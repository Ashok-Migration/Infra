<#
.DESCRIPTION
    This Script is for Creating all Site Content Types, and accociating Site columns to Respective Content type as per the input from the XML file
    XML files it will look for inputs are
    ContentType.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Site Content Types and accociates Site columns as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : createcontenttypescript.ps1
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
  $InstrumentationKey
)

#Import-Module Microsoft.Online.SharePoint.PowerShell
function Add-ContentTypesAndFields() {
  $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
 
  # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
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

  $siteContentTypePath = $PSScriptRoot + '\resources\ContentType.xml'
  $scXML = Get-FieldsToImport $siteContentTypePath

  Read-FileAndCreateContentTypes $scXML

  Write-host "Content Types creation and field addition completed successfully" -ForegroundColor Green

}

function Get-FieldsToImport($xmlTermsPath) {
  [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

  try {
    $xDoc = [System.Xml.Linq.XDocument]::Load($xmlTermsPath, [System.Xml.Linq.LoadOptions]::None)
    return $xDoc
  }
  catch {
    Write-Host "Unable to read ContentTypeCTH xml. Exception:$_.Exception.Message" -ForegroundColor Red
  }
}
function Read-FileAndCreateContentTypes($scXML) {
  $contenttypehub = "https://" + $tenant + ".sharepoint.com/sites/contentTypeHub"
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    
  # Connect with the tenant admin credentials to the tenant
  Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
  $connection = Get-PnPConnection
    
  #Add Site collection Admin
  Add-PnPSiteCollectionAdmin -Owners $sp_user
 
  #create all the content Types
  foreach ($contentItem in $scXML.Descendants("contentItem")) {
    $contentTypeName = Get-AttributeValue $contentItem "ContentTypeName"
    $parentCTName = Get-AttributeValue $contentItem "ParentCTName"
    $groupName = Get-AttributeValue $contentItem "GroupName"
 
    if ($contentTypeName -ne '') {
      Add-ContentType $tenantAdmin $contenttypehub $contentTypeName $contentTypeName $parentCTName $groupName $connection
    }
  }
 
  #add columns to the content Types
  foreach ($columnItem in $scXML.Descendants("columnItem")) {
    $contentTypeName = Get-AttributeValue $columnItem "ContentTypeName"
    $columnName = Get-AttributeValue $columnItem "ColumnName"
    $required = Get-AttributeValue $columnItem "Required"
    if ($contentTypeName -ne '') {
      Add-FieldToContentType $tenantAdmin $contenttypehub $contentTypeName $columnName $connection $required
    }
  }
  #remove columns from content types
  foreach ($columnRemovable in $scXML.Descendants("columnRemovable")) {
        
    $contentTypeName = Get-AttributeValue $columnRemovable "ContentTypeName"
    $columnName = Get-AttributeValue $columnRemovable "ColumnName"
        
    if ($contentTypeName -ne '') {
      Remove-FieldFromContentType $tenantAdmin $contenttypehub $contentTypeName $columnName $connection
    }
  }
 
  Disconnect-PnPOnline
}

function Add-ContentType($tenantAdmin, $contenttypehub, $ContentTypeName, $ContentTypeDesc, $ParentCTName, $GroupName, $connection) {
  try {
    $ContentTypeExist = Get-PnPContentType -Identity $ContentTypeName -ErrorAction Stop -Connection $connection
    #Check for existence of  site content type
    if ([bool]($ContentTypeExist) -eq $false) {
      Write-Host "Content Type not found ,so creating a new contenttype- $ContentTypeName....."
      $client.TrackEvent("Content Type not found ,so creating a new contenttype- $ContentTypeName.....")
      $ParentCT = Get-PnPContentType -Identity $ParentCTName -Connection $connection
      Add-PnPContentType -Name $ContentTypeName -Description $ContentTypeDesc -Group $GroupName -ParentContentType $ParentCT -ErrorAction Stop -Connection $connection
    }
    else {
      Write-Host "$ContentTypeName already exists"
      $client.TrackEvent("$ContentTypeName already exists")
    }  
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Yellow
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  } 
}

function Add-FieldToContentType($tenantAdmin, $contenttypehub, $ContentTypeName, $ColumnName, $connection, $required) {
  try {
    Write-Host "Column not added, so adding column - $ColumnName to contenttype - $ContentTypeName....."
    $client.TrackEvent("Column not added, so adding column - $ColumnName to contenttype - $ContentTypeName.....")

    if ($ContentTypeName -eq "TASMU Translation Tasks" -or $ContentTypeName -eq "TASMU Approval Tasks") {
      if ($ColumnName -eq "cmsAssignedToUser") {
        Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -Hidden -ErrorAction Stop -Connection $connection
      }
      elseif ($required -eq "False") {
        Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection
      }
      else {
        Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection -Required
      } 
    }
    else {
      if ($required -eq "False") {
        Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection
      }
      else {
        Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection -Required
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
}

function Remove-FieldFromContentType($tenantAdmin, $contenttypehub, $ContentTypeName, $ColumnName, $connection, $required) {
  try {
    Write-Host "Removing additional column - $ColumnName from content type - $ContentTypeName "
    $client.TrackEvent("Removing additional column - $ColumnName from content type - $ContentTypeName ")

    Remove-PnPFieldFromContentType -Field $ColumnName -ContentType $ContentTypeName -Connection $connection
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Yellow
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  } 
}

function Get-AttributeValue($node, $attributeName) {

  $attributeValue = ''
  if ($null -ne $node.Attribute($attributeName)) {
    $attributeValue = $node.Attributes($attributeName).Value
  }

  return $attributeValue

}

function Get-BooleanAttributeValue($node, $attributeName) {

  $booleanAttributeValue = $false
  $attributeValue = Get-AttributeValue $node $attributeName
  if ($attributeValue -ne '') {
    $booleanAttributeValue = [bool]::Parse($attributeValue)
  }

  return $booleanAttributeValue

}

Add-ContentTypesAndFields