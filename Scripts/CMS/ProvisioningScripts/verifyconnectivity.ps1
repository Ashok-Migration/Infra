<#
.DESCRIPTION
    This Script is for Intiating scripts execution from Azure Build Pipeline for provisioning Sectors

.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    scope                   - This is the scope for Search Configuration of the tenant which will be used for running the script, example, Subscription
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Sector sites and to provision other components as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : verifyconnectivity.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
21/01/2020  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
  $tenant,
  $sp_user,
  $sp_password
)

Write-host "Started verifying connectivity for the user " $sp_user "on " $tenant -ForegroundColor Yellow

$paramslogin = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; }
$psspologin = Resolve-Path $PSScriptRoot".\spologin.ps1"
$loginResult = .$psspologin  @paramslogin

$params = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password }

if ($null -ne $loginResult) {
  $webparams = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; fedAuth = $loginResult.FedAuth; rtFA = $loginResult.RtFa }
}

function checkUserConnectivity {
  param (
    $tenant,
    $siteRelativeName
  )
  
  try {
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr 
    $siteUrl = "https://" + $tenant + ".sharepoint.com/sites/" + $siteRelativeName
    Write-Host 'User ' $sp_user 'is trying to access the site ' + $siteUrl
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin -WarningAction Ignore
    Write-Host 'User ' $sp_user 'is able to access the site ' + $siteUrl
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
    throw "Error: $($_.Exception.Message)"
  }
}

#endregion

$count = 0

do {
  Write-host "Sleep started for 1 minute" -ForegroundColor Green
  start-sleep -s 60
  Write-host "Sleep completed for 1 minute" -ForegroundColor Green
  Write-Host 'System is trying to check whether the user ' $sp_user 'has access on contenttypehub'
  checkUserConnectivity -tenant $tenant -siteRelativeName 'contenttypehub'
  $count = $count + 1
}
until ($count -le 32)
