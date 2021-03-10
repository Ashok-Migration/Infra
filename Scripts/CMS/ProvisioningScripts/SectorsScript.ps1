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
Script name : SectorsScript.ps1
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
  $InstrumentationKey
)

function Install-RequiredModules{
    Write-Host "Uninstalling PnP.PowerShell module" -ForegroundColor Green
    $pnpPowerShellModule = Get-InstalledModule -Name PnP.PowerShell -ErrorAction SilentlyContinue

    if($null -ne $pnpPowerShellModule){
        Write-Host 'PnP.PowerShell moudule found. Uninstalling ...' -ForegroundColor Green
        Uninstall-Module -Name PnP.PowerShell -AllVersions -ErrorAction SilentlyContinue -Force
    }
    else{
        Write-Host 'PnP.PowerShell moudule not found.' -ForegroundColor Yellow
    }

    Write-host "Installing SharePointPnPPowerShellOnline module" -ForegroundColor Green
    $pnpPowerShellModule = Get-InstalledModule -Name SharePointPnPPowerShellOnline -ErrorAction SilentlyContinue
    if($null -eq $pnpPowerShellModule){
        Write-host "Installing SharePointPnPPowerShellOnline module not found. Installing ..." -ForegroundColor Green
        Install-Module -Name SharePointPnPPowerShellOnline -Scope CurrentUser -Force
    }
}

#region To check if all Content type exists in Global site 

function Get-ContentTypes() {
  Write-host "Check if Content Type Exists started..." -ForegroundColor Green
  $filePath = $PSScriptRoot + '.\resources\Sectors.xml'

  [xml]$sitefile = Get-Content -Path $filePath
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr 

  $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
    
  $isContentTypeAvailable = $true
  foreach ($site in $sitefile.sites.globalhubsite.site.sectorhubsite.site) {
    $sectorsite = $site.alias    
    $sectorSiteUrl = $urlprefix + $sectorsite
    Connect-PnPOnline -Url $sectorSiteUrl -Credentials $tenantAdmin
    $connection = Get-PnPConnection
        
    foreach ($itemList in $sitefile.sites.sectorSPList.ListAndContentTypes) {
      $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
      if ($null -eq $ListBase) {
        $isContentTypeAvailable = $false
        Write-host $itemList.ContentTypeName "not available in" $sectorSiteUrl -ForegroundColor Yellow
      }
    }
    Disconnect-PnPOnline
  }
  Write-host "Check if Content Type Exists completed..." -ForegroundColor Green
  return $isContentTypeAvailable
}

#endregion

Install-RequiredModules

Write-host "Started provisioning sectors on " $tenant -ForegroundColor Yellow

$paramslogin = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; }
$psspologin = Resolve-Path $PSScriptRoot".\spologin.ps1"
$loginResult = .$psspologin  @paramslogin

$params = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey }
$paramsnewsite = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; scope = $scope; InstrumentationKey = $InstrumentationKey }
if ($null -ne $loginResult) {
  $webparams = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey; fedAuth = $loginResult.FedAuth; rtFA = $loginResult.RtFa }
}

$psfilecreatenewsectorscript = Resolve-Path $PSScriptRoot".\createnewsectorsitescript.ps1"
$psfileprovisionnewsitecollectionscript = Resolve-Path $PSScriptRoot".\provisionnewsectorsitecollectionscript.ps1"

.$psfilecreatenewsectorscript @paramsnewsite

do {
  Write-host "Sleep started for 1 minute..." -ForegroundColor Green
  start-sleep -s 60
  Write-host "Sleep completed for 1 minute..." -ForegroundColor Green
  $isExists = $true
  $isExists = Get-ContentTypes
}
until ($isExists -eq $true)

if ($isExists -eq $true) {
  Write-host "All Content types are available, Starting the provisioning script..." -ForegroundColor Green
  .$psfileprovisionnewsitecollectionscript @paramsnewsite
}