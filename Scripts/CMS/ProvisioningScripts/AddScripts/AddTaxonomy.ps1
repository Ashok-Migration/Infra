<#
.DESCRIPTION
    This Script is for Intiating scripts execution from Azure Build Pipeline

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
Script name : AddTaxonomy.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
15/12/2020  V1.0     Microsoft Services  Initial script creation
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

Write-host "Started" -ForegroundColor Green

Write-host $TemplateParametersFile -ForegroundColor Yellow
Write-host $tenant -ForegroundColor Yellow

Import-PackageProvider -Name "NuGet" -RequiredVersion "3.0.0.1" -Force
Install-Module SharePointPnPPowerShellOnline -Force -Verbose -Scope CurrentUser

$parentDirectory = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf('\'))
$paramslogin = @{tenant=$tenant; sp_user=$sp_user; sp_password=$sp_password;}
$psspologin = Resolve-Path $parentDirectory".\spologin.ps1"
$loginResult = .$psspologin  @paramslogin

$params = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; InstrumentationKey=$InstrumentationKey}
$paramsnewsite = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; scope=$scope; InstrumentationKey=$InstrumentationKey}
if($null -ne $loginResult){
    $webparams = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; InstrumentationKey=$InstrumentationKey; fedAuth=$loginResult.FedAuth; rtFA=$loginResult.RtFa}
}

$psfileensuretermstoreadminscript = Resolve-Path $parentDirectory".\ensuretermstoreadmin.ps1"
$psfilecreatetaxanomyscript = Resolve-Path $parentDirectory".\createtaxanomyscript.ps1"


if($null -ne $webparams){
  .$psfileensuretermstoreadminscript @webparams
}
.$psfilecreatetaxanomyscript @params
