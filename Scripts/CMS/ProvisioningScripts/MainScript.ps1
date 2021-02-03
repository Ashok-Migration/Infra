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

#region Functions
function Get-ContentTypesForMarketplace() {
  param (
    $tenantAdmin
  )
  Write-host "Check if Content Type Exists started for marketplace ..." -ForegroundColor Green
  $filePath = $PSScriptRoot + '.\resources\Site.xml'

  [xml]$sitefile = Get-Content -Path $filePath
    
  $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
  $globalhubsite = $sitefile.sites.globalhubsite.site.Alias

  $globalhubSiteUrl = $urlprefix + $globalhubsite

  Connect-PnPOnline -Url $globalhubSiteUrl -Credentials $tenantAdmin
  $connection = Get-PnPConnection

  $isContentTypeAvailable = $true
  foreach ($itemList in $sitefile.sites.globalSPList.ListAndContentTypes) {
    if ([bool]($itemList.ParentCTName) -eq $false) {
      $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
      if ($null -eq $ListBase ) {
        $isContentTypeAvailable = $false
        Write-host $itemList.ContentTypeName "not available in" $globalhubSiteUrl -ForegroundColor Yellow
      }
    }
  }
  if ($isContentTypeAvailable -eq $true) {
        
    $configsite = $sitefile.sites.Configsite.site.Alias
    $configSiteUrl = $urlprefix + $configsite

    Connect-PnPOnline -Url $configSiteUrl -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    foreach ($itemList in $sitefile.sites.ConfigurationSPList.ListAndContentTypes) {
      if ([bool]($itemList.ParentCTName) -eq $false) {
        $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
        if ($null -eq $ListBase) {
          $isContentTypeAvailable = $false
          Write-host $itemList.ContentTypeName "not available in" $configSiteUrl -ForegroundColor Yellow
        }
      }
    }
  }

  Write-host "Check if Content Type Exists completed for marketplace..." -ForegroundColor Green
  return $isContentTypeAvailable
}

function Publish-TenantApp {
  param (
    $tenantUrl,
    $rootSiteUrl,
    $tenantAdmin
  )
    
  try {
    $appsPath = $PSScriptRoot + '\resources\Apps.xml'
    [xml]$appFile = Get-Content -Path $appsPath
    foreach ($app in $appFile.Apps.app) {
      if ($app.Scope -eq 'Tenant') {
        # Add the apps to the tenant level
        $tenantApps = Get-PnPApp -Scope Tenant
        if ($null -ne $tenantApps) {
          foreach ($tenantApp in $tenantApps) {
            if ($tenantApp.Title -eq $app.Title) {
              try {
                Publish-PnPApp -Identity $tenantApp.Id -SkipFeatureDeployment 
                Write-Host 'App '$app.Title' deployed tenant-wide'  -ForegroundColor Green
              }
              catch {
                write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
              }
            }
          }
        }
      }
    }
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }
}

function Add-TenantApp {
  param (
    $tenantUrl,
    $rootSiteUrl,
    $tenantAdmin
  )

  $appFolder = $PSScriptRoot + '.\SPFxWebparts\Package'
  $allApps = Get-ChildItem $appFolder
  if ($null -ne $allApps) {
    foreach ($appToPublish in $allApps) {
      try {
        $installedApp = Add-PnPApp -Path $appToPublish.FullName -Scope Tenant -Publish
        Write-Host $installedApp.Title' successfully added and published at the tenant level' -ForegroundColor Green
      }
      catch {
        write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
      }
    }
  }
}

function Get-TenantAppCatalog {
  param (
    $tenantUrl,
    $tenantAdmin
  )
    
  Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
  $tenantAppCatalogUrl = Get-PnPTenantAppCatalogUrl
  if ([bool]($tenantAppCatalogUrl) -eq $false) {
    throw "Tenant App catalog is not configured. Please configure the Tenant App Catalog before proceeding. Admin Center URL : " + $tenantUrl
  }
}

function ProvisionComponent {
  try {
    if ($null -ne $webparams) {
      .$psfileensuretermstoreadminscript @webparams
    }
    .$psfilecreatetaxanomyscript @params
    .$psfilecreatesitecolumnscript @params
    .$psfilecreatecontenttypescript @params
    if ($null -ne $webparams) {
      .$psfilepublishcontenttypescript @webparams
    }
    .$psfilecreatenewsitescript @paramsnewsite
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }
}

function Get-ContentTypeForSectors() {
  param (
    $tenantAdmin
  )

  Write-host "Check if Content Type Exists started for sectors..." -ForegroundColor Green
  $filePath = $PSScriptRoot + '.\resources\Site.xml'

  [xml]$sitefile = Get-Content -Path $filePath

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
  Write-host "Check if Content Type Exists completed for sectors..." -ForegroundColor Green
  return $isContentTypeAvailable
}

function Enable-PublicCDNAndSiteCollectionCustomization {
  param (
    $tenantUrl,
    $tenantAdmin
  )

  try {
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    $isEnabled = Get-PnPTenantCdnEnabled -CdnType Public
    if ([string] ($isEnabled.Value) -eq "False") {
      Set-PnPTenantCdnEnabled -CdnType Public -Enable $true
    }

    Connect-PnPOnline -Url $rootSiteColUrl -Credentials $tenantAdmin
    Set-PnPSite -Identity $rootSiteColUrl -NoScriptSite:$false
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }

}
#endregion

Write-host "Main Script Started" -ForegroundColor Green
Write-host $TemplateParametersFile -ForegroundColor Yellow
Write-host $tenant -ForegroundColor Yellow

$tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
$rootSiteColUrl = "https://" + $tenant + ".sharepoint.com/"
$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr 

$paramslogin = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; }
$psspologin = Resolve-Path $PSScriptRoot".\spologin.ps1"
$loginResult = .$psspologin  @paramslogin

$params = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey }
$paramsnewsite = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; scope = $scope; InstrumentationKey = $InstrumentationKey }
if ($null -ne $loginResult) {
  $webparams = @{tenant = $tenant; TemplateParametersFile = $TemplateParametersFile; sp_user = $sp_user; sp_password = $sp_password; InstrumentationKey = $InstrumentationKey; fedAuth = $loginResult.FedAuth; rtFA = $loginResult.RtFa }
}

#region Check if the Tenant App Catalog is available
Get-TenantAppCatalog -tenantUrl $tenantUrl -tenantAdmin $tenantAdmin
#endregion

#region Get file references
$psfileensuretermstoreadminscript = Resolve-Path $PSScriptRoot".\ensuretermstoreadmin.ps1"
$psfilecreatetaxanomyscript = Resolve-Path $PSScriptRoot".\createtaxanomyscript.ps1"
$psfilecreatesitecolumnscript = Resolve-Path $PSScriptRoot".\createsitecolumnscript.ps1"
$psfilecreatecontenttypescript = Resolve-Path $PSScriptRoot".\createcontenttypescript.ps1"
$psfilepublishcontenttypescript = Resolve-Path $PSScriptRoot".\publishcontenttypes.ps1"
$psfilecreatenewsitescript = Resolve-Path $PSScriptRoot".\createnewsitescript.ps1"
$psfileprovisionnewsitecollectionscript = Resolve-Path $PSScriptRoot".\provisionnewsitecollectionscript.ps1"
#endregion

ProvisionComponent

do {
  Write-host "Sleep started for 1 minute..." -ForegroundColor Green
  start-sleep -s 60
  Write-host "Sleep completed for 1 minute..." -ForegroundColor Green
  $isContentTypeExistsGlobal = $True
  $isContentTypeExistsGlobal = Get-ContentTypesForMarketplace -tenantAdmin $tenantAdmin
}
until ($isContentTypeExistsGlobal -eq $True)

if ($isContentTypeExistsGlobal -eq $True) {
  Write-host "All Content types are available, Starting the provisioning script..." -ForegroundColor Green
    
  Enable-PublicCDNAndSiteCollectionCustomization -tenantAdmin $tenantAdmin -tenantUrl $tenantUrl
  Add-TenantApp -tenantUrl $tenantUrl -rootSiteUrl $rootSiteColUrl -tenantAdmin $tenantAdmin
  Publish-TenantApp -tenantUrl $tenantUrl -rootSiteUrl $rootSiteColUrl -tenantAdmin $tenantAdmin

  .$psfileprovisionnewsitecollectionscript @paramsnewsite
}