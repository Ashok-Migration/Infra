<#
.DESCRIPTION
    This Script is for Creating all Site Columns as per the input from the XML file
    XML files it will look for inputs are
    SiteColumns.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Site Columns as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : createsitecolumnsscript.ps1
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
  $tenant,
  $TemplateParametersFile,
  $sp_user,
  $sp_password,
  $scope,
  $InstrumentationKey,
  $contenttypehub
)

function Add-Fields() {
  $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
 
  # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
  $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
  if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
    $JsonParameters = $JsonParameters.parameters
  }

  $RoleName = $JsonParameters.RoleName.value

  if ([bool]($contenttypehub) -eq $false) {
    $contenttypehub = "https://" + $tenant + ".sharepoint.com/sites/contentTypeHub"
  }

  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')

  $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
  $client.InstrumentationKey = $InstrumentationKey 
  if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
    $client.Context.Cloud.RoleName = $RoleName
  }

  $filePath = $PSScriptRoot + '\resources\SiteColumns.xml'

  [xml]$sitefile = Get-Content -Path $filePath

  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

  Add-SiteColumns $spContext
  Edit-Fields

  Write-host "Completed" -ForegroundColor Green

}

function Get-FieldsToImport($xmlTermsPath) {
  [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

  try {
    $xDoc = [System.Xml.Linq.XDocument]::Load($xmlTermsPath, [System.Xml.Linq.LoadOptions]::None)
    return $xDoc
  }
  catch {
    Write-Host "Unable to read taxonomy xml. Exception:$_.Exception.Message" -ForegroundColor Red
  }
}

#region --Site Column Creation
function Add-SiteColumns($spContext) {
    
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

  #Connect with the tenant admin credentials to the tenant
  Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
  $connection = Get-PnPConnection
 
  try {
    foreach ($fieldNode in $sitefile.SiteFields.Field) {        
      $columnName = $fieldNode.ColumnName
      $columnTitle = $fieldNode.ColumnTitle
      $groupName = $fieldNode.GroupName
      $columnType = $fieldNode.ColumnType
      $columnFormatting = $fieldNode.ColumnFormatting
      $description = $fieldNode.Description
      $message = $fieldNode.Message
      $validation = $fieldNode.Validation

      $columnChoices = ''

      if ($columnType -eq 'Choice') {
        $ChoiceOptions = ""
        $Choices = $fieldNode.choicevalue.Split(",")
        foreach ($Choice in $Choices) {
          $ChoiceOptions = $ChoiceOptions + "<CHOICE>$Choice</CHOICE>"
        }
      }

      $required = $fieldNode.Required
      $format = $fieldNode.Format
      $TermSetPath = $fieldNode.TermSetPath
      $isSingleSelect = $fieldNode.isSingleSelect
      $showInNewEditForm = $fieldNode.showInNewEditForm
      $isRichText = $fieldNode.isRichText
      $defaultValue = $fieldNode.DefaultValue
      $enforceUniqueValues = $fieldNode.EnforceUniqueValues
      $indexed = $fieldNode.Indexed
      $fillInChoice = $fieldNode.FillInChoice

      if ($columnName -ne '') {
        Add-Field $tenantAdmin $contenttypehub $columnTitle $columnName $groupName $columnType $ChoiceOptions $required $format $TermSetPath $showInNewEditForm $isSingleSelect $isRichText $defaultValue $enforceUniqueValues $indexed $columnFormatting $message $description $validation $fillInChoice
      }        

    }
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Yellow
        
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }

  Disconnect-PnPOnline
}

function Add-Field($tenantAdmin, $contenttypehub, $ColumnTitle, $ColumnName, $GroupName, $columnType, $ChoiceOptions, $Required, $Format, $TermSetPath, $showInNewEditForm, $isSingleSelect, $isRichText, $defaultValue, $enforceUniqueValues, $indexed, $columnFormatting, $message, $description, $validation, $fillInChoice) {
  Try {

    Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    if ([string]::IsNullOrWhiteSpace($enforceUniqueValues)) {
      $enforceUniqueValues = 'FALSE'  
    }

    if ([string]::IsNullOrWhiteSpace($indexed)) {
      $indexed = 'FALSE'  
    }

    $fieldExists = Get-PNPField -identity $ColumnName -ErrorAction SilentlyContinue
    #Check for existence of Institution Name site column
    if ([bool] ($fieldExists) -eq $false) {
      Write-Host "Site column not found ,so creating a new site column- $ColumnName....."
      $client.TrackEvent("Site column not found ,so creating a new site column- $ColumnName.....")

      if ($ColumnType -eq "Choice") {
        # Create new site column if site column does not exist                
        $Id = [GUID]::NewGuid()
        if ($null -eq $showInNewEditForm) {
          $showInNewEditForm = "TRUE"
        } 
        $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$columnType'
                DisplayName='$ColumnTitle'
                Required='$Required'
                Indexed='$indexed'
                Format='$Format'
                Group='$GroupName'                
                ShowInEditForm='$showInNewEditForm'
                ShowInNewForm='$showInNewEditForm'
                ID='$Id'
                Name='$ColumnName'>
                <Default>$defaultValue</Default> <CHOICES>$ChoiceOptions</CHOICES>
                </Field>"
      }
      elseif ($ColumnType -eq "Taxonomy") {
        if ($isSingleSelect -eq $True) {
          $addNewField = Add-PnPTaxonomyField -DisplayName $ColumnTitle -InternalName $ColumnName -TermSetPath $TermSetPath -Group $GroupName -Connection $connection
        }
        else {
          $addNewField = Add-PnPTaxonomyField -DisplayName $ColumnTitle -InternalName $ColumnName -TermSetPath $TermSetPath -Group $GroupName -MultiValue -Connection $connection
        }

        if ($fillInChoice -eq $True) {
          Set-PnPField -Identity $ColumnName -Values @{Open = $true; CreateValuesInEditForm = $true }
        }
      }
      elseif ($columnType -eq "Note") {
        if ($isRichText -eq $True) {
          $Id = [GUID]::NewGuid() 
          $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
                    DisplayName='$ColumnTitle' 
                    Required='$Required' 
                    EnforceUniqueValues='$enforceUniqueValues' 
                    Indexed='$indexed' Format='$Format' 
                    Group='$GroupName' 
                    FriendlyDisplayFormat='Disabled' 
                    StaticName='$ColumnName'
                    ID='$Id' 
                    UnlimitedLengthInDocumentLibrary ='TRUE'
                    Name='$ColumnName'
                    RichText='TRUE'
                    RichTextMode='FullHtml'
                    ShowInEditForm='$showInNewEditForm'
                    ShowInNewForm='$showInNewEditForm'>
                    </Field>"
        }
        else {
          $Id = [GUID]::NewGuid() 
          $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
                    DisplayName='$ColumnTitle' 
                    Required='$Required' 
                    EnforceUniqueValues='$enforceUniqueValues' 
                    Indexed='$indexed' Format='$Format' 
                    Group='$GroupName' 
                    FriendlyDisplayFormat='Disabled' 
                    StaticName='$ColumnName'
                    ID='$Id' 
                    UnlimitedLengthInDocumentLibrary ='TRUE'
                    Name='$ColumnName'
                    ShowInEditForm='$showInNewEditForm'
                    ShowInNewForm='$showInNewEditForm'>
                    </Field>"
        }
      } 
      elseif ($columnType -eq "Number") {
        $Id = [GUID]::NewGuid() 
        #$fieldXml = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Name='$ColumnName' ID='{$Id}' Decimals='0' Min='0' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Group='$GroupName'></Field>"
        if ($null -ne $validation) {
          $validation = $validation.Replace('>', '&gt;').Replace('<', '&lt;')
        }
        $fieldXml = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Name='$ColumnName' ID='{$Id}' Decimals='0' Min='0' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Group='$GroupName' Description='$description'><Validation Message='$message'>$validation</Validation></Field>"

        $addNewField = Add-PnPFieldFromXml -Connection $connection $fieldXml
      }
      elseif ($columnType -eq "Boolean") {
        $Id = [GUID]::NewGuid()
        if ($null -eq $showInNewEditForm) {
          $showInNewEditForm = "TRUE"
        }
        $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
                DisplayName='$ColumnTitle' 
                Required='$Required' 
                EnforceUniqueValues='$enforceUniqueValues' 
                Indexed='$indexed' 
                Group='$GroupName' 
                FriendlyDisplayFormat='Disabled' 
                StaticName='$ColumnName'
                ShowInEditForm='$showInNewEditForm'
                ShowInNewForm='$showInNewEditForm'
                ID='$Id' 
                Name='$ColumnName'>
                <Default>$defaultValue</Default>
                </Field>"
      }
      elseif ($columnType -eq "UserMulti") {
        $Id = [GUID]::NewGuid()
        if ($null -eq $showInNewEditForm) {
          $showInNewEditForm = "TRUE"
        }
        $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
                DisplayName='$ColumnTitle' 
                Required='$Required' 
                EnforceUniqueValues='$enforceUniqueValues' 
                Indexed='$indexed' 
                Group='$GroupName' 
                FriendlyDisplayFormat='Disabled' 
                StaticName='$ColumnName'
                ShowInEditForm='$showInNewEditForm'
                ShowInNewForm='$showInNewEditForm'
                UserSelectionMode='PeopleAndGroups' 
                Mult='TRUE'
                ID='$Id' 
                Name='$ColumnName'>
                <Default>$defaultValue</Default>
                </Field>"
      }
      else {
        $Id = [GUID]::NewGuid()
        $fieldXML = ""
        if ($null -eq $showInNewEditForm) {
          $showInNewEditForm = "TRUE"
        }
        if ($null -eq $defaultValue) {
                
          $fieldXML = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Format='$Format' Group='$GroupName' FriendlyDisplayFormat='Disabled' StaticName='$ColumnName' ShowInEditForm='$showInNewEditForm' ShowInNewForm='$showInNewEditForm' ID='$Id' Name='$ColumnName'></Field>"

        }
        else {
          $fieldXML = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Format='$Format' Group='$GroupName' FriendlyDisplayFormat='Disabled' StaticName='$ColumnName' ShowInEditForm='$showInNewEditForm' ShowInNewForm='$showInNewEditForm' ID='$Id' Name='$ColumnName'><Default>$defaultValue</Default></Field>"
        }
        $addNewField = Add-PnPFieldFromXml -Connection $connection $fieldXML -ErrorAction Stop
      }
            
      $getField = Get-PNPField -identity $ColumnName -ErrorAction SilentlyContinue

      if ($null -ne $columnFormatting) {
        $getField | Set-PnPField -Values @{CustomFormatter = $columnFormatting }
      }
    }
    else {
      Write-Host "$ColumnTitle already exists"
      $client.TrackEvent("$ColumnTitle already exists")
    } 
  }
  Catch {

    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Yellow
        
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  } 
}

function Set-TaxonomySiteColumns($ColumnName, $connection) {

  $field = Get-PnPField -identity $ColumnName -ErrorAction SilentlyContinue
  if ($field -ne $null) {
    [xml]$schemaXml = $field.SchemaXml

    if ($schemaXml.Field.HasAttribute('Mult') -eq $false) {
      Write-Host "Updating $ColumnName to multi selection..."
      $schemaXml.Field.Type = 'TaxonomyFieldTypeMulti'
      $schemaXml.Field.SetAttribute("Mult", 'TRUE')            
      $updateField = Set-PnPField -Identity $ColumnName -Values @{ SchemaXml = $schemaXml.OuterXml } -Connection $connection
    }
  }
}

function Edit-Fields {

  try {
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($contenttypehub)
    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
    $context.Credentials = $credentials
    $web = $context.Web
    $context.Load($web)
    $context.Load($web.Fields) 
    $context.Load($web.ContentTypes)
    $context.ExecuteQuery()

    foreach ($objfield in $sitefile.SiteFields.updateSiteColumns.renameFieldDisplayName) {
            
      $ctType = $web.ContentTypes | Where-Object { $_.Name -eq $objfield.ContentTypeName }
      $context.Load($ctType.FieldLinks)
      $context.ExecuteQuery()
      $field = $ctType.FieldLinks | Where-Object { $_.Name -eq $objfield.ColumnInternalName }
      if ($null -ne $field) {
        $field.DisplayName = $objfield.ColumnNewTitle
        $ctType.Update($true)
        $context.ExecuteQuery()
      }               
    }

  }
  catch {
    Write-Host $_.Exception.Message -ForegroundColor Yellow
  }
}

Add-Fields