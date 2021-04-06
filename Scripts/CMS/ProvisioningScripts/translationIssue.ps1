<#
.DESCRIPTION
    This Script is for updating the list column name to some other value and then reverting to its original value
    to resolve the translation file issue. 

    XML files it will look for inputs are
    SchemaToTest.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Create/Update the Schema Test Result list in the cms-global site collection with list/library validations

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : translationIssue.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
31/03/2021  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
  $tenant,
  $sp_user,
  $sp_password,
  $InstrumentationKey
)

$filePath = $PSScriptRoot + '\resources\SchemaToTest.xml'
[xml]$schemaFile = Get-Content -Path $filePath

$tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
$rootSCUrl = "https://" + $tenant + ".sharepoint.com"

$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
$client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
$client.InstrumentationKey = $InstrumentationKey 


function Edit-ColumnsTitle {
  param (
    $lists,
    $siteUrl,
    $tenantAdmin
  )
  try {
    foreach ($list in $lists) {
      Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
      $listObj = Get-PnPList -Identity $list.ListName
      if ($null -ne $listObj) {
        Write-Host "Started updating the list columns for the list $($listObj.Title) with URL $($rootSCUrl + $listObj.DefaultViewUrl)" -ForegroundColor Yellow

        #Get All Columns from List
        foreach ($column in $list.columnItem) {
          try {
            $field = Get-PnPField -List $listObj.Title -Identity $column.ColumnName
            if ($null -ne $field) {
              $originalTitle = $field.Title
              $newTitle = $originalTitle + "_Updated"
              Set-PnPField -List $listObj.Title -Identity $field.InternalName -Values @{Title = $newTitle }
              Write-Host "Temporary title updated for the field $($field.InternalName) to $($newTitle)" -ForegroundColor Magenta

              Set-PnPField -List $listObj.Title -Identity $field.InternalName -Values @{Title = $originalTitle }
              Write-Host "Title updated for the field $($field.InternalName) to its original value $($originalTitle)" -ForegroundColor Green
            }
            else {
              Write-Host $column.ColumnName "doesn't exists in the list with Title:" $list.ListName "& URL :"$listFullUrl -ForegroundColor Red
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
      else {
        Write-Host $list.ListName "doesn't exists at site" $siteUrl -ForegroundColor Red
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

function Get-SCs {
  param (
    $schemaFile
  )
  
  try {
    Write-Host "Starting the list column updation script for the teanant $($tenant)" -ForegroundColor Green
    foreach ($globalconfigsite in $schemaFile.schema.Configsite.site) {
      $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
      $globalconfigSiteUrl = $urlprefix + $globalconfigsite.Alias
      Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
      $siteExits = Get-PnPTenantSite -Url $globalconfigSiteUrl -ErrorAction SilentlyContinue
    
      if ([bool] ($siteExits) -eq $true) {
        Edit-ColumnsTitle -siteUrl $globalconfigSiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.global.ListAndContentTypes
      }
    }
      
    foreach ($globalhubsite in $schemaFile.schema.globalhubsite.site) {
      $globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
      Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
      $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
      if ([bool] ($siteExits) -eq $true) {
        Edit-ColumnsTitle -siteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.marketplace.ListAndContentTypes
      }
                   
      foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {
        $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
        Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
        $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
        if ([bool] ($siteExits) -eq $true) {
          Edit-ColumnsTitle -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.sector.ListAndContentTypes
        } 

        foreach ($entitySite in $globalhubsite.sectorhubsite.site.orgassociatedsite) {
          $entitySiteUrl = $urlprefix + $entitySite.Alias
          Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
          $siteExits = Get-PnPTenantSite -Url $entitySiteUrl -ErrorAction SilentlyContinue
          if ([bool] ($siteExits) -eq $true) {
            Edit-ColumnsTitle -siteUrl $entitySiteUrl -tenantAdmin $tenantAdmin -lists $schemaFile.schema.entity.ListAndContentTypes
          } 
        }
      }
    }
  }
  catch {
    write-host -f Red "Error !" $_.Exception.Message

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }

  Write-Host 'Schema validation script ended' -ForegroundColor Green
}

Get-SCs -schemaFile $schemaFile