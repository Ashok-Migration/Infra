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
    $rtFA
)

function Initialize(){
    $contenttypehub = "https://$tenant.sharepoint.com/sites/contenttypehub"
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
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
    if(($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)){
        $client.Context.Cloud.RoleName = $RoleName
    }

    Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
}

Initialize
$taxonomy = Get-PnPTaxonomySession
$termStoreName = $taxonomy.TermStores[0].Name

write-host "Ensuring term store admin: " -NoNewline
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession 
$cookieCollection = New-Object System.Net.CookieCollection 
$cookie1 = New-Object System.Net.Cookie 
$cookie1.Domain = "$tenant-admin.sharepoint.com" 
$cookie1.Name = "FedAuth" 
$cookie1.Value = $fedAuth
$cookieCollection.Add($cookie1) 
$cookie2 = New-Object System.Net.Cookie 
$cookie2.Domain = "$tenant-admin.sharepoint.com" 
$cookie2.Name = "rtFa" 
$cookie2.Value = $rtFA
$cookieCollection.Add($cookie2) 
$session.Cookies.Add($cookieCollection) 

$url = "https://$tenant-admin.sharepoint.com/_layouts/15/TermStoreManager.aspx"

$response = Invoke-WebRequest -Uri $url -Method Get -WebSession $session
$form = $response.Forms[0]
$fields = $form.Fields

$body = New-Object 'system.collections.generic.dictionary[[string],[object]]'
$fields.keys | ForEach-Object{
    $key = $_
    $value = $fields[$_]
    if($key -match "ctl00_ctl00_PlaceHolderContentArea_PlaceHolderMain_sharedAppId"){
        $global:uid = $value
    }

    $body[$key] = $value
}

$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$adminPicker$hiddenSpanData'] = $sp_user
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$adminPicker$downlevelTextBox'] = $sp_user
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$sharedAppSelector'] = $uid
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$sharedAppId'] = $uid
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$selectedTaxItemType'] = '0'
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$selectedTaxItemName'] = $termStoreName
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$selectedTaxItemGuid'] = 'TaxonomyRootID'
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$selectedItemModifiedTime'] = '0'
$body['ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$otherSubmitData'] = '1033|1033;'
$body['__EVENTTARGET'] = 'ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$submitProperties'
$body['ctl00$ctl00$ScriptManager'] = 'ctl00$ctl00$ScriptManager|ctl00$ctl00$PlaceHolderContentArea$PlaceHolderMain$submitProperties'
$body['__ASYNCPOST'] = "true"
$response = Invoke-WebRequest -Uri $url -Method Post -WebSession $session -Body $body

write-host "Done" -ForegroundColor Green