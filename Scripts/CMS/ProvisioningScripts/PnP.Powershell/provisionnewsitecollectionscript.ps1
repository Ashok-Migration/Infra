﻿<#
.DESCRIPTION
    This Script is for Creating below components as per the input from the XML file
    Creating List/Libraries
    Creating Columns And List for ProductDocuments (Only For MarketPlace Site)
    Creating New Group And Add Users
    Adding Users To Default SPGroup
    Creating Custom QuickLaunch Navigation
    Creating Modern SharePoint Page
    Adding Webpart To Modern Page
    Upload Files
    Update Site Columns for some List/Libraries
    Add Entry In Configuration List For Global Site
    Update View For Tasks List, Update View for only [ME]

    XML files it will look for inputs are
    Site.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    scope                   - This is the scope for Search Configuration of the tenant which will be used for running the script, example, Subscription
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Taxanomy Group & Taxanomy Columns as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : provisionnewsitecollectionscript.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
17/07/2020  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
  $tenant, # Enter the tenant name
  $TemplateParametersFile,
  $sp_user,
  $sp_password,
  $scope,
  $InstrumentationKey
)

function Add-ComponentsForSites() {
  
  $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
  $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
  if ($null -ne ($JsonParameters | Get-Member -Type NoteProperty 'parameters')) {
    $JsonParameters = $JsonParameters.parameters
  }
  $RoleName = $JsonParameters.RoleName.value
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
  $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
  $client.InstrumentationKey = $InstrumentationKey 
  if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
    $client.Context.Cloud.RoleName = $RoleName
  }

  $filePath = $PSScriptRoot + '\resources\Site.xml'
  [xml]$sitefile = Get-Content -Path $filePath
  $appsPath = $PSScriptRoot + '\resources\Apps.xml'
  $tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"

  ProvisionSiteCollections $sitefile $tenantUrl $appsPath

  Write-Host 'Site Collections provisioning completed successfully' -ForegroundColor Green

  #region Upload the script files to the root site Collection
  $rootSiteCollection = "https://" + $tenant + ".sharepoint.com"
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

  $destinationPath = "Style Library"
  $sourceFolder = $PSScriptRoot + '.\SPFxWebparts\Assets\Styles'
  $sourceFiles = Get-ChildItem $sourceFolder

  Add-FileToRootSiteCollection $rootSiteCollection $tenantAdmin $destinationPath $sourceFiles
  #endregion 

  #region Add Everyone except external users to the visitor gtoup
  AddEveryoneDefaultUserToVisitorGroup -siteUrl $rootSiteCollection -tenantAdmin $tenantAdmin
  #endregion

  Write-Host "Provisioning completed successfully" -ForegroundColor Green
  $client.TrackEvent("Completed.")
}

function ProvisionSiteCollections($sitefile, $tenantUrl, $appsPath) {

  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    
  foreach ($globalconfigsite in $sitefile.sites.Configsite.site) {
    $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
    $globalconfigSiteUrl = $urlprefix + $globalconfigsite.Alias
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    $siteExits = Get-PnPTenantSite -Url $globalconfigSiteUrl -ErrorAction SilentlyContinue

    if ([bool] ($siteExits) -eq $true) { 
      Write-Host "site exists, starting creation of other components. $globalconfigSiteUrl" -ForegroundColor Green
      $paramsSiteColumn = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey; contenttypehub = $globalconfigSiteUrl }
      $psfilecreatesitecolumnscript = Resolve-Path $PSScriptRoot".\createsitecolumnscript.ps1"
      .$psfilecreatesitecolumnscript @paramsSiteColumn
      Connect-PnPOnline -Url $globalconfigSiteUrl -Credentials $tenantAdmin
      Set-PnPTenantSite -Url $globalconfigSiteUrl -SharingCapability ExternalUserSharingOnly
      Add-ListAndLibrary $globalconfigSiteUrl $sitefile.sites.ConfigurationSPList
      Edit-SiteColumns $globalconfigSiteUrl $sitefile.sites.updateSiteColumns.configChange $tenantAdmin
      Add-SiteCollectionAdmins -siteUrl $globalconfigSiteUrl -tenantAdmin $tenantAdmin -users $sitefile.sites.configSPAdmin.users
      Add-UniquePermission $sitefile.sites.UniquePermissions.List $globalconfigSiteUrl
      Edit-RegionalSettings $globalconfigSiteUrl $tenantAdmin
      Add-CustomQuickLaunchNavigationGlobal $globalconfigSiteUrl $sitefile.sites.globalConfigNav
      New-SPFXWebPart $globalconfigSiteUrl $tenantAdmin 'Global'
      
      #check if the navigation webpart is present on the page or not
      $navigationContentWP = Get-PnPPageComponent -Page Home.aspx | Where-Object { $_.Title -eq "Navigation Content" }
      if ([bool]($navigationContentWP) -eq $True) {
        Remove-PnPPageComponent -Page "Home" -InstanceId $navigationContentWP.InstanceId -Force
      }
      
      #region Add the Navigation Content webpart to the page
      $marketplaceUrl = $urlprefix + $sitefile.sites.globalhubsite.site.Alias
      $webpartName = "Navigation Content"
      $pageName = "Home"
      $property = @{}
      $property.showEntities = $false
      $property.marketplaceUrl = $marketplaceUrl
      $prop = $property | ConvertTo-Json
      
      Write-host "Sleep started for 2 minutes..." -ForegroundColor Green
      start-sleep -s 120
      Write-host "Sleep completed for 2 minutes..." -ForegroundColor Green

      Add-CustomWebPartToPage $globalconfigSiteUrl $tenantAdmin $pageName $prop $webpartName
      #endregion
      Publish-SitePage $globalconfigSiteUrl $tenantAdmin '/SitePages/Home.aspx'
    }
  }

  foreach ($globalhubsite in $sitefile.sites.globalhubsite.site) {
    $isGlobalHubSite = $true
    $globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
    $themeGlobal = $globalhubsite.Theme    
    if ([bool] ($siteExits) -eq $true) {
      Write-Host "site exists, starting creation of other components. $globalhubSiteUrl" -ForegroundColor Green
      $paramsSiteColumn = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey; contenttypehub = $globalhubSiteUrl }
      $psfilecreatesitecolumnscript = Resolve-Path $PSScriptRoot".\createsitecolumnscript.ps1"
      .$psfilecreatesitecolumnscript @paramsSiteColumn
      Connect-PnPOnline -Url $globalhubSiteUrl -Credentials $tenantAdmin
      Set-PnPTenantSite -Url $globalhubSiteUrl -SharingCapability ExternalUserSharingOnly
      New-SiteCollectionAppCatalog $globalhubSiteUrl         
      New-SPFXWebPart $globalhubSiteUrl $tenantAdmin 'Marketplace'
      Add-ListAndLibrary $globalhubSiteUrl $sitefile.sites.globalSPList
      Add-FieldsAndListProductDocuments($globalhubSiteUrl)
      Edit-SiteColumns $globalhubSiteUrl $sitefile.sites.updateSiteColumns.globalChange $tenantAdmin
      Remove-SiteColumns $globalhubSiteUrl $sitefile.sites.deleteSiteColumns $tenantAdmin
      Add-SiteCollectionAdmins -siteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin -users $sitefile.sites.globalSPAdmin.users
      Add-GroupAndUsers $globalhubSiteUrl $sitefile.sites.globalSPGroup $globalhubsite.Title
      Edit-GroupOwner $globalhubSiteUrl $sitefile.sites.globalSPGroup $globalhubsite.Title
      Set-GroupViewSettings -SiteURL $globalhubSiteUrl -tenantAdmin $tenantAdmin -Groups $sitefile.sites.globalSPGroup -siteAlias $globalhubsite.Title
      Add-UsersToDefaultSharePointGroup $globalhubSiteUrl $sitefile.sites.globalSPGroup $globalhubsite.Title
      Add-UniquePermission $sitefile.sites.UniquePermissions.List $globalhubSiteUrl
      Add-Theme $themeGlobal $globalhubSiteUrl $tenantAdmin $tenantUrl
      New-SitePage $globalhubSiteUrl 'MyTasks' $tenantAdmin
      New-ModernPage $globalhubSiteUrl $sitefile.sites.globalPageWebpart
      New-WebPartToPage $globalhubSiteUrl $sitefile.sites.globalPageWebpart
      Edit-RegionalSettings $globalhubSiteUrl $tenantAdmin
      Edit-ViewForTasksList 'My Tasks' $globalhubSiteUrl
      
      
      #region My Task web part
      $componentName = "MyTasks"
      $pageName = 'MyTasks'
      $translationTaskContentTypeId = Get-ContentTypeId $globalhubSiteUrl $tenantAdmin "TASMU Translation Tasks" "My Tasks"
      $approverTaskContentTypeId = Get-ContentTypeId $globalhubSiteUrl $tenantAdmin "TASMU Approval Tasks" "My Tasks"
      $myTaskListId = Get-ListId $globalhubSiteUrl $tenantAdmin "My Tasks"
      
      $property = @{}
      $property.webPartTitle = "My Tasks"
      $property.itemsPerPage = 30
      $property.viewMode = "Detailed"
      $property.arWebPartTitle = "المهام الموكلة إليّ"
      $property.list = $myTaskListId.Guid
      $property.translationTaskContentType = $translationTaskContentTypeId.StringValue
      $property.approvalTaskContentType = $approverTaskContentTypeId.StringValue
      $prop = $property | ConvertTo-Json
            
      Write-host "Sleep started for 2 minutes..." -ForegroundColor Green
      start-sleep -s 120
      Write-host "Sleep completed for 2 minutes..." -ForegroundColor Green
      
      Add-CustomWebPartToPage $globalhubSiteUrl $tenantAdmin $pageName $prop $componentName 
      Publish-SitePage $globalhubSiteUrl $tenantAdmin '/SitePages/MyTasks.aspx'
      
      $pageName = 'Home'
      $property = @{}
      $property.webPartTitle = "My Tasks"
      $property.itemsPerPage = 5
      $property.viewMode = "Compact"
      $property.arWebPartTitle = "المهام الموكلة إليّ"
      $property.list = $myTaskListId.Guid
      $property.translationTaskContentType = $translationTaskContentTypeId.StringValue
      $property.approvalTaskContentType = $approverTaskContentTypeId.StringValue
      $property.seeAllLink = $globalhubSiteUrl + '/SitePages/MyTasks.aspx'
      $prop = $property | ConvertTo-Json
      
      Add-CustomWebPartToPage $globalhubSiteUrl $tenantAdmin $pageName $prop $componentName 1 1 0
      #endregion
      Edit-ListViewWebPartProperties $sitefile.sites.globalPageWebpart.page.name 1 $globalhubSiteUrl $tenantAdmin
      Publish-SitePage $globalhubSiteUrl $tenantAdmin '/SitePages/Home.aspx'
      Add-CustomQuickLaunchNavigationGlobal $globalhubSiteUrl $sitefile.sites.globalNav
      #Uncomment and run below line on new site creation only, else keep commented
      Add-EntryInConfigurationListForGlobalSite $globalconfigSiteUrl $globalhubSiteUrl $sitefile.sites.globalAddItemConfigurationList.item

      #Add-Files $globalhubSiteUrl $sitefile.sites.globalUploadFiles
    }
                
    foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {
      $isGlobalHubSite = $False
      $isSectorHubSite = $True
      $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
      Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
      $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
      $themeSector = $sectorhubsite.Theme 
      if ([bool] ($siteExits) -eq $true) {
        do {
          Write-host "Sleep started for 1 minute..." -ForegroundColor Green
          start-sleep -s 60
          Write-host "Sleep completed for 1 minute..." -ForegroundColor Green
          $isContentTypeExistsSectors = $true
          #$isContentTypeExistsSectors = Get-ContentTypeForSectors -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin
        }
        until ($isContentTypeExistsSectors -eq $true)

        if ($isContentTypeExistsSectors -eq $true) {
          Write-Host "site exists as well the content types are available, starting creation of other components. $sectorhubSiteUrl" -ForegroundColor Green
          $paramsSiteColumn = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey; contenttypehub = $sectorhubSiteUrl }
          $psfilecreatesitecolumnscript = Resolve-Path $PSScriptRoot".\createsitecolumnscript.ps1"
          .$psfilecreatesitecolumnscript @paramsSiteColumn
          
          Connect-PnPOnline -Url $sectorhubSiteUrl -Credentials $tenantAdmin
          Set-PnPTenantSite -Url $sectorhubSiteUrl -SharingCapability ExternalUserSharingOnly
          ####Register the created Site as Hub Site
          try {
            Register-PnPHubSite -Site $sectorhubSiteUrl
          }
          catch {
            $ErrorMessage = $_.Exception.Message
            Write-Host $ErrorMessage -ForegroundColor Yellow
          }
          EnableMegaMenu $sectorhubSiteUrl
          New-SiteCollectionAppCatalog $sectorhubSiteUrl
          New-SPFXWebPart $sectorhubSiteUrl $tenantAdmin 'Sector'
          Add-ListAndLibrary $sectorhubSiteUrl $sitefile.sites.sectorSPList
          Edit-SiteColumns $sectorhubSiteUrl $sitefile.sites.updateSiteColumns.sectorChange $tenantAdmin
          Add-SiteCollectionAdmins -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin -users $sitefile.sites.sectorSPAdmin.users
          Add-GroupAndUsers $sectorhubSiteUrl $sitefile.sites.sectorSPGroup $sectorhubsite.Title
          Edit-GroupOwner $sectorhubSiteUrl $sitefile.sites.sectorSPGroup $sectorhubsite.Title
          Set-GroupViewSettings -SiteURL $sectorhubSiteUrl -tenantAdmin $tenantAdmin -Groups $sitefile.sites.sectorSPGroup -siteAlias $sectorhubsite.Title
          Add-UsersToDefaultSharePointGroup $sectorhubSiteUrl $sitefile.sites.sectorSPGroup $sectorhubsite.Title
          Add-UniquePermission $sitefile.sites.UniquePermissions.List $sectorhubSiteUrl
          Add-Theme $themeSector $sectorhubSiteUrl $tenantAdmin $tenantUrl
          New-ModernPage $sectorhubSiteUrl $sitefile.sites.sectorPageWebpart 
          New-WebPartToPage $sectorhubSiteUrl $sitefile.sites.sectorPageWebpart
          Edit-RegionalSettings $sectorhubSiteUrl $tenantAdmin
          Edit-ViewForTasksList 'My Tasks' $sectorhubSiteUrl
          New-SitePage $sectorhubSiteUrl 'MyTasks' $tenantAdmin
                
          #region my Task web part
          $componentName = "MyTasks"
          $pageName = 'MyTasks'
          $translationTaskContentTypeId = Get-ContentTypeId $sectorhubSiteUrl $tenantAdmin "TASMU Translation Tasks" "My Tasks"
          $approverTaskContentTypeId = Get-ContentTypeId $sectorhubSiteUrl $tenantAdmin "TASMU Approval Tasks" "My Tasks"
          $myTaskListId = Get-ListId $sectorhubSiteUrl $tenantAdmin "My Tasks"
          
          $property = @{}
          $property.webPartTitle = "My Tasks"
          $property.itemsPerPage = 30
          $property.viewMode = "Detailed"
          $property.arWebPartTitle = "المهام الموكلة إليّ"
          $property.list = $myTaskListId.Guid
          $property.translationTaskContentType = $translationTaskContentTypeId.StringValue
          $property.approvalTaskContentType = $approverTaskContentTypeId.StringValue
          $prop = $property | ConvertTo-Json

          Write-host "Sleep started for 2 minutes..." -ForegroundColor Green
          start-sleep -s 120
          Write-host "Sleep completed for 2 minutes..." -ForegroundColor Green

          Add-CustomWebPartToPage $sectorhubSiteUrl $tenantAdmin $pageName $prop $componentName
          
          $pageName = 'Home'
          
          $property = @{}
          $property.webPartTitle = "My Tasks"
          $property.itemsPerPage = 5
          $property.viewMode = "Compact"
          $property.arWebPartTitle = "المهام الموكلة إليّ"
          $property.list = $myTaskListId
          $property.list = $myTaskListId.Guid
          $property.translationTaskContentType = $translationTaskContentTypeId.StringValue
          $property.approvalTaskContentType = $approverTaskContentTypeId.StringValue
          $property.seeAllLink = $sectorhubSiteUrl + '/SitePages/MyTasks.aspx'
          $prop = $property | ConvertTo-Json
          
          Add-CustomWebPartToPage $sectorhubSiteUrl $tenantAdmin $pageName $prop $componentName 1 1 0
          #endregion
          Publish-SitePage $sectorhubSiteUrl $tenantAdmin '/SitePages/MyTasks.aspx'
          
          Edit-ListViewWebPartProperties $sitefile.sites.sectorPageWebpart.page.name 1 $sectorhubSiteUrl $tenantAdmin
          Publish-SitePage $sectorhubSiteUrl $tenantAdmin '/SitePages/Home.aspx'
          Add-CustomQuickLaunchNavigationSector $sectorhubSiteUrl $sitefile.sites.sectorNav.QuickLaunchNav
          Add-CustomTopNavigationSector $sectorhubSiteUrl $sitefile.sites.sectorNav.TopNav
          #Uncomment and run below line on new site creation only, else keep commented
          Add-EntryInConfigurationListForSectorSite $globalconfigSiteUrl $sectorhubSiteUrl $sitefile.sites.sectorAddItemConfigurationList.item $sectorhubsite.Title

          #Add-Files $sectorhubSiteUrl $sitefile.sites.sectorUploadFiles
        }
        
      } 
    }
  }
  #set at Search Configuration tenant level, Uncomment to execute it
  $serchConfigPath = $PSScriptRoot + '\resources\SearchConfiguration.xml'
  Add-SearchConfiguration $scope $serchConfigPath
  #Disconnect-PnPOnline   
}

<#
Break permission inheritance for the list
Assign full control to owners group
Assign read access to other groups
#>
function Add-UniquePermission($lists, $siteUrl) {
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin

    foreach ($list in $lists) {
      $ListName = $list.ListName
      $spList = Get-PnPList -Identity $ListName
      try {
    
        If ($spList) {
          #Break Permission Inheritance of the List
          Set-PnPList -Identity $ListName -BreakRoleInheritance 
          Write-Host -f Green "Permission Inheritance Broken for $ListName"
          $client.TrackEvent("Permission Inheritance Broken for $ListName")

          $spGroups = Get-PnPGroup
          foreach ($spGroup in $spGroups) {
            $grpPermission = $null
            foreach ($group in $list.Permissions.Group) {
              if ($spGroup.Title.ToLower().Contains($group.Name.ToLower())) {
                $grpPermission = $group.Role
                break;
              }
            }
            if ($null -ne $grpPermission) {
              Set-PnPListPermission -Group $spGroup.Title -Identity $ListName -AddRole $grpPermission
              Write-Host -f Green "Assigned permission $grpPermission for Group "$spGroup.Title" in the list $ListName"
              $client.TrackEvent("Assigned permission $grpPermission for Group $spGroup.Title in the list $ListName")
            }
            else {
              $defaultPermission = $list.Permissions.Group | Where-Object { $_.Name -eq "*" }[0]
              Set-PnPListPermission -Group $spGroup.Title -Identity $ListName -AddRole $defaultPermission.Role
              Write-Host -f Green "Assigned permission "$defaultPermission.Role" for Group "$spGroup.Title" in the list  $ListName"
              $client.TrackEvent("Assigned permission $defaultPermission.Role for Group $spGroup.Title in the list  $ListName")
            }
          }
        }
      }
      catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -ForegroundColor Yellow
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
      }
        
    }
    Disconnect-PnPOnline
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-FieldsAndListProductDocuments($globalhubSiteUrl) {
    
  foreach ($ListAndContentTypes in $sitefile.sites.ProductDocumentsList.ListAndContentTypes) {

    Connect-PnPOnline -Url $globalhubSiteUrl -Credentials $tenantAdmin
    $connection = Get-PnPConnection
    #Call the function to add lookup column to list
    $nodeField = $ListAndContentTypes.Field
    $nodeList = $ListAndContentTypes
    $ListName = $nodeList.ListName
    if ($nodeList.ListTemplate -eq "GenericList") {
      $ListURL = "Lists/" + $ListName
    }
    else {
      $ListURL = $ListName
    }

    $ListURL = $ListName
    Add-LookupField -SiteURL $globalhubSiteUrl -ListName $ListName -Name $nodeField.ColumnName -DisplayName $nodeField.ColumnTitle -LookupListName $nodeField.LookupListName -LookupField $nodeField.LookupField -contentTypeName $nodeList.ContentTypeName -GroupName $nodeList.GroupName $connection

    
    #Call the function to Create ContentType
    New-ContentType $globalhubSiteUrl $nodeList.ContentTypeName $nodeList.ContentTypeName $nodeList.ParentCTName $nodeList.GroupName $connection

    foreach ($columnItem in $ListAndContentTypes.columnItem) {
      New-FieldToContentType $globalhubSiteUrl $columnItem.ContentTypeName $columnItem.ColumnName $connection $columnItem.Required
    } 
    
    #Call the function to add new list
    $List = Get-PnPList -Identity $ListName -ErrorAction Stop
    if ([bool]($List) -eq $false) {        
      $ListURL = $ListURL -replace '\s', ''
      $newList = New-PnPList -Title $ListName -Template $nodeList.ListTemplate -Url $ListURL -Connection $connection -ErrorAction Stop
    }

    $List = Get-PnPList -Identity $ListName -Connection $connection -ErrorAction Stop
    if ([bool]($List) -eq $true) {
      #Call the function to add Content Type to list
      $ListBase = Get-PnPContentType -Identity $nodeList.ContentTypeName -ErrorAction Stop -Connection $connection
      Set-PnPList -Identity $ListName -EnableContentTypes $true -EnableVersioning $true
      #original code
      #$contentTypeToList = Add-PnPContentTypeToList -List $List -ContentType $ListBase -DefaultContentType -ErrorAction Stop

      #region New Code for adding content type to list
      Add-ContentTypeToList -SiteURL $globalhubSiteUrl -ListName $ListName -CTypeName $nodeList.ContentTypeName -tenantAdmin $tenantAdmin
      #Set Default Content Type of the List
      Set-PnPDefaultContentTypeToList -List $ListName -ContentType $nodeList.ContentTypeName 
      #endregion
      Write-Host $ListBase.Name 'content type added to the List ' $ListName -ForegroundColor Green
      $client.TrackEvent("Content Type, $ContentTypeName added to List, $ListName")

      $BaseDocContentType = Get-PnPContentType -Identity "Document" -Connection $connection -ErrorAction Stop
 
      If ($BaseDocContentType) {
        Remove-PnPContentTypeFromList -List $List -ContentType $BaseDocContentType -ErrorAction Stop
        $client.TrackEvent("Default Content Type, $BaseDocContentType deleted from Library, $ListName")
      }

      New-View $ListName $globalhubSiteUrl $nodeList.defaultviewfields $nodeList.ListTemplate

      if ($nodeList.customView -ne '') {
        if (Get-PnPList -Identity $nodeList.ListName) {
          New-CustomView $nodeList.ListName $globalhubSiteUrl $nodeList.customView $nodeList.customViewfields
        }
      }
    }
  }

  Disconnect-PnPOnline
}

Function Add-LookupField() {
  param
  (
    [Parameter(Mandatory = $true)] [string] $SiteURL,
    [Parameter(Mandatory = $true)] [string] $ListName,
    [Parameter(Mandatory = $true)] [string] $Name,
    [Parameter(Mandatory = $true)] [string] $DisplayName,
    [Parameter(Mandatory = $false)] [string] $IsRequired = "FALSE",
    [Parameter(Mandatory = $false)] [string] $EnforceUniqueValues = "FALSE",
    [Parameter(Mandatory = $true)] [string] $LookupListName,
    [Parameter(Mandatory = $true)] [string] $LookupField,
    [Parameter(Mandatory = $true)] [string] $contentTypeName,
    [Parameter(Mandatory = $true)] [string] $GroupName,
    $connection
  )
    
  $fieldExists = Get-PNPField -identity $Name -ErrorAction SilentlyContinue
  $LookupListExist = Get-PnPList -Identity $LookupListName -Connection $connection -ErrorAction Stop

  if ([bool] ($fieldExists) -eq $false) {
    $LookupListID = $LookupListExist.id
    $web = Get-PnPWeb
    $LookupWebID = $web.Id
    $lookupColumnId = [GUID]::NewGuid() 
    Add-PnPFieldFromXml -Connection $connection "<Field Type='Lookup'
        ID='{$lookupColumnId}' Group='$GroupName' DisplayName='$DisplayName' Name='$Name' Description='$Description'
        Required='$IsRequired' EnforceUniqueValues='$EnforceUniqueValues' List='$LookupListID' 
        WebId='$LookupWebID' ShowField='$LookupField' />"

    foreach ($columnItem in $sitefile.sites.ProductDocumentsList.ListAndContentTypes.projectedField) {
      # create the projected field
      $prjFieldExists = Get-PNPField -identity $columnItem.ColumnName -ErrorAction SilentlyContinue
      if ([bool] ($prjFieldExists) -eq $false) {
        $newID = [GUID]::NewGuid() 
        $ColumnTitle = $columnItem.ColumnTitle
        $ColumnName = $columnItem.ColumnName
        $showField = $columnItem.ShowField
        Add-PnPFieldFromXml -Connection $connection "<Field Type='Lookup' Group='$GroupName' DisplayName='$ColumnTitle' Name='$ColumnName' 
                ShowField='$showField' EnforceUniqueValues='FALSE' Required='FALSE' Hidden='FALSE' ReadOnly='TRUE' CanToggleHidden='FALSE' 
                ID='$newID' UnlimitedLengthInDocumentLibrary='FALSE' FieldRef='$lookupColumnId' List='$LookupListID' />"
      }
    }
  }
}

Function New-LookupColumnForList() {
  param
  (
    [Parameter(Mandatory = $true)] [string] $SiteURL,
    [Parameter(Mandatory = $true)] [string] $ListName,
    [Parameter(Mandatory = $true)] [string] $Name,
    [Parameter(Mandatory = $true)] [string] $DisplayName,
    [Parameter(Mandatory = $false)] [string] $IsRequired = "FALSE",
    [Parameter(Mandatory = $false)] [string] $EnforceUniqueValues = "FALSE",
    [Parameter(Mandatory = $true)] [string] $LookupListName,
    [Parameter(Mandatory = $true)] [string] $LookupField,
    [Parameter(Mandatory = $true)] [string] $LookupType,
    [Parameter(Mandatory = $false)] [object] $ProjectedFields,
    [Parameter(Mandatory = $true)] [string] $GroupName,
    $connection
  )
    
  $fieldExists = Get-PNPField -identity $Name -ErrorAction SilentlyContinue
  $LookupListExist = Get-PnPList -Identity $LookupListName -Connection $connection -ErrorAction Stop

  if ([bool] ($fieldExists) -eq $false) {
    $LookupListID = $LookupListExist.id
    $web = Get-PnPWeb
    $LookupWebID = $web.Id

    $lookupColumnId = [GUID]::NewGuid() 
    Add-PnPFieldFromXml -Connection $connection "<Field Type='$LookupType'
        ID='{$lookupColumnId}' Group='$GroupName' Sortable='FALSE' DisplayName='$DisplayName' Name='$Name' Description='$Description'  
        Required='$IsRequired' EnforceUniqueValues='$EnforceUniqueValues' List='$LookupListID' 
        WebId='$LookupWebID' ShowField='$LookupField' />"
    #Mult='TRUE'
    foreach ($columnItem in $ProjectedFields) {
      $columnExists = Get-PNPField -identity $columnItem.ColumnName -ErrorAction SilentlyContinue
      if ([bool] ($columnExists) -eq $false) {
        # create the projected field
        $newID = [GUID]::NewGuid() 
        $ColumnTitle = $columnItem.ColumnTitle
        $ColumnName = $columnItem.ColumnName
        $showField = $columnItem.ShowField
        $projectedType = $columnItem.Type
        Add-PnPFieldFromXml -Connection $connection "<Field Type='$projectedType' DisplayName='$ColumnTitle' Name='$ColumnName' 
                ShowField='$showField' EnforceUniqueValues='FALSE' Group='$GroupName' Sortable='FALSE' Required='FALSE' Hidden='FALSE' ReadOnly='TRUE' CanToggleHidden='FALSE' 
                ID='$newID' UnlimitedLengthInDocumentLibrary='FALSE' FieldRef='$lookupColumnId' List='$LookupListID' />"
        #Mult='TRUE'
      }
    }
  }
}

function New-ContentType($contenttypehub, $ContentTypeName, $ContentTypeDesc, $ParentCTName, $GroupName, $connection) {
  try {
    $ContentTypeExist = Get-PnPContentType -Identity $ContentTypeName -ErrorAction Stop -Connection $connection
    #Check for existence of  site content type
    if ([bool]($ContentTypeExist) -eq $true) {
      Write-Host "$ContentTypeName already exists" -ForeGround Yellow
      $client.TrackEvent("$ContentTypeName already exists")
    } 
  }
  catch {
    try {
        Write-Host 'Content Type not found ,so creating a new contenttype' $ContentTypeName -Foreground Green
      $client.TrackEvent("Content Type not found ,so creating a new contenttype- $ContentTypeName.....")
      $ParentCT = Get-PnPContentType -Identity $ParentCTName -Connection $connection
      $addContentType = Add-PnPContentType -Name $ContentTypeName -Description $ContentTypeDesc -Group $GroupName -ParentContentType $ParentCT -ErrorAction Stop -Connection $connection
    }
    catch {
        $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
    }
  } 
}

function New-FieldToContentType($contenttypehub, $ContentTypeName, $ColumnName, $connection, $required) {
  try {
    Write-Host "Column not added, so adding column - $ColumnName to contenttype - $ContentTypeName....."
    $client.TrackEvent("Column not added, so adding column - $ColumnName to contenttype - $ContentTypeName.....")
    if ($required -eq "False") {
      Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection
      Write-Host $ColumnName 'added successfully to the content type' $ContentTypeName -ForegroundColor Green
    }
    else {
      Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection -Required
      Write-Host $ColumnName 'added successfully to the content type' $ContentTypeName -ForegroundColor Green
    }  
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  } 
}

function Add-EntryInConfigurationListForGlobalSite($globalconfigSiteUrl, $SiteUrl, $node) {
  try {
    Write-Host 'Addding entry In Configuration List for the site ' $SiteUrl -ForegroundColor Green
    $client.TrackEvent("Addding entry In Configuration List for the site $SiteUrl")

    Connect-PnPOnline -Url $globalconfigSiteUrl -Credentials $tenantAdmin

    $configListName = $node.configListName
    $query = "<View><Query><Where><Eq><FieldRef Name='SiteURL'/><Value Type='Text'>" + $siteUrl + "</Value></Eq></Where></Query></View>" 
    $listItem = Get-PnPListItem -List $configListName -Query $query
    if ([bool]($listItem) -eq $false) {
      $addListItem = Add-PnPListItem -List $configListName -Values @{"SiteURL" = $SiteUrl; "SiteLevel" = $node.SiteLevel; "ListNames" = $node.ListNames; "Approvers" = $node.Approvers; "CriticalApprovers" = $node.CriticalApprovers; "Translators" = $node.Translators }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-EntryInConfigurationListForSectorSite($globalconfigSiteUrl, $SiteUrl, $node, $value ) {
  try {
    Write-Host 'Addding entry In Configuration List for the site' $SiteUrl -ForegroundColor Green
    $client.TrackEvent("Addding entry In Configuration List for the site $SiteUrl")

    Connect-PnPOnline -Url $globalconfigSiteUrl -Credentials $tenantAdmin
    $query = "<View><Query><Where><Eq><FieldRef Name='SiteURL'/><Value Type='Text'>" + $siteUrl + "</Value></Eq></Where></Query></View>" 
    $listItem = Get-PnPListItem -List $node.configListName -Query $query
    if ([bool]($listItem) -eq $false) {
      $sectorApprovers = $node.Approvers.Replace('Sector', $value)
      $sectorTranslators = $node.Translators.Replace('Sector', $value)
      $addListItem = Add-PnPListItem -List $node.configListName -Values @{"SiteURL" = $SiteUrl; "SiteLevel" = $node.SiteLevel; "ListNames" = $node.ListNames; "Sector" = $value; "Approvers" = $sectorApprovers; "Translators" = $sectorTranslators }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function AddEntryInConfigurationListForOrgSite($globalconfigSiteUrl, $SiteUrl, $node, $value ) {
  try {
    Write-Host 'Addding entry In Configuration List for the site' $SiteUrl -ForegroundColor Green
    $client.TrackEvent("Addding entry In Configuration List for the site $SiteUrl")

    Connect-PnPOnline -Url $globalconfigSiteUrl -Credentials $tenantAdmin
    $addListItem = Add-PnPListItem -List $node.configListName -Values @{"SiteURL" = $SiteUrl; "SiteLevel" = $node.SiteLevel; "ListNames" = $node.ListNames; "Entity" = $value }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-SearchConfiguration($scope, $serchConfigPath) {
  try {
    if (Test-Path $serchConfigPath) {
      $client.TrackEvent("Search Configuration Started at Tenent Level.")
      Write-Host 'Search Configuration Started at Tenent Level.' -ForegroundColor Green
      Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
      Set-PnPSearchConfiguration -Path $serchConfigPath -Scope $scope
      $client.TrackEvent("Completed.")
      Write-Host 'Search Configuration Completed at Tenent Level.' -ForegroundColor Green
    }
    else {
      $client.TrackEvent("Search Configuration Completed at Tenent Level.")
      Write-Host 'Search Configuration Completed at Tenent Level.' -ForegroundColor Green
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
  
  Disconnect-PnPOnline
}

function New-SiteCollection($Type, $Title, $Alias, $isGlobalHubSite, $globalhubSiteUrl, $isSectorHubSite, $sectorhubSiteUrl, $isOrgSite, $orgSiteUrl) {
  try {
       
    if ($isGlobalHubSite -eq $true) {
      $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
    }
    if ($isSectorHubSite -eq $true) {
      $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
    }
    if ($isOrgSite -eq $true) {
      $siteExits = Get-PnPTenantSite -Url $orgSiteUrl -ErrorAction SilentlyContinue
    }
        
    #Check for existence of SPE Admin Site 
    if ([bool] ($siteExits) -eq $false) {
      Write-Host "Site collection not found ,so creating a new $globalhubSiteUrl" -ForegroundColor Green
      $client.TrackEvent("Site collection not found ,so creating a new $globalhubSiteUrl.....")
      #Create new site if site collection does not exist      
            
      if ($isGlobalHubSite) {
        try {
          New-PnPSite -Type $Type -Title $Title -Url $globalhubSiteUrl -SiteDesign Blank
          $client.TrackEvent("Site collection created.. $globalhubSiteUrl") 
        }
        catch {
          $ErrorMessage = $_.Exception.Message
          Write-Host $ErrorMessage -foreground Red

          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
          $telemtryException.Exception = $_.Exception.Message  
          $client.TrackException($telemtryException)

        }
      }
                
      if ($isSectorHubSite) {
        try {
          New-PnPSite -Type $Type -Title $Title -Url $sectorhubSiteUrl -SiteDesign Blank
          $client.TrackEvent("Site collection created.. $sectorhubSiteUrl") 
        }
        catch {
          $ErrorMessage = $_.Exception.Message
          Write-Host $ErrorMessage -foreground Red

          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
          $telemtryException.Exception = $_.Exception.Message  
          $client.TrackException($telemtryException)
        }
      }

      if ($isOrgSite) {
        try {
          New-PnPSite -Type $Type -Title $Title -Url $orgSiteUrl -SiteDesign Blank
          $client.TrackEvent("Site collection created.. $orgSiteUrl")
        }
        catch {
          $ErrorMessage = $_.Exception.Message
          Write-Host $ErrorMessage -foreground Red

          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
          $telemtryException.Exception = $_.Exception.Message  
          $client.TrackException($telemtryException)
        }
      }
                        
    }
    else {
      Write-Host "Site Collection- $siteTitle already exists" -ForegroundColor Yellow
      $client.TrackEvent("Site Collection- $siteTitle already exists")
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  } 
}

#region Enable Mega Menu/ Custom Navigation block, to add QuickLaunchNavigation or TopNavigation

function EnableMegaMenu($url) {
  try {
    $client.TrackEvent("MegaMenu Enable Started...")
    $web = Get-PnPWeb
    $web.MegaMenuEnabled = $true
    $web.Update()
    $client.TrackEvent("MegaMenu Enable Completed...")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-CustomQuickLaunchNavigationGlobal($url, $nodeLevel) {
  try {
    $client.TrackEvent("Configure Custom Navigation, Started.")

    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    Remove-PnPNavigationNode -Title Documents -Location QuickLaunch -Force
    Remove-PnPNavigationNode -Title Pages -Location QuickLaunch -Force
    Remove-PnPNavigationNode -Title "Site contents" -Location QuickLaunch -Force
    foreach ($level1 in $nodeLevel.Level1) {
      $isPresent = $false
      $allNavigationNodeQuickLaunch = Get-PnPNavigationNode -Location QuickLaunch
      foreach ($NavigationNodeQuickLaunch in $allNavigationNodeQuickLaunch) {
        if ($NavigationNodeQuickLaunch.Title -eq $level1.nodeName) {
          $isPresent = $true
        }
      }
      if ($isPresent -eq $false) {
        if ($level1.count -eq 3) {
          $rootNavurl = $level1.url
          #$rootNavcurrentURL = $url + "/Lists/" + $rootNavurl
          $rootNavcurrentURL = $url + $rootNavurl
          $rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Url $rootNavcurrentURL -Location "QuickLaunch" -ErrorAction Stop
        }
        else {
          $level1nodeName = $level1.nodeName       
          $rootNavNode = Add-PnPNavigationNode -Title $level1nodeName -Url "http://linkless.header/" -Location "QuickLaunch" -ErrorAction Stop
        }
        $client.TrackEvent("Root navigation node created, $level1.nodeName")

        foreach ($level2 in $level1.Level2) {
          $TopNav = Get-PnPNavigationNode -id  $rootNavNode.Id
          if ($level1.count -eq 1) {
            $level2url = $level2.url
            $level2currentURL = $urlprefix + $level2url
            AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id -ErrorAction Stop
          }
          if ($level1.count -eq 2) {
            $level2url = $level2.url
            #$level2currentURL = $url + "/Lists/" + $level2url
            $level2currentURL = $url + $level2url
            AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id -ErrorAction Stop
          }
          if ($level1.count -eq 3) {
            $level2url = $level2.url
            #$level2currentURL = $url + "/Lists/" + $level2url
            $level2currentURL = $url + $level2url
            AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id -ErrorAction Stop
          }
          if ($level1.count -eq 4) {
            if ($level2.nodeName -eq 'Site Contents') {
              $level2url = $url + $level2.url
            }
            else {
              $level2url = $level2.url
            }
            AddPnPNavigationNode $level2.nodeName $level2url $TopNav.Id -ErrorAction Stop
          }
            
          $client.TrackEvent("Navigation node created, $level2.nodeName")
          $TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id

          if ($TopNav.Children) {
            $child = $TopNav.Children | Select-Object Title, Url, Id
            foreach ($child in $TopNav.Children) { 
              foreach ($level3 in $level2.Level3) {
                if ($child.Title -eq $level2.nodeName) {
                  $level3url = $level3.url
                  $level3currentURL = $urlprefix + $level3url
                  AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id -ErrorAction Stop
                  $client.TrackEvent("Navigation node created, $level3.nodeName") 
                }
              }
            }
          }
        }
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-CustomNavigationQuickLaunchOnfailure $url $nodeLevel
  }
  Disconnect-PnPOnline
}

function Add-CustomQuickLaunchNavigationSector($url, $nodeLevel) {
  try {
    $client.TrackEvent("Configure Custom Navigation, Started.")
    Write-Host "Configure Custom Navigation, Started."
    $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    Remove-PnPNavigationNode -Title Documents -Location QuickLaunch -Force
    Remove-PnPNavigationNode -Title Pages -Location QuickLaunch -Force
    Remove-PnPNavigationNode -Title "Site contents" -Location QuickLaunch -Force
    foreach ($level1 in $nodeLevel.Level1) {

      $isPresent = $false
      $allNavigationNodeQuickLaunch = Get-PnPNavigationNode -Location QuickLaunch
      foreach ($NavigationNodeQuickLaunch in $allNavigationNodeQuickLaunch) {
        if ($NavigationNodeQuickLaunch.Title -eq $level1.nodeName) {
          $isPresent = $true
        }
      }

      if ($isPresent -eq $false) {
        if ($level1.count -eq 3) {
          $rootNavurl = $level1.url
          $rootNavcurrentURL = $url + $rootNavurl

          $rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Url $rootNavcurrentURL -Location "QuickLaunch"
        }
        else {
          $rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Location "QuickLaunch"
        }
        $client.TrackEvent("Root navigation node created, $level1.nodeName")
        Write-Host "Root navigation node created" $level1.nodeName

        foreach ($level2 in $level1.Level2) {
        
          $TopNav = Get-PnPNavigationNode -id  $rootNavNode.Id

          if ($level1.count -eq 1) {
            $level2sector = $urlprefix + $level2.sector
            if ($level2sector -eq $url) {
              $level2url = $level2.url
              $level2currentURL = $urlprefix + $level2url
              AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
            }               

          }
          if ($level1.count -eq 2) {
            $level2url = $level2.url
            $level2currentURL = $url + $level2url
            AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
          }
          if ($level1.count -eq 3) {
            $level2url = $level2.url
            $level2currentURL = $url + $level2url
            AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
          }
          if ($level1.count -eq 4) {
            if ($level2.nodeName -eq 'Site Contents') {
              $level2url = $url + $level2.url
            }
            else {
              $level2url = $level2.url
            }
            AddPnPNavigationNode $level2.nodeName $level2url $TopNav.Id
          }
        
            
          $client.TrackEvent("Navigation node created, $level2.nodeName")
          Write-Host "Navigation node created" $level2.nodeName
        
          $TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id

          if ($TopNav.Children) {
            $child = $TopNav.Children | Select-Object Title, Url, Id
            foreach ($child in $TopNav.Children) { 
              foreach ($level3 in $level2.Level3) {
                if ($child.Title -eq $level2.nodeName) {
                  $level3url = $level3.url
                  $level3currentURL = $urlprefix + $level3url
                  AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id
                  $client.TrackEvent("Navigation node created, $level3.nodeName") 
                  Write-Host "Navigation node created" $level3.nodeName
                }
              }
            }
          }
        }
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-CustomNavigationQuickLaunchOnfailure $url $nodeLevel
  }
  Disconnect-PnPOnline
}

function Add-CustomTopNavigationSector($url, $nodeLevel) {
  try {
    $client.TrackEvent("Configure Custom Navigation, Started.")
    Write-Host "Configure Custom Top Navigation, Started."
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
     
    foreach ($level1 in $nodeLevel.Level1) {
      $isPresent = $false
      $allNavigationTopNavigationBar = Get-PnPNavigationNode -Location TopNavigationBar
      foreach ($NavigationNodeTopNavigationBar in $allNavigationTopNavigationBar) {
        if ($NavigationNodeTopNavigationBar.Title -eq $level1.nodeName) {
          $isPresent = $true
        }
      }

      if ($isPresent -eq $false) {
        if ([bool]($level1.url) -eq $true) {  
          $level1URL = $urlprefix + $level1.url
          $rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Url $level1URL -Location "TopNavigationBar"
        }
        else {
          $rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Location "TopNavigationBar"
        }
        $client.TrackEvent("Root navigation node created, $level1.nodeName")
        Write-Host "Root navigation node created" $level1.nodeName

        foreach ($level2 in $level1.Level2) {
          $TopNav = Get-PnPNavigationNode -id  $rootNavNode.Id
          $level2url = $level2.url
          $level2currentURL = $urlprefix + $level2url
          AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
          $client.TrackEvent("Navigation node created, $level2.nodeName")
          $TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id
          if ($TopNav.Children) {
            $child = $TopNav.Children | Select-Object Title, Url, Id
            foreach ($child in $TopNav.Children) { 
              foreach ($level3 in $level2.Level3) {
                if ($child.Title -eq $level2.nodeName) {
                  $level3url = $level3.url
                  $level3currentURL = $urlprefix + $level3url
                  AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id
                  $client.TrackEvent("Navigation node created, $level3.nodeName") 
                  Write-Host "Navigation node created" $level3.nodeName
                }
              }
            }
          }
        }
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
  Disconnect-PnPOnline
}

function AddPnPNavigationNode($Title, $Url, $Parent) {
  $navigationNode = Add-PnPNavigationNode -Title $Title -Url $Url -Location "QuickLaunch" -Parent $Parent
}

#endregion

#region Apply theme block

function Add-Theme($themeName, $url, $tenantAdmin, $tenantUrl) {
  $themefilePath = $PSScriptRoot + '\resources\Themes.xml'
  [xml]$themefile = Get-Content -Path $themefilePath
  $themeToApply = $themefile.themes.$themeName
  
  $theme = @{
    "themePrimary"         = $themeToApply.themePrimary;
    "themeLighterAlt"      = $themeToApply.themeLighterAlt;
    "themeLighter"         = $themeToApply.themeLighter;
    "themeLight"           = $themeToApply.themeLight;
    "themeTertiary"        = $themeToApply.themeTertiary;
    "themeSecondary"       = $themeToApply.themeSecondary;
    "themeDarkAlt"         = $themeToApply.themeDarkAlt;
    "themeDark"            = $themeToApply.themeDark;
    "themeDarker"          = $themeToApply.themeDarker;
    "neutralLighterAlt"    = $themeToApply.neutralLighterAlt;
    "neutralLighter"       = $themeToApply.neutralLighter;
    "neutralLight"         = $themeToApply.neutralLight;
    "neutralQuaternaryAlt" = $themeToApply.neutralQuaternaryAlt;
    "neutralQuaternary"    = $themeToApply.neutralQuaternary;
    "neutralTertiaryAlt"   = $themeToApply.neutralTertiaryAlt;
    "neutralTertiary"      = $themeToApply.neutralTertiary;
    "neutralSecondary"     = $themeToApply.neutralSecondary;
    "neutralPrimaryAlt"    = $themeToApply.neutralPrimaryAlt;
    "neutralPrimary"       = $themeToApply.neutralPrimary;
    "neutralDark"          = $themeToApply.neutralDark;
    "black"                = $themeToApply.black;
    "white"                = $themeToApply.white;
  }
  try {
    $client.TrackEvent("Started applying themes")
    try {
      Add-ThemeToSiteCollection $themeName $url $tenantAdmin
    }
    catch {
      Add-ThemeAndApply $themeName $tenantUrl $url $tenantAdmin $theme
    }
    $client.TrackEvent("Themes applied successfully.")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

#endregion

#region --CreateNewGroup --

function Add-GroupAndUsers($url, $nodeLevel, $siteAlias) {

  $siteUrl = $url
  $connection = Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
   
  try {

    foreach ($SPGroup in $nodeLevel.group) {
      if ($siteAlias -eq "TASMU CMS") {
        $SPGroupName = 'Global ' + $SPGroup.Name
      }
      else {
        $SPGroupName = $siteAlias + ' ' + $SPGroup.Name
      }
      $groupExists = Get-PnPGroup $SPGroupName -Connection $connection -ErrorAction SilentlyContinue
        
      if ([bool]($groupExists) -eq $false) {
        Write-Host "Group not found. Creating new $($SPGroup.Name) group in $siteUrl" -ForegroundColor Green
        $client.TrackEvent("Group not found. Creating new $($SPGroup.Name) group in $siteUrl")
            
        New-PnPGroup -Title $SPGroupName -Description $SPGroup.Description
        Set-PnPGroupPermissions -Identity $SPGroupName -AddRole $SPGroup.Role
      }
      else {
        Write-Host "$($SPGroup.Name) already exists in $siteUrl" -ForegroundColor Yellow
        $client.TrackEvent("$($SPGroup.Name) already exists in $siteUrl")
      }

      #add users in group
      $GroupPresent = Get-PnPGroup -Identity $SPGroupName

      if ([bool]($GroupPresent) -eq $true) {

        if ($SPGroup.isUsers -eq $true) {
          $web = Get-PnPWeb  
          $ctx = $web.Context  
          $newGroupName = $web.SiteGroups.GetByName($SPGroupName)  
          $ctx.Load($newGroupName)  
          $ctx.ExecuteQuery()

          foreach ($user in $SPGroup.users) {
            try {                  
              $userName = $user.email  
              $userInfo = $web.EnsureUser($userName)  
              $ctx.Load($userInfo)  
              $addUser = $GroupPresent.Users.AddUser($userInfo)  
              $ctx.Load($addUser)  
              $ctx.ExecuteQuery()
            }
            catch {                    
              $ErrorMessage = $_.Exception.Message
              Write-Host $ErrorMessage -foreground Red

              $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
              $telemtryException.Exception = $_.Exception.Message  
              $client.TrackException($telemtryException)
            }
          }
        }

        if ($SPGroup.isADGroup -eq $true) {
          $web = Get-PnPWeb  
          $ctx = $web.Context  
          $newGroupName = $web.SiteGroups.GetByName($SPGroupName)  
          $ctx.Load($newGroupName)  
          $ctx.ExecuteQuery()

          foreach ($ADGroupUser in $SPGroup.ADGroup) {
            try {
                                   
              $ADGroup = $web.EnsureUser($ADGroupUser)                    
              #sharepoint online powershell add AD group to sharepoint group
              $Result = $GroupPresent.Users.AddUser($ADGroup)
              $ctx.Load($Result)
              $ctx.ExecuteQuery()
            }
            catch {                    
              $ErrorMessage = $_.Exception.Message
              Write-Host $ErrorMessage -foreground Red

              $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
              $telemtryException.Exception = $_.Exception.Message  
              $client.TrackException($telemtryException)
            }
          }
        }
        

        if ($SPGroup.SecurityGroup -ne '') {
          # Add Security group as member to Sharepoint group
          Add-PnPGroupMember -Group $SPGroupName -LoginName $SPGroup.SecurityGroup
        }
      }       
    }      
  }   
  catch {            
    Write-Host $_.Exception.Message -ForegroundColor Red
  }
  Disconnect-PnPOnline
}

function Edit-GroupOwner($url, $nodeLevel, $siteAlias) {
  $siteUrl = $url
  $connection = Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
   
  try {

    foreach ($SPGroup in $nodeLevel.group) {
      if ($siteAlias -eq "TASMU CMS") {
        $SPGroupName = 'Global ' + $SPGroup.Name
      }
      else {
        $SPGroupName = $siteAlias + ' ' + $SPGroup.Name
      }
      $groupExists = Get-PnPGroup $SPGroupName -Connection $connection -ErrorAction SilentlyContinue
        
      if ([bool]($groupExists) -eq $true) {
        try {
          $ownerGroup = Get-PnPGroup -AssociatedOwnerGroup
          #Set Group Owner
          Set-PnPGroup -Identity $SPGroupName -Owner $ownerGroup.Title
          Write-Host 'Group Owner updated for the group ' $SPGroupName 'successfully' -ForegroundColor Green
        }
        catch {
          $ErrorMessage = $_.Exception.Message
          Write-Host $ErrorMessage -foreground Red
        }
      }
    }      
  }   
  catch {            
    Write-Host $_.Exception.Message -ForegroundColor Red
  }
  Disconnect-PnPOnline
}

function Add-UsersToDefaultSharePointGroup($url, $nodeLevel, $siteAlias) {
  $siteUrl = $url
  $connection = Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
  try {

    foreach ($SPGroup in $nodeLevel.defaultgroup) {
      $SPGroupName = $siteAlias + ' ' + $SPGroup.Name
      $GroupPresent = Get-PnPGroup $SPGroupName -Connection $connection -ErrorAction SilentlyContinue
        
      if ([bool]($GroupPresent) -eq $true) {
        Write-Host "Group found. Adding users in $SPGroupName group in $siteUrl" -ForegroundColor Green
        $client.TrackEvent("Group found. Adding users inw $SPGroupName group in $siteUrl")
            
        #add users in group
        if ($SPGroup.isUsers -eq $true) {
          $web = Get-PnPWeb  
          $ctx = $web.Context  
          $newGroupName = $web.SiteGroups.GetByName($SPGroupName)  
          $ctx.Load($newGroupName)  
          $ctx.ExecuteQuery()

          foreach ($user in $SPGroup.users) {
            try {                  
              $userName = $user.email  
              $userInfo = $web.EnsureUser($userName)  
              $ctx.Load($userInfo)  
              $addUser = $GroupPresent.Users.AddUser($userInfo)  
              $ctx.Load($addUser)  
              $ctx.ExecuteQuery()
            }
            catch {                    
              $ErrorMessage = $_.Exception.Message
              Write-Host $ErrorMessage -foreground Red

              $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
              $telemtryException.Exception = $_.Exception.Message  
              $client.TrackException($telemtryException)
            }
          }
        }

        if ($SPGroup.isADGroup -eq $true) {
          $web = Get-PnPWeb  
          $ctx = $web.Context  
          $newGroupName = $web.SiteGroups.GetByName($SPGroupName)  
          $ctx.Load($newGroupName)  
          $ctx.ExecuteQuery()

          foreach ($ADGroupUser in $SPGroup.ADGroup) {

            try {
                                   
              $ADGroup = $web.EnsureUser($ADGroupUser)                    
              #sharepoint online powershell add AD group to sharepoint group
              $Result = $GroupPresent.Users.AddUser($ADGroup)
              $ctx.Load($Result)
              $ctx.ExecuteQuery()
            }
            catch {                    
              $ErrorMessage = $_.Exception.Message
              Write-Host $ErrorMessage -foreground Red

              $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
              $telemtryException.Exception = $_.Exception.Message  
              $client.TrackException($telemtryException)
            }
          }
        }

        if ($SPGroup.SecurityGroup -ne '') {
          # Add Security group as member to Sharepoint group
          Add-PnPGroupMember -Group $SPGroup.Name -LoginName $SPGroup.SecurityGroup
        }
      }
        
      else {
        Write-Host "$SPGroupName not found in $siteUrl" -ForegroundColor Yellow
        $client.TrackEvent("$SPGroupName not found in $siteUrl")
      }
    }
  }
  catch {            
    Write-Host $_.Exception.Message -ForegroundColor Red
  }
  Disconnect-PnPOnline
}

#endregion

#region --List And Library Creation --

function Add-ListAndLibrary($url, $nodeLevel) {

  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

  $admin = $tenantAdmin.UserName
  $password = $tenantAdmin.Password
  $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)

  #create all list
  $siteUrlNew = $url
  EnableSitePagesFeatureAtSiteLevel $siteUrlNew

  #create all List & Libraries
  $client.TrackEvent("List and Library creation started.")
        
  foreach ($itemList in $nodeLevel.ListAndContentTypes) {
    if ($itemList.ListTemplate -eq "GenericList") {
      $ListURL = "Lists/" + $itemList.ListName
    }
    else {
      $ListURL = $itemList.ListName
    }
            
    $ListURL = $ListURL -replace '\s', ''
            
    New-ListAddContentType $tenantAdmin $siteUrlNew $itemList.ListName $itemList.ListTemplate $ListURL $itemList.ContentTypeName $itemList.Field.LookupListName $itemList.Field.LookupField $itemList.projectedField $itemList.Field.ColumnName $itemList.Field.ColumnTitle $itemList.Field.Type $itemList.columnItem $itemList.Data.Item $itemList.ParentCTName $itemList.GroupName $itemList.Field.EnforceUniqueValues $itemList.Field.Required

    if (Get-PnPList -Identity $itemList.ListName) {     
      New-View $itemList.ListName $siteUrlNew $itemList.defaultviewfields $itemList.ListTemplate
    }

    if ($itemList.customView -ne '') {
      if (Get-PnPList -Identity $itemList.ListName) {
        New-CustomView $itemList.ListName $siteUrlNew $itemList.customView $itemList.customViewfields
      }
    }
    if (Get-PnPList -Identity $itemList.ListName) {
      # Enable document set content type only for Services List
      if ($itemList.ListName -eq 'Services') {
        EnableDocumentSetFeatureOnTargetSite $siteUrlNew $itemList.ListName
      }
    } 
  }
}

function GrantPermissionOnListToGroup($url, $nodeLevel) {
  #GrantPermissionOnListToGroup List & Libraries
  $client.TrackEvent("List and Library creation started.")
        
  foreach ($itemList in $nodeLevel.ListAndContentTypes) {
    #Grant permission on list to Group
    Set-PnPListPermission -Identity $itemList.ListName -AddRole "Read" -Group $GroupName
    Set-PnPListPermission -Identity $itemList.ListName -AddRole "Read" -Group $GroupName
    Set-PnPListPermission -Identity $itemList.ListName -AddRole "Read" -Group $GroupName
  }
}

function Set-FieldToRichText($SiteUrl, $ListName, $FieldName) {
  Write-Host "Updating $FieldName to RichText for $ListName in $SiteUrl..."  -ForegroundColor Green

  $admin = $sp_user
  $password = $sp_password
  $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
  $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
  $context.Credentials = $credentials
  try {
    $web = $context.Web
    $list = $web.Lists.GetByTitle($ListName)
    $context.Load($web)
    $context.Load($web.Lists)
    $context.Load($list.Fields)
    $context.ExecuteQuery()
    $field = $list.Fields | Where-Object { $_.InternalName -eq $FieldName }
    if ($null -ne $field) {
      $field.RichText = $True
      $field.Update()
      $context.ExecuteQuery()
    }
  }
  catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
  }
}

function New-ListAddContentType($tenantAdmin, $siteUrlNew, $ListName, $ListTemplate, $ListURL, $ContentTypeName, $LookupListName, $LookupField, $ProjectedFields, $LookupFieldColumnName, $LookupFieldColumnTitle, $LookupFieldType, $ColumnItems, $Items, $ParentContentTypeName, $GroupName, $enforceUniqueValues, $required) {
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

  try {
    $connection = Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin -ErrorAction Stop

    if ([bool]$LookupFieldColumnName -eq $true -and [bool]$LookupListName -eq $true -and [bool]$LookupField -eq $true) {
      if ([string]::IsNullOrWhiteSpace($enforceUniqueValues)) {
        $enforceUniqueValues = 'FALSE'  
      }
      else {
        $enforceUniqueValues = 'TRUE' 
      }
      New-LookupColumnForList -SiteURL $siteUrlNew -ListName $ListName -Name $LookupFieldColumnName -DisplayName $LookupFieldColumnTitle -LookupListName $LookupListName -LookupField $LookupField -LookupType $LookupFieldType -ProjectedFields $ProjectedFields -GroupName $GroupName -EnforceUniqueValues $enforceUniqueValues -IsRequired $required $connection
    }
        
    if ([bool]($ParentContentTypeName) -eq $true) {
      #Call the function to Create ContentType
      New-ContentType $globalhubSiteUrl $ContentTypeName $ContentTypeName $ParentContentTypeName $GroupName $connection

      foreach ($columnItem in $ColumnItems) {
        New-FieldToContentType $globalhubSiteUrl $columnItem.ContentTypeName $columnItem.ColumnName $connection $columnItem.Required
      } 
    }

    $ListExist = Get-PnPList -Identity $ListURL -ErrorAction Stop
    if ([bool]($ListExist) -eq $false) {
      Write-Host "List not found in $siteUrlNew creating new List - $ListName .."  -ForegroundColor Green
      $client.TrackEvent("List not found in $siteUrlNew creating new List - $ListName ..")

      if ($ListName -eq "Documents") {                
        $newList = New-PnPList -Title $ListName -Template $ListTemplate -ErrorAction Stop
      }
      else {
        if ($ListName -ne "Site Pages") {
          $newList = New-PnPList -Title $ListName -Template $ListTemplate -Url $ListURL -ErrorAction Stop
          $client.TrackEvent("List/Library created, $ListName")
        }
      }
      
      $List = Get-PnPList -Identity $ListURL -ErrorAction Stop
      if ($ContentTypeName -ne '') {

        $ListBase = Get-PnPContentType -Identity $ContentTypeName -ErrorAction Stop -Connection $connection
        Set-PnPList -Identity $ListName -EnableContentTypes $true -EnableVersioning $true
        $addContentType = Add-PnPContentTypeToList -List $List -ContentType $ContentTypeName -DefaultContentType -ErrorAction Stop
        $client.TrackEvent("Content Type, $ContentTypeName added to List, $ListName")

        if ($ListName -eq "My Tasks") {
          $secondContentTypeName = "TASMU Translation Tasks"
          $secondListBase = Get-PnPContentType -Identity $secondContentTypeName -ErrorAction Stop -Connection $connection
          $addContentType = Add-PnPContentTypeToList -List $List -ContentType $secondListBase -ErrorAction Stop
          $client.TrackEvent("Content Type, $secondContentTypeName added to List, $ListName")                
        }

        #remove content type which gets created by default

        if ($ListTemplate -eq 'GenericList') {
          #Get the content type
          $BaseItemContentType = Get-PnPContentType -Identity "Item" -Connection $connection -ErrorAction Stop
 
          If ($BaseItemContentType) {
            Remove-PnPContentTypeFromList -List $List -ContentType $BaseItemContentType -ErrorAction Stop
            $client.TrackEvent("Default Content Type, $BaseItemContentType deleted from List, $ListName")
          }
        }
        if ($ListTemplate -eq 'DocumentLibrary') {
          #Get the content type
          $BaseDocContentType = Get-PnPContentType -Identity "Document" -Connection $connection -ErrorAction Stop
 
          If ($BaseDocContentType) {
            Remove-PnPContentTypeFromList -List $List -ContentType $BaseDocContentType -ErrorAction Stop
            $client.TrackEvent("Default Content Type, $BaseDocContentType deleted from Library, $ListName")
          }
        }
        if ($ListTemplate -eq 'PictureLibrary') {
          #Get the content type
          $BasePicContentType = Get-PnPContentType -Identity "Picture" -Connection $connection -ErrorAction Stop
 
          If ($BasePicContentType) {
            Remove-PnPContentTypeFromList -List $List -ContentType $BasePicContentType -ErrorAction Stop
            $client.TrackEvent("Default Content Type, $BasePicContentType deleted from picture Library, $ListName")
          }
        }
      }

      #Adding data to the created list
      foreach ($item in $Items) {
        $hash = $null
        $hash = @{}
        foreach ($attr in $item.Attributes) {
          $hash.add($attr.Name, $attr.Value)
        }
        Write-Host "Adding item to " $ListName  -ForegroundColor Green
        $client.TrackEvent("Adding item to $ListName")
        $addListItem = Add-PnPListItem -List $ListName -Values $hash
      }
    }
    else {
      Write-Host "$ListName already exists in $siteUrlNew" -ForegroundColor Yellow
      $client.TrackEvent("$ListName already exists in $siteUrlNew")
    } 
    #Disconnect-PnPOnline
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-ListOnFailure $siteUrlNew $ListName
  }
}

function Remove-ContentTypeFromListLibrary($SiteUrl, $ListName, $ContentType) {
    
  Write-Host "Removing $ContentType content type from $ListName in $SiteUrl"  -ForegroundColor Green
  $client.TrackEvent("Removing $ContentType content type from $ListName in $SiteUrl")
  try {
    Connect-PnPOnline -Url $SiteUrl -Credentials $tenantAdmin
    $list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    if ($null -ne $list) {
      Remove-PnPContentTypeFromList -List $ListName -ContentType $ContentType
    }
    Disconnect-PnPOnline
  }
  catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
  }
}

function EnableSitePagesFeatureAtSiteLevel($siteUrlNew) {
  $client.TrackEvent("Enable SitePages Feature At SiteLevel Started.")
  Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin
  $connection = Get-PnPConnection

  #activate feature for site pages
  Write-Host "Enabling feature for site pages - b6917cb1-93a0-4b97-a84d-7cf49975d4ec"  -ForegroundColor Green
  $client.TrackEvent("Enabling feature for site pages - b6917cb1-93a0-4b97-a84d-7cf49975d4ec")
    
  Enable-PnPFeature -Identity b6917cb1-93a0-4b97-a84d-7cf49975d4ec -Connection $connection -Scope Web -Force
  #enable Team Collaboration Lists feature
  Write-Host "Enabling feature for Team Collaboration Lists - 00bfea71-4ea5-48d4-a4ad-7ea5c011abe5"  -ForegroundColor Green
  $client.TrackEvent("Enabling feature for Team Collaboration Lists - 00bfea71-4ea5-48d4-a4ad-7ea5c011abe5")
    
  Enable-PnPFeature -Identity 00bfea71-4ea5-48d4-a4ad-7ea5c011abe5 -Connection $connection -Scope Web -Force

        
  Disconnect-PnPOnline
}

function EnableDocumentSetFeatureOnTargetSite($siteUrlNew, $ListName) {
  $client.TrackEvent("Enabling docset feature on target site Started.")
  Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin
  $connection = Get-PnPConnection

  #activate feature for site pages
  Write-Host "Enabling docset feature on target site - 3bae86a2-776d-499d-9db8-fa4cdc7884f8"  -ForegroundColor Green
  $client.TrackEvent("Enabling feature for site pages - 3bae86a2-776d-499d-9db8-fa4cdc7884f8")
    
  Enable-PnPFeature -Identity 3bae86a2-776d-499d-9db8-fa4cdc7884f8 -Connection $connection -Scope Site -Force

  Set-PnPList -Identity $ListName -EnableContentTypes $true
  $addContentType = Add-PnPContentTypeToList -List $ListName -ContentType "Document Set"
        
  Disconnect-PnPOnline
}

function RenameColumn($siteColUrl, $ListName, $ColumnName, $DisplayName, $spoCtx) {
  Try {

    [Microsoft.SharePoint.Client.Web]$web = $spoCtx.Web
    $spoCtx.ExecuteQuery();

    #Get the List
    [Microsoft.SharePoint.Client.List]$List = $spoCtx.Web.Lists.GetByTitle($ListName)
    $spoCtx.Load($List)
    $spoCtx.ExecuteQuery()
 
    #Get the column to rename
    $Field = $List.Fields.GetByInternalNameOrTitle($ColumnName)
    $Field.Title = $DisplayName
    $Field.Update()
    $spoCtx.ExecuteQuery()
    $spoCtx.Dispose()
    Write-Host "Column Name Changed successfully! in site - $siteColUrl" -ForegroundColor Green 
    $client.TrackEvent("Column Name Changed successfully! in site - $siteColUrl")
  }
  Catch {
    Write-Host -f Red "Error Renaming Column! -$siteColUrl" $_.Exception.Message
  }
}
#endregion

#region --CreateView--
function New-View($listNameForView, $siteUrlNew, $fields, $ListTemplate) {
    
  $client.TrackEvent("View creation started for list, $listNameForView.")
  try {
             
    if ($ListTemplate -eq 'DocumentLibrary') {
      $defaultviewName = 'All Documents'
    }
    else {
      if ($ListTemplate -eq 'PictureLibrary') {
        $defaultViewName = 'All Images'
      }
      else {
        $defaultviewName = 'All Items'
      }
    }
    
    $viewExists = Get-PnPView -List $listNameForView -Identity $defaultviewName -ErrorAction SilentlyContinue
         
    foreach ($field in $fields) {
      $defaultviewfields += @($field.name)
    }

    $client.TrackEvent("Fields ready for default view creation.")

    if ([bool]($viewExists) -eq $false) {
      Write-Host "View not found ,so creating a new View in $listNameForView"  -ForegroundColor Green
      $client.TrackEvent("View not found ,so creating a new View in $listNameForView")
      if ($ListTemplate -eq 'PictureLibrary') {
        $addView = Add-PnPView -List $listNameForView -Title $defaultviewName -Fields $defaultviewfields -ViewType Grid -SetAsDefault -ErrorAction Stop
      }
      else {
        $addView = Add-PnPView -List $listNameForView -Title $defaultviewName -Fields $defaultviewfields -SetAsDefault -ErrorAction Stop
      }
      #delete the LinkTitle from default view
      Edit-FieldsToDefaultView -ListName $listNameForView $defaultviewName $siteUrlNew
    }
    else {
      Write-Host "View already exists in List $listNameForView site- $siteUrlNew " -ForegroundColor Yellow
      $client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")

      New-ColumnToDefaultView -SiteUrl $siteUrlNew -Fields $defaultviewfields -ListName $listNameForView
            
      #delete the LinkTitle from default view
      Edit-FieldsToDefaultView -ListName $listNameForView $defaultviewName $siteUrlNew
    }

    #region update the sorting order for the view 
    Edit-View $siteUrlNew $tenantAdmin $defaultviewName $listNameForView
    #endregion
    $client.TrackEvent("View sorting order is modified for $defaultviewName for the list $listNameForView")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage "in Site $siteUrlNew  List $listNameForView " -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-ListOnFailure $siteUrlNew $listNameForView
  }
  #Disconnect-PnPOnline
}

function New-CustomView($listNameForView, $siteUrlNew, $customViewName, $fields) {

  try {
    $viewExists = Get-PnPView -List $listNameForView -Identity $customViewName -ErrorAction SilentlyContinue
    $arHomeViewName = "الرئيسية"
    if ([bool]($viewExists) -eq $false) {
      Write-Host "View not found ,so creating a new View in $listNameForView"  -ForegroundColor Green
      $client.TrackEvent("View not found ,so creating a new View in $listNameForView")

      foreach ($field in $fields) {
        $customViewfields += @($field.name)
      }
      #check for picture library
      $list = Get-PnPList -Identity $listNameForView -ErrorAction Stop
      if ($list.BaseTemplate -eq 109) {
        $addView = Add-PnPView -List $listNameForView -Title $customViewName -Fields $customViewfields -ViewType Grid -ErrorAction Stop  
        $addArHomeView = Add-PnPView -List $listNameForView -Title $arHomeViewName -Fields $customViewfields -ViewType Grid -ErrorAction Stop
      }
      else {
        $addView = Add-PnPView -List $listNameForView -Title $customViewName -Fields $customViewfields -ErrorAction Stop
        $addArHomeView = Add-PnPView -List $listNameForView -Title $arHomeViewName -Fields $customViewfields -ErrorAction Stop
      }
    }
    else {
      Write-Host "View already exists in List $listNameForView site- $siteUrlNew " -ForegroundColor Yellow
      $client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")

      New-ColumnToCustomView -SiteUrl $siteUrlNew -Fields $customViewfields -ListName $listNameForView -ViewName $customViewName
    }

    #region update the sorting order for the view 
    Edit-View $siteUrlNew $tenantAdmin $customViewName $listNameForView
    #endregion
    $client.TrackEvent("View sorting order is modified for $customViewName for the list $listNameForView")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage "in Site $siteUrlNew  List $listNameForView " -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-ListOnFailure $siteUrlNew $listNameForView
  }
  #Disconnect-PnPOnline
}

function Edit-ViewForTasksList($listNameForView, $siteUrlNew) {   
  try {
    Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin -ErrorAction Stop

    $allItemViewMyTasks = Get-PnPView -List $listNameForView -Identity 'All Items' -ErrorAction SilentlyContinue
        
    if ([bool]($allItemViewMyTasks) -eq $true) {
      $PnPContext = Get-PnPContext
      $allItemViewMyTasks.ViewQuery = "<Where><Eq><FieldRef Name='cmsAssignedToUser'/><Value Type='Integer'><UserID Type='Integer'/></Value></Eq></Where>"
      $allItemViewMyTasks.Update()
      $PnPContext.ExecuteQuery()
      Write-Host "All Items - View updated for $listNameForView list."  -ForegroundColor Green
      $client.TrackEvent("All Items - View updated for $listNameForView list.")
    }
    else {
      Write-Host "View not found in List $listNameForViews site- $siteUrlNew " -ForegroundColor Yellow
      $client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")
    }

    $HomeViewMyTasks = Get-PnPView -List $listNameForView -Identity 'Home' -ErrorAction SilentlyContinue

    if ([bool]($HomeViewMyTasks) -eq $true) {

      $PnPContext = Get-PnPContext
      $HomeViewMyTasks.ViewQuery = "<Where><Eq><FieldRef Name='cmsAssignedToUser'/><Value Type='Integer'><UserID Type='Integer'/></Value></Eq></Where>"
      $HomeViewMyTasks.Update()
      $PnPContext.ExecuteQuery()
      Write-Host "Home - View updated for $listNameForView list."  -ForegroundColor Green
      $client.TrackEvent("Home - View updated for $listNameForView list.")
    }
    else {
      Write-Host "View already exists in List $listNameForView site- $siteUrlNew " -ForegroundColor Yellow
      $client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage "in Site $siteUrlNew  List $listNameForView " -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-ListOnFailure $siteUrlNew $listNameForView
  }
  #Disconnect-PnPOnline
}

function New-SPFXWebPart($siteUrl, $tenantAdmin, $scope) {
  try {
    [xml]$appFile = Get-Content -Path $appsPath
    foreach ($app in $appFile.Apps.app) {
      if ($app.Scope -eq $scope) {
        Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
        $tenantApps = Get-PnPApp -Scope Tenant
        if ($null -ne $tenantApps) {
          foreach ($tenantApp in $tenantApps) {
            if ($tenantApp.Title -eq $app.Title) {
              try {
                $installedApp = Get-PnPApp -Identity $tenantApp.Id
                if ([bool]($installedApp) -eq $True) {
                  Update-PnPApp -Identity $tenantApp.Id
                  Write-Host 'App' $app.Title ' updated successfully for the site' $SiteUrl -f Green
                }
                Install-PnPApp -Identity $tenantApp.Id
                Write-Host 'App' $app.Title ' deployed successfully to the site' $SiteUrl -f Green
              }
              catch {
                $ErrorMessage = $_.Exception.Message
                Write-Host $ErrorMessage -ForegroundColor Red
              }
            }
          }
        }
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -ForegroundColor Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function New-SiteCollectionAppCatalog($siteUrl) {     
  try {  
    Add-PnPSiteCollectionAppCatalog -Site $siteUrl             
    Write-Host 'App catalog created successfully for the site collection' + $siteUrl -ForegroundColor Green
  }     
  catch {         
    $ErrorMessage = $_.Exception.Message         
    Write-Host $ErrorMessage "In Site $siteUrl " -foreground Red         
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"        
    $telemtryException.Exception = $_.Exception.Message
    $client.TrackException($telemtryException)     
  } 
}

function New-ColumnToDefaultView($SiteUrl, $Fields, $ListName) {
  Write-Host "Updating view for $ListName..."  -ForegroundColor Green
  $client.TrackEvent("Updating view for $ListName...")
  $admin = $tenantAdmin.UserName
  $password = $tenantAdmin.Password
  $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
  $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
  $context.Credentials = $credentials
  $web = $context.Web
  $list = $web.Lists.GetByTitle($ListName)
  $defaultFields = $list.DefaultView.ViewFields
    
  $context.Load($web)
  $context.Load($web.Lists)
  $context.Load($list.Fields)
  $context.Load($defaultFields)
  $context.ExecuteQuery()

  try {
    [int]$fieldOrder = 0
    foreach ($f in $Fields) {
      $field = $list.Fields | Where-Object { $_.InternalName -eq $f } | Select-Object -First 1
      if ($null -ne $field) {
        $isField = $defaultFields | Where-Object { $_ -eq $field.Title -or $_ -eq $field.InternalName }
        if ($null -eq $isField) {
          $defaultFields.Add($field.InternalName)
        }
        $defaultFields.MoveFieldTo($field.InternalName, $fieldOrder)
      }      
      $list.DefaultView.Update()
      $fieldOrder++
    }

    # If view contains Pinned column, then sort with Pinned then Modified Date
    $isContainsPinned = $list.Fields | Where-Object { $_.InternalName -eq 'Pinned' }
    if ($null -ne $isContainsPinned) {
      $viewQuery = '<OrderBy><FieldRef Name="Pinned" Ascending="FALSE" /><FieldRef Name="Modified" Ascending="FALSE" /></OrderBy>'
      $list.DefaultView.ViewQuery = $viewQuery
      $list.DefaultView.Update()
    }
    else {
      $viewQuery = '<OrderBy><FieldRef Name="Modified" Ascending="FALSE"/></OrderBy>'
      $list.DefaultView.ViewQuery = $viewQuery
      $list.DefaultView.Update()
    }
    $context.ExecuteQuery()
  }
  catch {
    Write-Host $_.Exception.Message -ForegroundColor Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-ListOnFailure $SiteUrl $ListName
  }
}

function New-ColumnToCustomView($SiteUrl, $Fields, $ListName,$ViewName) {
  Write-Host "Updating view for $ListName..."  -ForegroundColor Green
  $client.TrackEvent("Updating view for $ListName...")
  $admin = $tenantAdmin.UserName
  $password = $tenantAdmin.Password
  $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
  $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
  $context.Credentials = $credentials
  $web = $context.Web
  $list = $web.Lists.GetByTitle($ListName)
  $customView = $List.Views.GetByTitle($ViewName)
  $defaultFields = $customView.ViewFields
    
  $context.Load($web)
  $context.Load($web.Lists)
  $context.Load($list.Fields)
  $context.Load($customView)
  $context.Load($defaultFields)
  $context.ExecuteQuery()

  try {
    [int]$fieldOrder = 0
    foreach ($f in $Fields) {
      $field = $list.Fields | Where-Object { $_.InternalName -eq $f } | Select-Object -First 1
      if ($null -ne $field) {
        $isField = $defaultFields | Where-Object { $_ -eq $field.Title -or $_ -eq $field.InternalName }
        if ($null -eq $isField) {
          $defaultFields.Add($field.InternalName)
        }
        $defaultFields.MoveFieldTo($field.InternalName, $fieldOrder)
      }      
      $list.DefaultView.Update()
      $fieldOrder++
    }

    # If view contains Pinned column, then sort with Pinned then Modified Date
    $isContainsPinned = $list.Fields | Where-Object { $_.InternalName -eq 'Pinned' }
    if ($null -ne $isContainsPinned) {
      $viewQuery = '<OrderBy><FieldRef Name="Pinned" Ascending="FALSE" /><FieldRef Name="Modified" Ascending="FALSE" /></OrderBy>'
      $list.DefaultView.ViewQuery = $viewQuery
      $list.DefaultView.Update()
    }
    else {
      $viewQuery = '<OrderBy><FieldRef Name="Modified" Ascending="FALSE"/></OrderBy>'
      $list.DefaultView.ViewQuery = $viewQuery
      $list.DefaultView.Update()
    }
    $context.ExecuteQuery()
  }
  catch {
    Write-Host $_.Exception.Message -ForegroundColor Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-ListOnFailure $SiteUrl $ListName
  }
}
#endregion

#region --Create Page, Webparts & Section--

function New-WebPartToPage($url, $nodeLevel) {
  try {
    #Load SharePoint CSOM Assemblies
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
    $client.TrackEvent("Page creation & Webpart addition to page started.") 
         
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin -ErrorAction Stop

    $pagename = $nodeLevel.webpartSection.pagename
    $page = Get-PnPPage -Identity $pagename -ErrorAction Stop           
        
    if ($null -ne $page) {
      Add-PnPPageSection -Page $page -SectionTemplate $nodeLevel.webpartSection.SectionTemplate -ErrorAction Stop
        
      foreach ($webpartSection in $nodeLevel.webpartSection) {
        foreach ($webpartSection in $webpartSection.webpart) {
          if ($webpartSection.DefaultWebPartType -eq 'List') {
            Write-Host "Updating the web part " $webpartSection.ListTitleDisplay  -ForegroundColor Green
            $admin = $tenantAdmin.UserName
            $password = $tenantAdmin.Password
            $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
            $context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
            $context.Credentials = $credentials

            try {
              $web = $context.Web
              $list = $web.Lists.GetByTitle($webpartSection.ListTitle)
              $ListView = $list.views.GetByTitle($webpartSection.ViewName)                        
              $context.Load($list)
              $context.Load($ListView)
              $context.ExecuteQuery()
            }
            catch {
              Write-Host $_.Exception.Message -ForegroundColor Red
            }

            if ($webpartSection.hideCommandBar -eq "True") {
              $jsonProperties = '{"selectedListId":"' + $list.Id + '","listTitle":"' + $webpartSection.ListTitleDisplay + '","webpartHeightKey":1,"hideCommandBar":true,"selectedViewId":"' + $ListView.Id + '"}'
            }
            else {
              $jsonProperties = '{"selectedListId":"' + $list.Id + '","listTitle":"' + $webpartSection.ListTitleDisplay + '","webpartHeightKey":1,"hideCommandBar":false,"selectedViewId":"' + $ListView.Id + '"}'
            }
                    
            $listWebpart = Add-PnPPageWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -WebPartProperties $jsonProperties -ErrorAction Stop
            Write-Host "Webpart " $listWebpart.InstanceId " added successfully with properties " $listWebpart.PropertiesJson  -ForegroundColor Green
          }
                  
          if ($webpartSection.DefaultWebPartType -eq 'SiteActivity') {
            Add-PnPPageWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -WebPartProperties @{"title" = "Recent Activity"; maxItems = "9" } -ErrorAction Stop
          }

          if ($webpartSection.DefaultWebPartType -eq 'QuickLinks') {

            $item0Title = $webpartSection.items.item[0].Title
            $item0Url = $url + $webpartSection.items.item[0].ListUrl
                        
            $item1Title = $webpartSection.items.item[1].Title
            $item1Url = $url + $webpartSection.items.item[1].ListUrl

            $item2Title = $webpartSection.items.item[2].Title
            $item2Url = $url + $webpartSection.items.item[2].ListUrl

            $item3Title = $webpartSection.items.item[3].Title
            $item3Url = $url + $webpartSection.items.item[3].ListUrl

            $item4Title = $webpartSection.items.item[4].Title
            $item4Url = $url + $webpartSection.items.item[4].ListUrl

            $item5Title = $webpartSection.items.item[5].Title
            $item5Url = $url + $webpartSection.items.item[5].ListUrl

            $item6Title = $webpartSection.items.item[6].Title
            $item6Url = $url + $webpartSection.items.item[6].ListUrl

            $item7Title = $webpartSection.items.item[7].Title
            $item7Url = $url + $webpartSection.items.item[7].ListUrl

            $item8Title = $webpartSection.items.item[8].Title
            $item8Url = $url + $webpartSection.items.item[8].ListUrl

            $item9Title = $webpartSection.items.item[9].Title
            $item9Url = $url + $webpartSection.items.item[9].ListUrl

            $item10Title = $webpartSection.items.item[10].Title
            $item10Url = $url + $webpartSection.items.item[10].ListUrl

            $jsonProps = '
{"controlType":3,"id":"41d11bca-2e0b-47c8-a6e8-185a9d7c5dd9","position":{"zoneIndex":1,"sectionIndex":1,"controlIndex":1,"layoutIndex":1},"webPartId":"c70391ea-0b10-4ee9-b2b4-006d3fcad0cd","webPartData":{"id":"c70391ea-0b10-4ee9-b2b4-006d3fcad0cd","instanceId":"41d11bca-2e0b-47c8-a6e8-185a9d7c5dd9","title":"Quick links","description":"Add links to important documents and pages.","serverProcessedContent":{"htmlStrings":{},"searchablePlainTexts":{"title":"Quick Links","items[0].title":"' + $item0Title + '","items[1].title":"' + $item1Title + '","items[2].title":"' + $item2Title + '","items[3].title":"' + $item3Title + '","items[4].title":"' + $item4Title + '","items[5].title":"' + $item5Title + '","items[6].title":"' + $item6Title + '","items[7].title":"' + $item7Title + '","items[8].title":"' + $item8Title + '","items[9].title":"' + $item9Title + '","items[10].title":"' + $item10Title + '"},"imageSources":{},"links":{"baseUrl":"' + $url + '","items[0].sourceItem.url":"' + $item0Url + '","items[1].sourceItem.url":"' + $item1Url + '","items[2].sourceItem.url":"' + $item2Url + '","items[3].sourceItem.url":"' + $item3Url + '","items[4].sourceItem.url":"' + $item4Url + '","items[5].sourceItem.url":"' + $item5Url + '","items[6].sourceItem.url":"' + $item6Url + '","items[7].sourceItem.url":"' + $item7Url + '","items[8].sourceItem.url":"' + $item8Url + '","items[9].sourceItem.url":"' + $item9Url + '","items[10].sourceItem.url":"' + $item10Url + '"},"componentDependencies":{"layoutComponentId":"706e33c8-af37-4e7b-9d22-6e5694d92a6f"}},"dataVersion":"2.2","properties":{"items":[{"sourceItem":{"itemType":5,"fileExtension":"","progId":""},"thumbnailType":3,"id":11,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":10,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":9,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":8,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":7,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":6,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":5,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":4,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":3,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":2,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":1,"description":"","altText":""}],"isMigrated":true,"layoutId":"List","shouldShowThumbnail":true,"imageWidth":100,"buttonLayoutOptions":{"showDescription":false,"buttonTreatment":2,"iconPositionType":2,"textAlignmentVertical":2,"textAlignmentHorizontal":2,"linesOfText":2},"listLayoutOptions":{"showDescription":false,"showIcon":false},"waffleLayoutOptions":{"iconSize":1,"onlyShowThumbnail":false},"hideWebPartWhenEmpty":true,"dataProviderId":"QuickLinks","webId":"93012ab1-1675-4c10-a48d-9318b877ab5e","siteId":"8051fa3b-1aeb-4793-8354-d5c2eb571b6d"}},"emphasis":{},"reservedHeight":270,"reservedWidth":744,"addedFromPersistedData":true}
'
            Add-PnPPageWebPart -Page $page -DefaultWebPartType QuickLinks -WebPartProperties $jsonProps -Section $webpartSection.Section -Column $webpartSection.Column -Order 3
          }

          if ($webpartSection.DefaultWebPartType -eq 'ContentRollup') {
            Add-PnPPageWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -Order 2 -WebPartProperties @{"title" = "Recent documents"; "count" = 5 } -ErrorAction Stop
          }
        }
      }
    }
    else {
      Write-Host "Page does not exist or is not modern $webpart.pagename" -ForegroundColor Yellow
      $client.TrackEvent("Page does not exist or is not modern $webpart.pagename")
    }
  }
  catch {  
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red  
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-PageOnFailure $pagename
  }
}

function Edit-ListViewWebPartProperties($page, $webpartkeyHeight, $url, $tenantAdmin) {
  Connect-PnPOnline -Url $url -Credentials $tenantAdmin
  $wpList = Get-PnPPageComponent -Page $page
  foreach ($wp in $wpList) {
    try {
      if ($wp.Title -eq "List") {
        Write-Host "Webpart " $wp.InstanceId " PropertiesJson is : " $wp.PropertiesJson  -ForegroundColor Green
        $prop = $wp.PropertiesJson
        $property = $prop | ConvertFrom-Json
        $property.webpartHeightKey = $webpartkeyHeight
        $prop = $property | ConvertTo-Json
        Write-Host "Updated PropertiesJson is " $prop  -ForegroundColor Green
        Set-PnPPageWebPart -Page $page -Identity $wp.InstanceId -PropertiesJson $prop
      }
    }
    catch {
      $ErrorMessage = $_.Exception.Message
      Write-Host $ErrorMessage -foreground Red  

      $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
      $telemtryException.Exception = $_.Exception.Message  
      $client.TrackException($telemtryException)
    }
  }
}

function Edit-RegionalSettings($url, $tenantAdmin) {
  try {
    #Load SharePoint CSOM Assemblies
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
  
    #Config parameters for SharePoint Online Site URL and Timezone description
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($url)
    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
    $Ctx.Credentials = $credentials
    $Web = $Ctx.Web
    $regionalSettings = $Web.RegionalSettings
    $timezones = $Web.RegionalSettings.TimeZones
    $Ctx.Load($regionalSettings)
    $Ctx.Load($timezones)
    $Ctx.ExecuteQuery()
    $Web.RegionalSettings.LocaleId = 16385 # Arabic(Qatar)
    $Web.RegionalSettings.WorkDayStartHour = 480 # 8 AM
    $Web.RegionalSettings.WorkDayEndHour = 1020 # 5 PM
    $Web.RegionalSettings.FirstDayOfWeek = 0 # Sunday
    $Web.RegionalSettings.Time24 = $False
    $Web.RegionalSettings.CalendarType = 10 #Gregorian Arabic Calendar
    $Web.RegionalSettings.AlternateCalendarType = 0 #None
    $Web.RegionalSettings.WorkDays = 124
    $TimezoneName = "(UTC) Coordinated Universal Time"
    $NewTimezone = $Timezones | Where-Object { $_.Description -eq $TimezoneName }
    $Ctx.Web.RegionalSettings.TimeZone = $NewTimezone
    $Web.Update()
    $Ctx.ExecuteQuery()
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function New-ModernPage($url, $nodeLevel) {
  try {
    Connect-PnPOnline -Url $url -Credential $tenantAdmin

    foreach ($modernPage in $nodeLevel.page) {
      $modernPagename = $modernPage.name
      $page = Get-PnPPage -Identity $modernPagename -ErrorAction SilentlyContinue           
      if ($null -ne $page) {    
        Remove-PnPPage -Identity $modernPagename -Force        
        Write-Host $modernPagename 'found. Removing the page ' -ForegroundColor Yellow
      }
            
      Add-PnPPage -Name $modernPagename -LayoutType Home -ErrorAction Stop
      $client.TrackEvent("Page created, $modernPage.name")
      Set-PnPHomePage -RootFolderRelativeUrl SitePages/$modernPagename.aspx
      Set-PnPPage -Identity $modernPagename -CommentsEnabled:$false -LayoutType Home -ErrorAction Stop
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-PageOnFailure $modernPagename
  }
}

function New-SitePage($url, $pageName, $tenantAdmin) {
  try {
    Connect-PnPOnline -Url $url -Credential $tenantAdmin

    $page = Get-PnPPage -Identity $pageName -ErrorAction SilentlyContinue           
    if ($null -ne $page) {            
      Remove-PnPPage -Identity $pageName -Force
      Write-Host $pageName 'found. Removing the page ' -ForegroundColor Yellow
    } 
    else {
      $page = Get-PnPPage -Identity 'My Tasks' -ErrorAction SilentlyContinue
      if ($null -ne $page) {            
        Remove-PnPPage -Identity 'My Tasks' -Force
        Write-Host $pageName 'found. Removing the page ' -ForegroundColor Yellow
      } 
    }

    Add-PnPPage -Name $pageName -LayoutType Home -ErrorAction Stop
    Set-PnPPage -Identity $pageName -Title 'My Tasks' -CommentsEnabled:$false -LayoutType Home -ErrorAction Stop

    Write-Host $pageName' added successfully to the site collection '$url -ForegroundColor Green
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)

    Remove-PageOnFailure $modernPagename
  }
}
#endregion

#region --cleanup Block--

function Remove-ListOnFailure($siteUrlNew, $listName) {
  try {
    Write-Host "Clean up: Delete List on failure started for: $listName"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Delete List on failure started for: $listName") 

    #Connect to PNP Online
    Connect-PnPOnline -Url $siteUrlNew -Credential $tenantAdmin -ErrorAction Stop
         
    if (Get-PnPList -Identity $listName) {
      #sharepoint online powershell remove list
      Remove-PnPList -Identity $listName -Force -ErrorAction Stop
      Write-Host "List '$listName' Deleted Successfully!"  -ForegroundColor Green
      $client.TrackEvent("List '$listName' Deleted Successfully!, Site URL, $url")
    }
    else {
      Write-Host -f Yellow "Could not find List '$listName'"
      $client.TrackEvent("Could not find List '$listName', Site URL, $url")
    }

    Write-Host "Clean up: Delete List on failure completed for: $listName"
    $client.TrackEvent("Clean up: Delete List on failure completed for: $listName")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Remove-PageOnFailure($pagename) {
  try {
    Write-Host "Clean up: Delete Page on failure started for: $pagename"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Delete Page on failure started for: $pagename") 

    Connect-PnPOnline -Url $url -Credentials $tenantAdmin -ErrorAction Stop

    $pagename = $nodeLevel.webpartSection.pagename
    $page = Get-PnPPage -Identity $pagename -ErrorAction SilentlyContinue           
        
    if ($null -ne $page) {
      Remove-PnPPage $pagename -ErrorAction Stop
    }

    Write-Host "Clean up: Delete Page on failure completed for: $pagename"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Delete Page on failure completed for: $pagename")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Remove-CustomNavigationQuickLaunchOnfailure($url, $nodeLevel) {
  try {
    Write-Host "Clean up: Remove Custom Navigation QuickLaunch on failure started for site: $url"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Remove Custom Navigation QuickLaunch on failure started for site: $url")

    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    $navigationNodeCollection = Get-PnPNavigationNode -Location QuickLaunch

    foreach ($level1 in $nodeLevel.Level1) {
      foreach ($navigationNode in $navigationNodeCollection) {
        if ($navigationNode.Title -eq $level1.nodeName) {
          Remove-PnPNavigationNode -Title $navigationNode.Title -Location QuickLaunch -Force
        }
      }    
    }
      
    Write-Host "Clean up: Remove Custom Navigation QuickLaunch on failure completed for site: $urll"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Remove Custom Navigation QuickLaunch on failure completed for site: $url")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Remove-CustomNavigationTopNavOnfailure($url, $nodeLevel) {
  try {
    Write-Host "Clean up: Remove Custom Navigation TopNav on failure started for site: $url"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Remove Custom Navigation TopNav on failure started for site: $url")

    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    $topNavigationNodeCollection = Get-PnPNavigationNode -Location TopNavigationBar

    foreach ($level1 in $nodeLevel.Level1) {
      foreach ($topNavigationNode in $topNavigationNodeCollection) {
        if ($topNavigationNode.Title -eq $level1.nodeName) {
          Remove-PnPNavigationNode -Title $topNavigationNode.Title -Location TopNavigationBar -Force
        }
      }    
    }

    Write-Host "Clean up: Remove Custom Navigation TopNav on failure completed for site: $url"  -ForegroundColor Green
    $client.TrackEvent("Clean up: Remove Custom Navigation TopNav on failure completed for site: $url")
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
  #Disconnect-PnPOnline
}

function Remove-ColumnsAndContentType($url) {   
    
  #remove all the fields from each content type from given site
  foreach ($objcolumnItem in $deletefile.Main.siteColumnsToContentTypes.columnItem) {
    Remove-FieldFromContentType $url $objcolumnItem.ColumnName $objcolumnItem.ContentTypeName
  }
    
  #remove all the content types from given site
  foreach ($objcolumnItem in $deletefile.Main.siteColumnsToContentTypes.columnItem) {
    Remove-PnPContentType $url $objcolumnItem.ContentTypeName
  }
    
  #remove all all the fields from given site
  foreach ($objcolumnItem in $deletefile.Main.siteColumnsToContentTypes.columnItem) {
    Remove-PnPField $url $objcolumnItem.ColumnName
  }
}

function Remove-FieldFromContentType($url, $sitecolumn, $contenttype) {
  try {
    #Connect to PNP Online
    Connect-PnPOnline -Url $url -Credential $tenantAdmin -ErrorAction Stop
        
    $fieldExists = Get-PNPField -identity $sitecolumn -ErrorAction SilentlyContinue
    $ContentTypeExist = Get-PnPContentType -Identity $contenttype -ErrorAction SilentlyContinue
        
    if (([bool] ($fieldExists) -eq $true) -and ([bool] ($ContentTypeExist) -eq $true)) {
      Remove-PnPFieldFromContentType -Field $sitecolumn -ContentType $contenttype
      $client.TrackEvent("Field '$sitecolumn' removed From ContentType '$contenttype', Site URL, $url")
    }        
         
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
  Disconnect-PnPOnline
}

function Remove-PnPContentType($url, $contenttype) {
  try {
    #Connect to PNP Online
    Connect-PnPOnline -Url $url -Credential $tenantAdmin

    $ContentTypeExist = Get-PnPContentType -Identity $contenttype -ErrorAction SilentlyContinue
        
    if ([bool] ($ContentTypeExist) -eq $true) {
      Remove-PnPContentType -Identity $contenttype -Force
      $client.TrackEvent("ContentType '$contenttype' removed From site, Site URL, $url")
    }
         
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
  Disconnect-PnPOnline
}

function Remove-PnPField($url, $sitecolumn) {
  try {
    #Connect to PNP Online
    Connect-PnPOnline -Url $url -Credential $tenantAdmin

    $fieldExists = Get-PNPField -identity $sitecolumn -ErrorAction SilentlyContinue
        
    if ([bool] ($fieldExists) -eq $true) {
      Remove-PnPField -Identity $sitecolumn
      $client.TrackEvent("Field '$sitecolumn' removed From site, Site URL, $url")
    }
         
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
  Disconnect-PnPOnline
}

#endregion

#region --File upload block-- 

function Add-Files($url, $nodeLevel) {
  foreach ($uploadFile in $nodeLevel.UploadFile) {
    Add-FilesToSharePoint $url $uploadFile.SourceFolder $uploadFile.DestinationFolder
  }
}

function Add-FilesToSharePoint($url, $sourcefolder, $destinationfolder) {
  try {
    Write-Host "Upload file to Sharepoint started." -foreground Green
    $client.TrackEvent("Upload file to Sharepoint started.")
    $Files = Get-ChildItem $sourcefolder
    $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
        
    foreach ($File in $Files) {
      try {      
        Add-PnPFile -Folder $destinationfolder -Path $File.FullName -Connection $connection -ErrorAction Stop
      }
      catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

#endregion

function Edit-SiteColumns($url, $node, $tenantAdmin) {
  try {
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
    $context.Credentials = $credentials
    $web = $context.Web
    $context.Load($web)
    $context.Load($web.Fields) 
    $context.Load($web.ContentTypes)
    $context.ExecuteQuery()

    foreach ($objfield in $node.changeDateOnly) {
      try {
        Write-Host "Update-SiteColumns, DateTime to Date for Content Type started for- " $objfield.ListName -foreground Green
        $client.TrackEvent("Update-SiteColumns, DateTime to Date for Content Type started for- " + $objfield.ListName)           
        Connect-PnPOnline -Url $url -Credentials $tenantAdmin
        $field = Get-PNPField -identity $objfield.ColumnInternalName -List $objfield.ListName
        [xml]$schemaXml = $field.SchemaXml
        $schemaXml.Field.Format = $objfield.DisplayFormat
        Set-PnPField -List $objfield.ListName  -Identity $objfield.ColumnInternalName -Values @{ SchemaXml = $schemaXml.OuterXml }
        Write-Host $objfield.ColumnInternalName 'updated successfully !!!' -foreground Green
            
      }
      catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow
    
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
      }
    }

    foreach ($objfield in $node.changeContentTierChoice) {
      try {
        Write-Host "Edit-SiteColumns, Choice value for Content Type started for- " $objfield.ListName -foreground Green
        $client.TrackEvent("Edit-SiteColumns, Choice value for Content Type started for- " + $objfield.ListName)           
        #Get the List
        $List = $context.Web.Lists.GetByTitle($objfield.ListName)
        $context.Load($List)
        $context.ExecuteQuery()
 
        #Get the field
        $Field = $List.Fields.GetByInternalNameOrTitle($objfield.ColumnInternalName)
        $context.Load($Field)
        $context.ExecuteQuery()
 
        #Cast the field to Choice Field
        $ChoiceField = New-Object Microsoft.SharePoint.Client.FieldMultiChoice($context, $Field.Path)
        $context.Load($ChoiceField)
        $context.ExecuteQuery()

        $Choices = $objfield.choicevalue.Split(",")
 
        #$choiceField.Choices.Clear()
        $ChoiceField.Choices = $Choices
        $ChoiceField.DefaultValue = $objfield.DefaultValue           
        $ChoiceField.UpdateAndPushChanges($True)
        $context.ExecuteQuery()
                           
      }
      catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
      }
    }

    Connect-PnPOnline -Url $url -Credentials $tenantAdmin

    #region Updating the change Title Fields
    foreach ($item in $node.changeTitle) {
      Write-Host "Changing Display Name for "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
      $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
      if ([bool]($field) -eq $true) {
        $field.Title = $item.NewTitle
        $field.Update()
        $field.Context.ExecuteQuery()
      }

    }
    #endregion

    #region Change the required value
    foreach ($item in $node.changeRequiredField) {
      try {
        Write-Host "Changing "$item.ColumnInternalName" as required column for the list: "$item.ListName -foreground Green
        $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
        if ([bool]($field) -eq $true) {
          if ($item.Required -eq "True") {
            $field.Required = $True
          }
          else {
            $field.Required = $False
          }
          $field.Update()
          $field.Context.ExecuteQuery()
        }
      }
      catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
      }
    }
    #endregion

    #region Hide columns
    foreach ($item in $node.hideColumn) {
      try {
        Write-Host "Hiding "$item.ColumnInternalName" column for the list: "$item.ListName -foreground Green
        $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
        if ([bool]($field) -eq $true) {
          $field.Hidden = $true
          $field.Update()
          $field.Context.ExecuteQuery()
        }
      }
      catch {
        #$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
        #if ([bool]($field) -eq $true) {
        #  $field.ReadOnlyField = $true
        #  $field.Update()
        #  $field.Context.ExecuteQuery()
        #}
      }
    }
    #endregion

    #region Change enforce unique value columns
    foreach ($item in $node.changeEnforceUniqueValue) {
      try {
        Write-Host "Changing the EnforceUniqueValues as True for the column "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
        $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
        if ([bool]($field) -eq $true) {
          $field.Indexed = $true
          $field.EnforceUniqueValues = $true
          $field.Update()
          $field.Context.ExecuteQuery()
        }
      }
      catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
      }
    }
    #endregion

    #region Update multi select column
    <#foreach($item in $node.updateUserSelectionMode){
            try{
                Write-Host "Updating the user selection mode for the column "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
                $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
                if([bool]($field) -eq $true){
                    $field.Required = $false
                    $field.Update()
                    $field.Context.ExecuteQuery()
                }
            }
            catch{
                
            }
        }#>
    #endregion

    #region Remove from edit form
    foreach ($item in $node.removeFromEditForm) {
      Write-Host "Removing the column "$item.ColumnInternalName" to show in new and edit form for the list: "$item.ListName -foreground Green
      $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
      if ([bool]($field) -eq $true) {
        $field.SetShowInEditForm($false)
        $field.SetShowInNewForm($false)
        $field.Update()
        $field.Context.ExecuteQuery()
      }
    }
    #endregion
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Remove-SiteColumns($url, $node, $tenantAdmin) {
  Connect-PnPOnline -Url $url -Credentials $tenantAdmin
  #region Delete Site Column
  foreach ($item in $node.column) {
    try {
      Write-Host "Remove-SiteColumns, "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
      $field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
      if ([bool]($field) -eq $true) {
        Remove-PnPField -List $item.ListName -Identity $item.ColumnInternalName -Force
        $field.Hidden = $true
        $field.Update()
        $field.Context.ExecuteQuery()
      }
            
    }
    catch {
      $ErrorMessage = $_.Exception.Message
      Write-Host $ErrorMessage -foreground Red
      $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
      $telemtryException.Exception = $_.Exception.Message  
      $client.TrackException($telemtryException)
    }
    #endregion
  }
    
}

function Edit-FieldsToDefaultView($ListName, $ViewName, $url) {
  Try {
    #Connect to PNP Online
    Connect-PnPOnline -Url $url -Credential $tenantAdmin
 
    #Get the Context
    $Context = Get-PnPContext
 
    #Get the List View from the list
    $ListView = Get-PnPView -List $ListName -Identity $ViewName -ErrorAction Stop

    $ColumnName = "LinkTitle"
 
    #Check if view doesn't have the column already
    If ($ListView.ViewFields -contains $ColumnName) {
      #Remove Column from View
      $ListView.ViewFields.Remove($ColumnName)
      $ListView.Update()
      $Context.ExecuteQuery()
      Write-Host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
    }
    else {
      Write-Host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
    }

    $ColumnName = "LinkFilename"

    #Check if view doesn't have the column already
    If ($ListView.ViewFields -contains $ColumnName) {
      #Remove Column from View
      $ListView.ViewFields.Remove($ColumnName)
      $ListView.Update()
      $Context.ExecuteQuery()
      Write-Host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
    }
    else {
      Write-Host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
    }

    $ColumnName = "Editor"

    #Check if view doesn't have the column already
    If ($ListView.ViewFields -contains $ColumnName) {
      #Remove Column from View
      $ListView.ViewFields.Remove($ColumnName)
      $ListView.Update()
      $Context.ExecuteQuery()
      Write-Host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
    }
    else {
      Write-Host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-ContentTypeToList($SiteURL, $ListName, $CTypeName, $tenantAdmin) {
  Try {
    #Setup the context
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
 
    #Get the List
    $List = $Ctx.web.Lists.GetByTitle($ListName)
    $Ctx.Load($List)
    $Ctx.ExecuteQuery()
         
    #Enable management of content type in list - if its not enabled already
    If ($List.ContentTypesEnabled -ne $True) {
      $List.ContentTypesEnabled = $True
      $List.Update()
      $Ctx.ExecuteQuery()
      Write-Host "Content Types Enabled in the List!" -f Yellow
    }
 
    #Get all existing content types of the list
    $ListContentTypes = $List.ContentTypes
    $Ctx.Load($ListContentTypes)
 
    #Get the content type to Add to list
    $ContentTypeColl = $Ctx.Web.ContentTypes
    $Ctx.Load($ContentTypeColl)
    $Ctx.ExecuteQuery()
         
    #Check if the content type exists in the site       
    $CTypeToAdd = $ContentTypeColl | Where-Object { $_.Name -eq $CTypeName }
    If ($null -eq $CTypeToAdd) {
      Write-Host "Content Type '$CTypeName' doesn't exists in  '$SiteURL'" -f Yellow
      Return
    }
 
    #Check if content type added to the list already
    $ListContentType = $ListContentTypes | Where-Object { $_.Name -eq $CTypeName }
    If ($null -ne $ListContentType ) {
      Write-Host "Content type '$CTypeName' already exists in the List!" -ForegroundColor Yellow
    }
    else {
      #Add content Type to the list or library
      $List.ContentTypes.AddExistingContentType($CTypeToAdd)
      $Ctx.ExecuteQuery()
            
      Write-Host "Content Type '$CTypeName' Added to '$ListName' Successfully!" -ForegroundColor Green
    }
  }
  Catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-FileToRootSiteCollection($url, $tenantAdmin, $destinationPath, $sourceFiles) {
  try {
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    if ($null -ne $sourceFiles) {
      foreach ($file in $sourceFiles) {
        Write-Host 'Upload started for the file' $file.Name 'for the location' $url/$destinationPath -ForegroundColor Green
        $fileUploaded = Add-PnPFile -Path $file.FullName -Folder $destinationPath
        Write-Host 'File Upload Successful !!!' $fileUploaded -ForegroundColor Green
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Get-ContentTypeId($url, $tenantAdmin, $contentTypeName, $listName) {
  try {
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    $ContentType = Get-PnPContentType -Identity $ContentTypeName -List $listName
    return $ContentType.Id
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Get-ListId($url, $tenantAdmin, $listTitle) {
  try {
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    $list = Get-PnPList -Identity $listTitle
    return $list.Id
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-CustomWebPartToPage($url, $tenantAdmin, $pageName, $webPartProperties, $webPartName, $section, $column, $order) {
  try {
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    $page = Get-PnPPage -Identity $pageName -ErrorAction Stop 
    if ($null -ne $page) {
      if (([bool]($section) -eq $true) -and ([bool]($column) -eq $true)) {
        $newWebPart = Add-PnPPageWebPart -Page $pageName -Component $webPartName -Section $section -Column $column -Order $order -WebPartProperties $webPartProperties
        Write-Host 'Webpart ' $webPartName 'added & updated successfully to the page ' $pageName -ForegroundColor Green
      }
      else {
        $newWebPart = Add-PnPPageWebPart -Page $pageName -Component $webPartName -WebPartProperties $webPartProperties
        Write-Host 'Webpart ' $webPartName 'added & updated successfully to the page ' $pageName -ForegroundColor Green
      }
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-ThemeToSiteCollection($themeName, $url, $tenantAdmin) {
  $theme = Get-SPOTheme -Name $themeName
  Connect-PnPOnline -Url $url -Credentials $tenantAdmin
  Set-PnPWebTheme -Theme $themeName -WebUrl $url
  Write-Host 'Theme' $theme 'updated for the site ' $url -ForegroundColor Green
}

function Add-ThemeAndApply($themeName, $tenantUrl, $url, $tenantAdmin, $themePalette) {
  try {
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    Add-PnPTenantTheme -Identity $themeName -Palette $themePalette -IsInverted $false -Overwrite
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    Set-PnPWebTheme -Theme $themeName -WebUrl $url
    Write-Host "Theme" $themeName "updated for the site " $url  -ForegroundColor Green
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Edit-View($url, $tenantAdmin, $viewName, $ListName) {
  try {
    #Setup the context
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
        
    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($url)
    $Ctx.Credentials = $credentials
    $List = $Ctx.Web.Lists.GetByTitle($ListName)
    $View = $List.Views.GetByTitle($viewName)
    $Ctx.ExecuteQuery()
    if ($null -ne $View) {
      #Define the CAML Query
      $Query = "<OrderBy><FieldRef Name='Modified' Ascending='FALSE'/></OrderBy>"
      #Update the View
      $View.ViewQuery = $Query
      $View.Update()
      $Ctx.ExecuteQuery()
 
      Write-Host "View '$viewName' Updated Successfully for the list '$ListName' for the site collection '$url'!" -f Green
    }
    else {
      Write-Host "View '$viewName' Doesn't exist in the List '$listName'!"  -f Yellow
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Publish-SitePage {
  param (
    $url,
    $tenantAdmin,
    $sitePageRelativeUrl
  )
    
  try {
    Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    $clientContext = Get-PnPContext
    $ListItem = Get-PnPFile -Url $sitePageRelativeUrl -AsListItem
    $targetFile = $ListItem.File
    $clientContext.Load($targetFile)
    $clientContext.ExecuteQuery()
    $targetFile.Publish("Page publish successfully!!!")
    $clientContext.ExecuteQuery()
 
    Disconnect-PnPOnline
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Add-SiteCollectionAdmins {
  param (
    $siteUrl,
    $tenantAdmin,
    $users
  )
    
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    foreach ($user in $users.user) {
      Write-host 'System is going to add ' $user.email 'as the Site Collection Admin for site :' $siteUrl -ForegroundColor Yellow
      Add-PnPSiteCollectionAdmin -Owners $user.email
      Write-host $user.email 'added successfully as the Site Collection Admin for site :' $siteUrl -ForegroundColor Green
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Set-GroupViewSettings {
  param (
    $SiteURL,
    $tenantAdmin,
    $Groups,
    $siteAlias
  )
 
  try {
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
 
    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
  
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $credentials
 
    foreach ($SPGroup in $Groups.group) {
      if ($siteAlias -eq "TASMU CMS") {
        $SPGroupName = 'Global ' + $SPGroup.Name
      }
      else {
        $SPGroupName = $siteAlias + ' ' + $SPGroup.Name
      }
      #Get the Group
      $Group = $Ctx.web.SiteGroups.GetByName($SPGroupName)
      $Ctx.Load($Group)
      $Ctx.ExecuteQuery()
 
      #Set Group settings: Who can view the membership of the group? Everyone
      $Group.OnlyAllowMembersViewMembership = $False
      $Group.Update()
      $Ctx.ExecuteQuery()
 
      Write-host "Group Settings Updated" -ForegroundColor Green
    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
 
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Get-ContentTypeForSectors() {
  param (
    $siteUrl,
    $tenantAdmin
  )
  
  Write-host "Check if Content Type Exists started for sector..." $siteUrl -ForegroundColor Green
  $filePath = $PSScriptRoot + '.\resources\Site.xml'
  [xml]$sitefile = Get-Content -Path $filePath
  $isContentTypeAvailable = $true
  Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
          
  foreach ($itemList in $sitefile.sites.sectorSPList.ListAndContentTypes) {
    $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
    if ($null -eq $ListBase) {
      $isContentTypeAvailable = $false
      Write-host $itemList.ContentTypeName "not available in" $sectorSiteUrl -ForegroundColor Yellow
    }
  }
  return $isContentTypeAvailable
}

function Add-ContentTypeToList() {
  param
  (
    $SiteURL,
    $ListName,
    $CTypeName,
    $tenantAdmin
  )
 
  Try {
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $Credentials
         
    #Get the List
    $List = $Ctx.web.Lists.GetByTitle($ListName)
    $Ctx.Load($List)
    $Ctx.ExecuteQuery()
         
    #Enable managemnt of content type in list - if its not enabled already
    If ($List.ContentTypesEnabled -ne $True) {
      $List.ContentTypesEnabled = $True
      $List.Update()
      $Ctx.ExecuteQuery()
      Write-host "Content Types Enabled in the List!" -f Yellow
    }
 
    #Get all existing content types of the list
    $ListContentTypes = $List.ContentTypes
    $Ctx.Load($ListContentTypes)
 
    #Get the content type to Add to list
    $ContentTypeColl = $Ctx.Web.ContentTypes
    $Ctx.Load($ContentTypeColl)
    $Ctx.ExecuteQuery()
         
    #Check if the content type exists in the site       
    $CTypeToAdd = $ContentTypeColl | Where-Object { $_.Name -eq $CTypeName }
    If ($Null -eq $CTypeToAdd) {
      Write-host "Content Type '$CTypeName' doesn't exists in  '$SiteURL'" -f Yellow
      Return
    }
 
    #Check if content type added to the list already
    $ListContentType = $ListContentTypes | Where-Object { $_.Name -eq $CTypeName }
    If ($Null -ne $ListContentType) {
      Write-host "Content type '$CTypeName' already exists in the List!" -ForegroundColor Yellow
    }
    else {
      #Add content Type to the list or library
      $AddedCtype = $List.ContentTypes.AddExistingContentType($CTypeToAdd)
      $Ctx.ExecuteQuery()
            
      Write-host "Content Type '$CTypeName' Added to '$ListName' Successfully!" -ForegroundColor Green
    }
  }
  Catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
  
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function AddEveryoneDefaultUserToVisitorGroup {
  param (
    $siteUrl,
    $tenantAdmin
  )
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    $Group = Get-PnPGroup -AssociatedVisitorGroup
    Add-PnPGroupMember -Group $Group -LoginName "everyone except external users"
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

Add-ComponentsForSites