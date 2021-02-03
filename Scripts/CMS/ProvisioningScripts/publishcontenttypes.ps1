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
  $InstrumentationKey,
  $fedAuth,
  $rtFA,
  $arrContentTypesToPublish
)

function Initialize() {
  $contenttypehub = "https://$tenant.sharepoint.com/sites/contenttypehub"
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

  $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
  $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
  if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
    $JsonParameters = $JsonParameters.parameters
    $RoleName = $JsonParameters.RoleName.value
  }

  Add-Type -Path (Resolve-Path $PSScriptRoot'.\Assemblies\Microsoft.ApplicationInsights.dll')
  $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
  $client.InstrumentationKey = $InstrumentationKey 
  if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
    $client.Context.Cloud.RoleName = $RoleName
  }

  Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
}

function PublishContentType($ct, $republish) {

  if ($republish -eq $true) {
    write-host "Republishing CT $($ct.Name): " -NoNewline
  }
  else {
    write-host "Publishing CT $($ct.Name): " -NoNewline    
  }
    
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession 
  $cookieCollection = New-Object System.Net.CookieCollection 
  $cookie1 = New-Object System.Net.Cookie 
  $cookie1.Domain = "$tenant.sharepoint.com" 
  $cookie1.Name = "FedAuth" 
  $cookie1.Value = $fedAuth
  $cookieCollection.Add($cookie1) 
  $cookie2 = New-Object System.Net.Cookie 
  $cookie2.Domain = "$tenant.sharepoint.com" 
  $cookie2.Name = "rtFa" 
  $cookie2.Value = $rtFA
  $cookieCollection.Add($cookie2) 
  $session.Cookies.Add($cookieCollection) 

  $ctUrl = "https://$tenant.sharepoint.com/sites/contentTypeHub/_layouts/15/managectpublishing.aspx"
  $ctId = $ct.Id # "0x01005E7A4F91FBA12643B747364A2D99D156"
  $url = "$($ctUrl)?ctype=$ctId"

  $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $session
  $form = $response.Forms[0]
  $fields = $form.Fields

  $body = New-Object 'system.collections.generic.dictionary[[string],[object]]'
  $fields.keys | ForEach-Object {
    $key = $_
    $value = $fields[$_]
    if ($key -contains "ctl00") {
      # Skip
    }
    else {
      $body[$key] = $value
    }
  }
  if ($republish -eq $false) {
    $body['ctl00$PlaceHolderMain$actionSection$RadioGroupAction'] = 'publishButton'
  }
  else {
    $body['ctl00$PlaceHolderMain$actionSection$RadioGroupAction'] = 'republishButton'
  }
    
  $body['ctl00$PlaceHolderMain$ctl00$RptControls$okButton'] = 'OK'
  $response = Invoke-WebRequest -Uri $url -Method Post -WebSession $session -Body $body
  write-host "Done" -ForegroundColor Green
}

Initialize

if ($null -ne $arrContentTypesToPublish -and $arrContentTypesToPublish.Length -gt 0) {
  foreach ($item in $arrContentTypesToPublish) {
    $ct = Get-PnPContentType -Identity $item
    PublishContentType $ct $true
  }
}
else {
    
  $CTs = Get-PnPContentType 
  $tasmuCTs = $CTs | Where-Object { $_.Group -eq "TASMU" }
  foreach ($ct in $tasmuCTs) {
    PublishContentType $ct $false
  }
}