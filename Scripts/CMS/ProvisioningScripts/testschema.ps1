<#
.DESCRIPTION
    This Script is for Testing below components as per the input from the XML file
    Check if list/libraries exist in the site collection
    Check if the column exists in the list/library
    Validate the custom attributes
    Check if custom view exists in the list/library with the columns defined as per the XML file
    Check if the default view exists and contains the columns defined as per the XML file

    XML files it will look for inputs are
    SchemaToTest.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Create/Update the Schema Test Result list in the cms-global site collection with list/library validations

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : testschema.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
17/03/2021  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
  $tenant,
  $sp_user,
  $sp_password,
  $InstrumentationKey
)

$filePath = $PSScriptRoot + '\resources\SchemaToTest.xml'
[xml]$schemaFile = Get-Content -Path $filePath

$tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
$rootSCUrl = "https://" + $tenant + ".sharepoint.com"
$schemaTestResultListName = 'Schema Test Result'

$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

$globalConfigSCUrl = ''
$termSets = [ordered]@{}

function Get-Lists {
  param (
    $lists,
    $siteUrl,
    $tenantAdmin
  )
  try {
    foreach ($list in $lists) {
      Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
      $web = Get-PnPWeb
      $listIssue = $null
      $listIssue = [System.Collections.ArrayList]@()
      $listObj = Get-PnPList -Identity $list.ListName
      if ($null -ne $listObj) {
        Write-Host "Started validation for the list $($listObj.Title) with URL $($rootSCUrl + $listObj.DefaultViewUrl)" -ForegroundColor Yellow
        $listFullUrl = $rootSCUrl + $listObj.DefaultViewUrl
        $contentTypeNames = $list.ContentTypeName.Split(";")
        Get-ListContentTypes -listName $listObj.Title -siteUrl $siteUrl -issues $listIssue -tenantAdmin $tenantAdmin -contentTypeNames $contentTypeNames

        #Get All Columns from List
        foreach ($column in $list.columnItem) {
          $fieldIssue = $null
          $fieldIssue = [System.Collections.ArrayList]@()
          $field = Get-PnPField -List $listObj.Title -Identity $column.ColumnName
          if ($null -ne $field) {
            if ($field.InternalName -eq 'cdnurl') {
              Write-Host $field.InternalName
            }
            $listDetails = ''
            $listDetails += "Column Title  : $($field.Title)`n"
            $listDetails += "Description   : $($field.Description)`n"
            $listDetails += "Group Name    : $($field.Group)`n"
            $listDetails += "Internal Name : $($field.InternalName)`n"
            $listDetails += "Static Name   : $($field.StaticName)`n"
            $listDetails += "Scope         : $($field.Scope)`n"
            $listDetails += "Type          : $($field.TypeDisplayName)`n"
            $listDetails += "Schema XML    : $($field.SchemaXml)`n"
            $listDetails += "Is Required?  : $($field.Required)`n"
            $listDetails += "Is read only? : $($field.ReadOnlyField)`n"
            $listDetails += "Unique?       : $($field.EnforceUniqueValues)`n"
            
            Write-Host "Field details for the list $($listObj.Title) & $($rootSCUrl + $listObj.DefaultViewUrl) is : " -ForegroundColor Green
            Write-host "$($listDetails)"
            try {
              if ($field.TypeAsString -eq "Choice") {
                [xml]$choiceSchema = $field.SchemaXml
                $choiceValues = $choiceSchema.Field.CHOICES.CHOICE
                if ($null -ne $choiceValues -and $choiceValues -gt 0 -and $null -ne $column.choicevalue) {
                  $schemaChoiceValues = $column.choicevalue.Split(",")
                  foreach ($schemaChoiceValue in $schemaChoiceValues) {
                    if (!$choiceValues.Contains($schemaChoiceValue)) {
                      Write-Host "The Choice value "$schemaChoiceValue" is not available for the field " $field.InternalName " as per the schema"$column.Required" for the list" $list.ListName -ForegroundColor Red
                      $fieldIssue.Add("The Choice value $($schemaChoiceValue) is not available for the field $($field.InternalName) as per the schema $($column.Required) for the list $($list.ListName)")
                    }
                  }
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Coice Error " $ErrorMessage -foreground Red
            }

            try {
              if ($field.TypeDisplayName -eq "Managed Metadata") {
                $siteField = Get-PnPField -Identity $field.InternalName
                if ($null -ne $siteField) {
                  $manageMetaDataMappingExists = $false
                  foreach ($termSet in $termSets.GetEnumerator()) {
                    if ($termSet.Name.Guid.Contains($siteField.TermSetId.Guid)) {
                      $manageMetaDataMappingExists = $true
                      break;
                    }
                  }
  
                  if ($manageMetaDataMappingExists -eq $false) {
                    Write-Host "The termset mapping is not available for the field " $field.InternalName " as per the schema for the list" $list.ListName -ForegroundColor Red
                    $fieldIssue.Add("The termset mapping is not available for the field $($field.InternalName) as per the schema for the list $($list.ListName)")
                  }
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Manage Metadata Error" $ErrorMessage -foreground Red
            }
            try {
              if ($null -ne $column.Required) {
                $requiredFieldIssue = Get-ListFieldCTLevelRequireValidation -siteUrl $siteUrl -contentTypeNames $contentTypeNames -listName $listObj.Title -fieldName $field.InternalName -tenantAdmin $tenantAdmin -isRequired $column.Required -issue $fieldIssue
                if ($null -ne $requiredFieldIssue -and $requiredFieldIssue -gt 0) {
                  $fieldIssue.Add($requiredFieldIssue)
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Required Attribute Error" $ErrorMessage -foreground Red
            }

            try {
              if ($null -ne $column.ColumnTitle) {
                if (!$column.ColumnTitle -eq $field.Title) {
                  Write-Host "The Title for the field " $field.Title "doesn't match as per the schema"$column.ColumnTitle" for the list" $list.ListName -ForegroundColor Red
                  $fieldIssue.Add("The Title for the field $($field.Title) doesn't match as per the schema $($column.ColumnTitle) for the list $($list.ListName)")
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Title Change Attribute Error" $ErrorMessage -foreground Red
            }

            try {
              if ($null -ne $column.Hidden) {
                if (!$column.Hidden -eq $field.Hidden.ToString() ) {
                  #check for Content Type Level Hidden Validation
                  $hiddenFieldIssue = Get-ListFieldCTLevelHiddenValidation -siteUrl $siteUrl -issue $fieldIssue -fieldName $field.InternalName -listName $listObj.Title -tenantAdmin $tenantAdmin -isHidden $column.Hidden -contentTypeNames $contentTypeNames
                  if ($null -ne $hiddenFieldIssue -and $hiddenFieldIssue -gt 0) {
                    $fieldIssue.Add($hiddenFieldIssue)
                  }
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Hidden Attribute Error" $ErrorMessage -foreground Red
            }
            
            try {
              if ($null -ne $column.EnforceUniqueValues) {
                if (!$column.EnforceUniqueValues -eq $field.EnforceUniqueValues.ToString() ) {
                  Write-Host "The EnforceUniqueValues attribute" $field.EnforceUniqueValues" for the field " $field.InternalName "doesn't match as per the schema" $column.EnforceUniqueValues" for the list" $list.ListName -ForegroundColor Red
                  $fieldIssue.Add("The EnforceUniqueValues attribute $($field.EnforceUniqueValues) for the field $($field.InternalName) doesn't match as per the schema $($column.EnforceUniqueValues) for the list $($list.ListName)")
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Enforce uinque value Attribute Error" $ErrorMessage -foreground Red
            }
            
            try {
              if ($null -ne $column.showInNewEditForm) {
                if (!$field.SchemaXml.Contains('ShowInEditForm="FALSE"')) {
                  if (!$field.Hidden ) {
                    #check for Content Type Level Hidden Validation
                    $showInEditFormIssue = Get-ListFieldCTLevelHiddenValidation -siteUrl $siteUrl -issue $fieldIssue -fieldName $field.InternalName -listName $listObj.Title -tenantAdmin $tenantAdmin -isHidden $column.Hidden -contentTypeNames $contentTypeNames
                    if ($null -ne $showInEditFormIssue -and $showInEditFormIssue -gt 0) {
                      Write-Host "The ShowInEditForm attribute for the field" $field.InternalName "doesn't match as per the schema" $column.showInNewEditForm" for the list" $list.ListName -ForegroundColor Red
                      $fieldIssue.Add("The ShowInEditForm attribute for the field $($field.InternalName) doesn't match as per the schema $($column.showInNewEditForm) for the list $($list.ListName)")
                    }
                  }
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Show in Edit Form Attribute Error" $ErrorMessage -foreground Red
            }
            
            try {
              if ($null -ne $column.Validation) {
                if ($null -eq $field.ValidationFormula) {
                  Write-Host "There is no validation formula set for the field" $field.InternalName " for the list" $list.ListName -ForegroundColor Red
                  $fieldIssue.Add("There is no validation formula set for the field $($field.InternalName) for the list $($list.ListName)")
                }
              }
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host "Validation Attribute Error" $ErrorMessage -foreground Red
            }
          }
          else {
            Write-Host $column.ColumnName "doesn't exists in the list with Title:" $list.ListName "& URL :"$listFullUrl -ForegroundColor Red
            $fieldIssue.Add("$($column.ColumnName) doesn't exists in the list Titled: $($list.ListName) & URL : $($listFullUrl)")
          }

          if ($null -ne $fieldIssue -and $fieldIssue.Count -gt 0) {
            $listIssue.Add($fieldIssue -join '. ')
          }
        }
        
        $listIssue = Get-Views -listSchema $list -issues $listIssue -listUrl $listFullUrl
      }
      else {
        Write-Host $list.ListName "doesn't exists at site" $siteUrl -ForegroundColor Red
        $listIssue.Add("$($list.ListName) doesn't exists at site $($siteUrl)")
      }
      Write-Host "Validation completed for the list $($listObj.Title) with URL $($rootSCUrl + $listObj.DefaultViewUrl)" -ForegroundColor Green
     
      Connect-PnPOnline -Url $globalConfigSCUrl -Credentials $tenantAdmin
      $hash = $null
      $hash = @{}
      $hash.Add("SiteUrl", $siteUrl)
      $hash.Add("ListName", "$($listFullUrl), $($listObj.Title)")
      $hash.Add("Title", $web.Title)
      Write-Host "ListIssue count is $($listIssue.Count)" -ForegroundColor Green
      if ($null -eq $listIssue -or $listIssue.Count -eq 0) {
        $hash.Add("IssueWithList", "No")
        $hash.Add("Issues", "No Issues")
      }
      else {
        $hash.Add("IssueWithList", "Yes")
        $hash.Add("Issues", $listIssue -join ' .')
      }
      Add-PnPListItem -List $schemaTestResultListName -Values $hash
      Disconnect-PnPOnline
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
  }
}

function Get-ListFieldCTLevelRequireValidation {
  param (
    $siteUrl,
    $listName,
    $fieldName,
    $tenantAdmin,
    $isRequired,
    $issue,
    $contentTypeNames
  )
  
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    $context = Get-PnPContext
    foreach ($contentTypeName in $contentTypeNames) {
      $contentTypeObject = Get-PnPContentType -Identity $contentTypeName -List $listName
      if ($null -ne $contentTypeObject) {
        $context.Load($contentTypeObject.Fields)
        $context.ExecuteQuery()
        $field = $contentTypeObject.Fields | Where-Object { $_.InternalName -eq $fieldName }
        if ($null -ne $field) {
          if (!($field.Required.ToString() -eq $isRequired)) {
            Write-Host "The Required attribute"$field.Required" for the field " $field.InternalName "doesn't match as per the schema"$isRequired" for the list" $listName -ForegroundColor Red
            $issue.Add("The Required attribute $($field.Required) for the field $($field.InternalName) doesn't match as per the schema $($isRequired) for the list $($listName)")
          }
        }
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Error in Get-ListFieldCTLevelRequireValidation for the field "$fieldName "for the list :"$listName "for the site collection : "$siteUrl "Error : " $ErrorMessage -ForegroundColor Red
  }

  return $issue
}

function Get-ListFieldCTLevelHiddenValidation {
  param (
    $siteUrl,
    $listName,
    $fieldName,
    $tenantAdmin,
    $isHidden,
    $issue,
    $contentTypeNames
  )
  
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    $context = Get-PnPContext
    foreach ($contentTypeName in $contentTypeNames) {
      $contentTypeObject = Get-PnPContentType -Identity $contentTypeName -List $listName
      if ($null -ne $contentTypeObject) {
        $context.Load($contentTypeObject.Fields)
        $context.ExecuteQuery()
        $field = $contentTypeObject.Fields | Where-Object { $_.InternalName -eq $fieldName }
        if ($null -ne $field) {
          if (!($field.Hidden.ToString() -eq $isHidden)) {
            Write-Host "The Required attribute"$field.Hidden" for the field " $field.InternalName "doesn't match as per the schema"$isHidden" for the list" $listName -ForegroundColor Red
            $issue.Add("The Required attribute $($field.Hidden) for the field $($field.InternalName) doesn't match as per the schema $($isHidden) for the list $($listName)")
          }
        }
      }
    }
  }
  catch {
    Write-Host "Error in Get-ListFieldCTLevelHiddenValidation for the field "$fieldName "for the list :"$listName "for the site collection : "$siteUrl "Error : " $_.Exception.Message -ForegroundColor Red
  }

  return $issue
}

function Get-TermSets {
  param (
    $schemaFile,
    $tenantUrl,
    $tenantAdmin
  )
  $termSets = [ordered]@{}

  try {
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    foreach ($termset in $schemaFile.schema.termsets.termset) {
      $termObject = Get-PnPTermSet -Identity $termset.Name -TermGroup "TASMU"
      if ($null -ne $termObject) {
        $termSets[$termObject.Id] = $termObject.Name 
      }
    }
  }
  catch {
    write-host -f Red "Error in getting term sets !" $_.Exception.Message
  }

  return $termSets
}

function Get-Views {
  param (
    $listSchema,
    $issues,
    $listUrl
  )
  
  try {
    if ($listSchema.ListTemplate -eq 'GenericList') {
      $defaultViewName = 'All Items'
      $issue = Find-ValidateViews -listSchema $listSchema -issues $issues -defaultViewName $defaultViewName -listUrl $listUrl
      if ($null -ne $issue -and $issue -gt 0) {
        $issues.Add($issue)
      }
    }
    elseif ($listSchema.ListTemplate -eq 'DocumentLibrary') {
      $defaultViewName = 'All Documents'
      $issue = Find-ValidateViews -listSchema $listSchema -issues $issues -defaultViewName $defaultViewName -listUrl $listUrl
      if ($null -ne $issue -and $issue -gt 0) {
        $issues.Add($issue)
      }
    }
    elseif ($listSchema.ListTemplate -eq 'PictureLibrary') {
      $defaultViewName = 'All Images'
      $issue = Find-ValidateViews -listSchema $listSchema -issues $issues -defaultViewName $defaultViewName -listUrl $listUrl
      if ($null -ne $issue -and $issue -gt 0) {
        $issues.Add($issue)
      }
    }
  }
  catch {
    $issues.Add("Error while getting view for the listURL $($listUrl) : $($_.Exception.Message)")
    write-host -f Red "Error while getting view for the listURL $($listUrl) : $($_.Exception.Message)"
  }

  return $issues
}

function Find-ValidateViews {
  param (
    $listSchema,
    $issues,
    $defaultViewName,
    $listUrl
  )
  
  try {

    Write-Host "Validating views for the list with Title : $($listSchema.ListName) & URL: $($listUrl)" -ForegroundColor Yellow

    if ([bool]($listSchema.customView) -ne $false) {
      $homeView = Get-PnPView -List $listSchema.ListName -Identity $listSchema.customView
      if ($null -ne $homeView) {
        if ($null -ne $listSchema.customViewfields) {
          foreach ($columnName in $listSchema.customViewfields.name) {
            if ($homeView.ViewFields -notcontains $columnName) {
              Write-Host $columnName "doesn't exists in " $listSchema.customView "view for list "$listSchema.ListName "with URL " $listUrl -ForegroundColor Red
              $issues.Add("$($columnName) doesn't exists in  $($listSchema.customView) view for list $($listSchema.ListName) with URL $($listUrl)")
            }
          }
        }
      }
    }

    $defaultView = Get-PnPView -List $listSchema.ListName -Identity $defaultViewName
    if ($null -ne $defaultView) {
      if ($null -ne $listSchema.defaultviewfields) {
        foreach ($defaultColumnName in $listSchema.defaultviewfields.name) {
          if ($defaultView.ViewFields -notcontains $defaultColumnName) {
            Write-Host $defaultColumnName "doesn't exists in " $defaultViewName "view for list "$listSchema.ListName "with URL " $listUrl -ForegroundColor Red
            $issues.Add("$($defaultColumnName) doesn't exists in $($defaultViewName) view for list $($listSchema.ListName) with URL $($listUrl)") 
          }
        }
      }
    }
  }
  catch {
    $issues.Add("Error while validating view for the listURL $($listUrl) : $($_.Exception.Message)")
    write-host -f Red "Error while validating view for the listURL $($listUrl) : $($_.Exception.Message)"
  }

  Write-Host "Validation completed for views for the list with Title: $($listSchema.ListName) & URL: $($listUrl)" -ForegroundColor Green
  return $issues
}

function Remove-ListItems {
  param (
    $siteUrl,
    $listName,
    $tenantAdmin
  )
  
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
     
  $BatchSize = 200
  try {
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($tenantAdmin.UserName, $tenantAdmin.Password)
   
    #Get the web and List
    $Web = $Ctx.Web
    $List = $web.Lists.GetByTitle($ListName)
    $Ctx.Load($List)
    $Ctx.ExecuteQuery()
    Write-host "Total Number of Items Found in the List:"$List.ItemCount
  
    #Define CAML Query to get list items in batches
    $Query = New-Object Microsoft.SharePoint.Client.CamlQuery
    $Query.ViewXml = "<View Scope='RecursiveAll'><RowLimit Paged='TRUE'>$BatchSize</RowLimit></View>"
  
    do { 
      #Get items from the list in batches
      $ListItems = $List.GetItems($Query)
      $Ctx.Load($ListItems)
      $Ctx.ExecuteQuery()
      If ($ListItems.count -eq 0) { Break; }
      Write-host Deleting $($ListItems.count) Items from the List...
      ForEach ($Item in $ListItems) {
        $List.GetItemById($Item.Id).DeleteObject()
      }
      $Ctx.ExecuteQuery()
    } while ($true)
  
    Write-host -f Green "All Items Deleted!"
  }
  catch {
    write-host -f Red "Error Deleting List Items!" $_.Exception.Message
  }
}

function Get-ListContentTypes {
  param (
    $siteUrl,
    $listName,
    $issues,
    $tenantAdmin,
    $contentTypeNames
  )

  try {
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
  
    Write-Host "Validating content types for the list $($listName) at the site $($siteUrl)" -ForegroundColor Yellow
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($tenantAdmin.Username, $tenantAdmin.Password)
    $List = $Ctx.Web.lists.GetByTitle($listName)
    $ContentTypeCollection = $List.ContentTypes
    $Ctx.Load($ContentTypeCollection)
    $Ctx.ExecuteQuery()
    foreach ($contentTypeName in $contentTypeNames) {
      $contentType = $ContentTypeCollection | Where-Object { $_.Name -eq $contentTypeName }
      if ($null -eq $contentType) {
        Write-Host "Content Type $($contentTypeName) is not associated with the list $($listName) & $($rootSCUrl + $list.DefaultViewUrl)" -ForegroundColor Red
        $issues.Add("Content Type $($contentTypeName) is not associated with the list $($listName) & $($rootSCUrl + $list.DefaultViewUrl)")
      }
    }
  }
  catch {
    Write-Host "Error occurred while validating Content Types for the list $($listName) at site $($siteUrl) Error : $($_.Exception.Message)" -ForegroundColor Red
    $issues.Add("Error occurred while validating Content Types for the list $($listName) at site $($siteUrl)")
  }
  
  Write-Host "Validation completed for content types for the list $($listName) at the site $($siteUrl)" -ForegroundColor Green
  return $issues
}

function Get-SCReport {
  param (
    $schemaFile
  )
  
  try {
    Write-Host "Starting the schema validation script for the teanant $($tenant)" -ForegroundColor Green
    foreach ($globalconfigsite in $schemaFile.schema.Configsite.site) {
      $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
      $globalconfigSiteUrl = $urlprefix + $globalconfigsite.Alias
      Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
      $siteExits = Get-PnPTenantSite -Url $globalconfigSiteUrl -ErrorAction SilentlyContinue
    
      if ([bool] ($siteExits) -eq $true) {
        $globalConfigSCUrl = $globalconfigSiteUrl 
        Connect-PnPOnline -Url $globalconfigSiteUrl -Credentials $tenantAdmin
        $Web = Get-PnPWeb
        Write-host "Starting validation for the lists/libraries of $($Web.Title) - $($globalConfigSCUrl)" -ForegroundColor Green
        Write-Host "Checking if the $($schemaTestResultListName) list exists at $($globalconfigSiteUrl)" -ForegroundColor Yellow
        $list = Get-PnPList -Identity $schemaTestResultListName
        if ([bool]($list) -eq $false) {
          Write-Host "$($schemaTestResultListName) list doesn't exists. Creating ..." -ForegroundColor Yellow
          New-PnPList -Title $schemaTestResultListName -Template GenericList 
          Add-PnPField -List $schemaTestResultListName -DisplayName 'Site Url' -InternalName 'SiteUrl' -Type 'Text' -Required -AddToDefaultView -ErrorAction Stop
          Add-PnPField -List $schemaTestResultListName -DisplayName 'List Name' -InternalName 'ListName' -Type URL -AddToDefaultView -ErrorAction Stop
          Add-PnPField -List $schemaTestResultListName -DisplayName 'Issues' -InternalName 'Issues' -Type 'Note' -AddToDefaultView -ErrorAction Stop
          Add-PnPField -List $schemaTestResultListName -DisplayName 'Issue with List/Library?' -InternalName 'IssueWithList' -Type 'Text' -AddToDefaultView -ErrorAction Stop
          Add-PnPField -List $schemaTestResultListName -DisplayName 'Comments(If Any)' -InternalName 'Comments' -Type 'Note' -AddToDefaultView -ErrorAction Stop
        }
        else {
          Write-Host "$($schemaTestResultListName) list exists. Deleting all entries before proceeding with the schema validation" -ForegroundColor Green
          Remove-ListItems -siteUrl $globalconfigSiteUrl -listName $schemaTestResultListName -tenantAdmin $tenantAdmin
        }
        Get-Lists -siteUrl $globalconfigSiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.global.ListAndContentTypes
      }
    }
      
    foreach ($globalhubsite in $schemaFile.schema.globalhubsite.site) {
      $globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
      Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
      $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
      if ([bool] ($siteExits) -eq $true) {
        Connect-PnPOnline -Url $globalhubSiteUrl -Credentials $tenantAdmin
        $Web = Get-PnPWeb
        Write-host "Starting validation for the lists/libraries of $($Web.Title) - $($globalhubSiteUrl)" -ForegroundColor Green
        Get-Lists -siteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.marketplace.ListAndContentTypes
      }
                   
      foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {
        $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
        Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
        $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
        if ([bool] ($siteExits) -eq $true) {
          Connect-PnPOnline -Url $sectorhubSiteUrl -Credentials $tenantAdmin
          $Web = Get-PnPWeb
          Write-host "Starting validation for the lists/libraries of $($Web.Title) - $($sectorhubSiteUrl)" -ForegroundColor Green
          Get-Lists -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.sector.ListAndContentTypes
        } 

        foreach ($entitySite in $globalhubsite.sectorhubsite.site.orgassociatedsite) {
          $entitySiteUrl = $urlprefix + $entitySite.Alias
          Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
          $siteExits = Get-PnPTenantSite -Url $entitySiteUrl -ErrorAction SilentlyContinue
          if ([bool] ($siteExits) -eq $true) {
            Connect-PnPOnline -Url $entitySiteUrl -Credentials $tenantAdmin
            $Web = Get-PnPWeb
            Write-host "Starting validation for the lists/libraries of $($Web.Title) - $($entitySiteUrl)" -ForegroundColor Green
            Get-Lists -siteUrl $entitySiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.entity.ListAndContentTypes
          } 
        }
      }
    }
  }
  catch {
    write-host -f Red "Error !" $_.Exception.Message
  }

  Write-Host 'Schema validation script ended' -ForegroundColor Green
}

$termSets = Get-TermSets -schemaFile $schemaFile -tenantUrl $tenantUrl -tenantAdmin $tenantAdmin

Get-SCReport -schemaFile $schemaFile