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
Script name : MainScript.ps1
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

Write-host "Started" -ForegroundColor Green

Write-host $TemplateParametersFile -ForegroundColor Yellow
Write-host $tenant -ForegroundColor Yellow

Import-PackageProvider -Name "NuGet" -RequiredVersion "3.0.0.1" -Force
Install-Module SharePointPnPPowerShellOnline -Force -Verbose -Scope CurrentUser

$paramslogin = @{tenant=$tenant; sp_user=$sp_user; sp_password=$sp_password;}
$psspologin = Resolve-Path $PSScriptRoot".\spologin.ps1"
$loginResult = .$psspologin  @paramslogin

$params = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; InstrumentationKey=$InstrumentationKey}
$paramsnewsite = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; scope=$scope; InstrumentationKey=$InstrumentationKey}
if($null -ne $loginResult){
    $webparams = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; InstrumentationKey=$InstrumentationKey; fedAuth=$loginResult.FedAuth; rtFA=$loginResult.RtFa}
}

$psfileensuretermstoreadminscript = Resolve-Path $PSScriptRoot".\ensuretermstoreadmin.ps1"
$psfilecreatetaxanomyscript = Resolve-Path $PSScriptRoot".\createtaxanomyscript.ps1"
$psfilecreatesitecolumnscript = Resolve-Path $PSScriptRoot".\createsitecolumnscript.ps1"
$psfilecreatecontenttypescript = Resolve-Path $PSScriptRoot".\createcontenttypescript.ps1"
$psfilepublishcontenttypescript = Resolve-Path $PSScriptRoot".\publishcontenttypes.ps1"
$psfilecreatenewsitescript = Resolve-Path $PSScriptRoot".\createnewsitescript.ps1"
$psfileprovisionnewsitecollectionscript = Resolve-Path $PSScriptRoot".\provisionnewsitecollectionscript.ps1"

if($null -ne $webparams){
    .$psfileensuretermstoreadminscript @webparams
}
.$psfilecreatetaxanomyscript @params
 .$psfilecreatesitecolumnscript @params
  .$psfilecreatecontenttypescript @params
  if($null -ne $webparams){
     .$psfilepublishcontenttypescript @webparams
  }
 .$psfilecreatenewsitescript @paramsnewsite

#region To check if all Content type exists in Global site 

function checkContentTypeExists()
{
    Write-host "Check if Content Type Exists started..." -ForegroundColor Green
    $filePath = $PSScriptRoot + '.\resources\Site.xml'

    [xml]$sitefile = Get-Content -Path $filePath
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr 


    $urlprefix = "https://"+$tenant+".sharepoint.com/sites/"
    $globalhubsite=$sitefile.sites.globalhubsite.site.Alias

    $globalhubSiteUrl = $urlprefix + $globalhubsite

    Connect-PnPOnline -Url $globalhubSiteUrl -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    $isContentTypeAvailable=$true
    foreach ($itemList in $sitefile.sites.globalSPList.ListAndContentTypes) {
        $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
        if($ListBase -eq $null)
        {
            $isContentTypeAvailable=$false
            Write-host $itemList.ContentTypeName "not available in" $globalhubSiteUrl -ForegroundColor Yellow
        }
    }
    if($isContentTypeAvailable -eq $true){
        
        $configsite=$sitefile.sites.Configsite.site.Alias
        $configSiteUrl = $urlprefix + $configsite

        Connect-PnPOnline -Url $configSiteUrl -Credentials $tenantAdmin
        $connection = Get-PnPConnection

        foreach ($itemList in $sitefile.sites.ConfigurationSPList.ListAndContentTypes) {
            $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
            if($ListBase -eq $null)
            {
                $isContentTypeAvailable=$false
                Write-host $itemList.ContentTypeName "not available in" $configSiteUrl -ForegroundColor Yellow
            }
        }
    }

    Write-host "Check if Content Type Exists completed..." -ForegroundColor Green
    return $isContentTypeAvailable
}

#endregion

do
{
    Write-host "Sleep started for 1 minute..." -ForegroundColor Green
    start-sleep -s 60
    Write-host "Sleep completed for 1 minute..." -ForegroundColor Green
    $isExists= $true
    $isExists= checkContentTypeExists
}
until ($isExists -eq $true)

if($isExists -eq $true)
{
     Write-host "All Content types are available, Starting the provisioning script..." -ForegroundColor Green
     #add the custom script command 
     $tenantUrl="https://"+$tenant+"-admin.sharepoint.com/"
     $rootSiteColUrl = "https://"+$tenant+".sharepoint.com/"

     $secstr = New-Object -TypeName System.Security.SecureString
     $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
     $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr 
     Connect-SPOService -url $tenantUrl -credential $tenantAdmin
     $isEnabled = Get-SPOTenantCdnEnabled -CdnType Public
     if([string] ($isEnabled.Value) -eq "False"){
          Set-SPOTenantCdnEnabled -CdnType Public -Confirm:$false
     }

     Set-SPOsite $rootSiteColUrl -DenyAddAndCustomizePages 0
     .$psfileprovisionnewsitecollectionscript @paramsnewsite
}