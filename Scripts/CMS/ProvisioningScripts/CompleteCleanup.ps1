<#
.DESCRIPTION
	This Script is for Deleting all Site collections, Site content types, Site columns & taxanomy columns as per the input from the XML file
	XML files it will look for inputs are
	Cleanup.xml, ContentType.xml, SiteColumns.xml, Taxonomy.xml
.INPUTS
	tenant                  - This is the name of the tenant that you are running the Clean up script
	TemplateParametersFile  - This should be the json file having RoleName for Logging
	sp_user                 - This is the user email ID of the tenant which will be used for running the script
	sp_password             - This is the user password of the tenant which will be used for running the script
	InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
	Delete all Site collections, Site content types, Site columns & taxanomy columns as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : CompleteCleanup.ps1
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
  $InstrumentationKey
)

function Complete-Cleanup() {
  Write-Host 'Cleanup started on tenant '$tenant -ForegroundColor Yellow
  $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
  $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
  if ($null -ne ($JsonParameters | Get-Member -Type NoteProperty 'parameters')) {
    $JsonParameters = $JsonParameters.parameters
  }

  $paramslogin = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; }
  $psspologin = Resolve-Path $PSScriptRoot".\spologin.ps1"
  $loginResult = .$psspologin  @paramslogin
  
  $RoleName = $JsonParameters.RoleName.value
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
  $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
  $client.InstrumentationKey = $InstrumentationKey 
  $client.Context.Cloud.RoleName = $RoleName

  $filePath = $PSScriptRoot + '\resources\Cleanup.xml'
  [xml]$sitefile = Get-Content -Path $filePath

  $siteContentTypePath = $PSScriptRoot + '\resources\ContentType.xml'
  [xml]$scXML = Get-Content -Path $siteContentTypePath

  $siteColumnfilePath = $PSScriptRoot + '\resources\SiteColumns.xml'
  [xml]$siteColumnfilePathfile = Get-Content -Path $siteColumnfilePath

  $termsPath = $PSScriptRoot + '\resources\Taxonomy.xml'
  [xml]$termsfile = Get-Content -Path $termsPath

  $serchConfigPath = $PSScriptRoot + '\resources\SearchConfiguration.xml'
  $tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
  $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
  $contenttypehub = "https://" + $tenant + ".sharepoint.com/sites/contentTypeHub"

  CompleteCleanup $sitefile $scXML $siteColumnfilePathfile $termsfile

  Write-host "Cleanup completed successfully" -ForegroundColor Green
  $client.TrackEvent("Completed.")
}

<#
.SYNOPSIS
	This function is used for calling all the methods for cleanup

.DESCRIPTION
	This function is responsible for calling all the methods for cleanup.

.EXAMPLE
	CompleteCleanup $sitefile $scXML $siteColumnfilePathfile $termsfile

.INPUTS

.OUTPUTS
	Status - $true for when the function has been able to call all the methods for cleanup
			 $false for when the function has not been able to call all the methods for cleanup
#>

function CompleteCleanup($sitefile, $scXML, $siteColumnfilePathfile, $termsfile) {
  #delete Sites
  Remove-SiteCollections $sitefile

  # delete ContentTypes from Contenttypehub
  #Remove-ContentTypes $scXML

  # delete Site Columns from Contenttypehub
  #Remove-Fields $siteColumnfilePathfile

  # delete Taxanomy from Term Store
  #Remove-TaxonomyGroup $termsfile

  #delete Apps from tenant app catalog
  Remove-TenantApp -tenantUrl $tenantUrl
}

<#
.SYNOPSIS
	This function is used to Delete all SiteCollections as per Sites.xml

.DESCRIPTION
	This function will use the PnP cmdlets to Delete all site collection that
	is configured as per Sites.xml.

.EXAMPLE
	Remove-SiteCollections $sitefile

.INPUTS

.OUTPUTS
	Status - $true for when the function has been able to Delete the requested site collection as per xml
			 $false for when the function has not been able to Delete the requested site collection as per xml
#>

function Remove-SiteCollections($sitefile) {
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
  # Connect with the tenant admin credentials to the tenant
  Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin

  $SiteColumnGroup = "TASMU"

  $filePath = $PSScriptRoot + '\resources\Site.xml'
  [xml]$sitefile = Get-Content -Path $filePath
	
  Write-Host "Delete Site Collections Started..."
  $client.TrackEvent("Delete Site Collections Started...")

  foreach ($globalhubsite in $sitefile.sites.globalhubsite.site) {
    try {
      $globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
      $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
			
      if ([bool] ($siteExits) -eq $true) {
        Write-Host 'Site exists ' $globalhubSiteUrl -ForegroundColor Green
        Write-Host 'Starting the removal process' -ForegroundColor Green
        Remove-Lists -siteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin -nodeLevel $sitefile.sites.globalSPList
        Remove-SiteContentTypeGroup $globalhubSiteUrl $SiteColumnGroup $tenantAdmin
        Remove-SiteColumnGroup $globalhubSiteUrl $SiteColumnGroup $tenantAdmin

        Remove-ProductLookupFields -siteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin

        Get-AppsFromXmlFileAndRemove -siteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin -scope 'Marketplace'
        Write-host "Sleep started for 1 minute.." -ForegroundColor Green
        Start-Sleep -s 60
        Write-host "Sleep completed for 1 minute.." -ForegroundColor Green

        Remove-ItemsFromRecycleBin -SiteUrl $globalhubSiteUrl -tenantAdmin $tenantAdmin
        Write-Host "Site Exists so, Remove-PnPTenantSite Started for $globalhubSiteUrl" -ForegroundColor Green
        $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $globalhubSiteUrl")

        try {
          Remove-PnPTenantSite -Url $globalhubSiteUrl -Force -SkipRecycleBin
          Clear-PnPTenantRecycleBinItem -Url $globalhubSiteUrl -Wait -Force
        }
        catch {
          $ErrorMessage = $_.Exception.Message
          Write-Host $ErrorMessage -foreground Red

          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
          $telemtryException.Exception = $_.Exception.Message  
          $client.TrackException($telemtryException)
        }

        Write-Host "Remove-PnPTenantSite Completed for $globalhubSiteUrl" -ForegroundColor Green
        $client.TrackEvent("Remove-PnPTenantSite Completed for $globalhubSiteUrl")
      }
      foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {
        $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
        $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
        if ([bool] ($siteExits) -eq $true) {
          Write-Host 'Site exists ' $sectorhubSiteUrl -ForegroundColor Green
          Write-Host 'Starting the removal process' -ForegroundColor Green

          Remove-Lists -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin -nodeLevel $sitefile.sites.sectorSPList
          Remove-SiteContentTypeGroup $sectorhubSiteUrl $SiteColumnGroup $tenantAdmin
          Remove-SiteColumnGroup $sectorhubSiteUrl $SiteColumnGroup $tenantAdmin

          Remove-ProductLookupFields -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin

          Get-AppsFromXmlFileAndRemove -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin -scope 'Sector'

          Write-host "Sleep started for 1 minute.." -ForegroundColor Green
          Start-Sleep -s 60
          Write-host "Sleep completed for 1 minute.." -ForegroundColor Green
          Remove-ItemsFromRecycleBin -SiteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin

          Write-Host "Site Exists so, Remove-PnPTenantSite Started for $sectorhubSiteUrl" -ForegroundColor Green
          $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $sectorhubSiteUrl")
					
          try {
            Unregister-PnPHubSite -Site $globalhubSiteUrl -Force
            Remove-PnPTenantSite -Url $sectorhubSiteUrl -Force -SkipRecycleBin
            Clear-PnPTenantRecycleBinItem -Url $sectorhubSiteUrl -Wait -Force
          }
          catch {
            $ErrorMessage = $_.Exception.Message
            Write-Host $ErrorMessage -foreground Red
	
            $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
            $telemtryException.Exception = $_.Exception.Message  
            $client.TrackException($telemtryException)
          }

          Write-Host "Remove-PnPTenantSite Completed for $sectorhubSiteUrl" -ForegroundColor Green
          $client.TrackEvent("Remove-PnPTenantSite Completed for $sectorhubSiteUrl")
        }           
        foreach ($orgassociatedsite in $sectorhubsite.orgassociatedsite.site) {
          $orgSiteUrl = $urlprefix + $orgassociatedsite.Alias
          $siteExits = Get-PnPTenantSite -Url $orgSiteUrl -ErrorAction SilentlyContinue
          if ([bool] ($siteExits) -eq $true) {
            Write-Host 'Site exists ' $orgSiteUrl -ForegroundColor Green
            Write-Host 'Starting the removal process' -ForegroundColor Green

            Remove-SiteContentTypeGroup $orgSiteUrl $SiteColumnGroup $tenantAdmin
            Remove-SiteColumnGroup $orgSiteUrl $SiteColumnGroup $tenantAdmin

            Write-host "Sleep started for 1 minute..." -ForegroundColor Green
            Start-Sleep -s 60
            Write-host "Sleep completed for 1 minute..." -ForegroundColor Green
            Remove-ItemsFromRecycleBin -SiteUrl $orgSiteUrl -tenantAdmin $tenantAdmin
						

            Write-Host "Site Exists so, Remove-PnPTenantSite Started for $orgSiteUrl" -ForegroundColor Green
            $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $orgSiteUrl")
						
            try {
              Remove-PnPTenantSite -Url $orgSiteUrl -Force -SkipRecycleBin
              Clear-PnPTenantRecycleBinItem -Url $orgSiteUrl -Wait -Force
            }
            catch {
              $ErrorMessage = $_.Exception.Message
              Write-Host $ErrorMessage -foreground Red
		
              $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
              $telemtryException.Exception = $_.Exception.Message  
              $client.TrackException($telemtryException)
            }

            Write-Host "Remove-PnPTenantSite Completed for $orgSiteUrl" -ForegroundColor Green
            $client.TrackEvent("Remove-PnPTenantSite Completed for $orgSiteUrl")
          }               
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

  foreach ($globalsite in $sitefile.sites.Configsite.site) {
    try {
      $globalSiteUrl = $urlprefix + $globalsite.Alias
      $siteExits = Get-PnPTenantSite -Url $globalSiteUrl -ErrorAction SilentlyContinue
			
      if ([bool] ($siteExits) -eq $true) {
        Write-Host 'Site exists ' $globalSiteUrl -ForegroundColor Green
        Write-Host 'Starting the removal process' -ForegroundColor Green

        Remove-Lists -siteUrl $globalSiteUrl -tenantAdmin $tenantAdmin -nodeLevel $sitefile.sites.ConfigurationSPList
        Remove-SiteContentTypeGroup $globalSiteUrl $SiteColumnGroup $tenantAdmin
        Remove-SiteColumnGroup $globalSiteUrl $SiteColumnGroup $tenantAdmin

        Remove-ProductLookupFields -siteUrl $globalSiteUrl -tenantAdmin $tenantAdmin

        Get-AppsFromXmlFileAndRemove -siteUrl $sectorhubSiteUrl -tenantAdmin $tenantAdmin -scope 'Global'
        Write-host "Sleep started for 1 minute.." -ForegroundColor Green
        Start-Sleep -s 60
        Write-host "Sleep completed for 1 minute.." -ForegroundColor Green
        Remove-ItemsFromRecycleBin -SiteUrl $globalSiteUrl -tenantAdmin $tenantAdmin
        Write-Host "Site Exists so, Remove-PnPTenantSite Started for $globalSiteUrl" -ForegroundColor Green
        $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $globalSiteUrl")
			 
        try {
          Remove-PnPTenantSite -Url $globalSiteUrl -Force -SkipRecycleBin
          Clear-PnPTenantRecycleBinItem -Url $globalSiteUrl -Wait -Force
        }
        catch {
          $ErrorMessage = $_.Exception.Message
          Write-Host $ErrorMessage -foreground Red

          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
          $telemtryException.Exception = $_.Exception.Message  
          $client.TrackException($telemtryException)
        }
			
        Write-Host "Remove-PnPTenantSite Completed for $globalSiteUrl" -ForegroundColor Green
        $client.TrackEvent("Remove-PnPTenantSite Completed for $globalSiteUrl")
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

  #Remove-DeletedSites -tenantUrl $tenantUrl -tenantAdmin $tenantAdmin

  Disconnect-PnPOnline
}

<#
.SYNOPSIS
	This function is used to Delete all Content Types as per Sites.xml

.DESCRIPTION
	This function will use the PnP cmdlets to Delete all Content Types that
	is configured as per ContentType.xml.

.EXAMPLE
	Remove-ContentTypes $scXML

.INPUTS

.OUTPUTS
	Status - $true for when the function has been able to Delete the requested Content Types as per ContentType.xml
			 $false for when the function has not been able to Delete the requested sContent Types as per ContentType.xml
#>
function Remove-ContentTypes($scXML) {
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
  # Connect with the tenant admin credentials to the tenant
  Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
  $connection = Get-PnPConnection

  Write-Host "Delete Content Types Started..."
  $client.TrackEvent("Delete Content Types Started...")

  foreach ($contentItem in $scXML.Main.siteContentTypes.contentItem) {
    try {
      $ContentTypeExist = Get-PnPContentType -Identity $contentItem.ContentTypeName -ErrorAction SilentlyContinue
      if ([bool] ($ContentTypeExist) -eq $true) {
        $ct = $contentItem.ContentTypeName
        Write-Host "ContentType $ct Exists so, Remove-PnPContentType Started."
        $client.TrackEvent("ContentType $ct Exists so, Remove-PnPContentType Started.")
				
        Remove-PnPContentType -Identity $contentItem.ContentTypeName -Force -Connection $connection
				
        Write-Host "ContentType $ct Removed."
        $client.TrackEvent("ContentType $ct Removed.")
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
  Disconnect-PnPOnline
}

<#
.SYNOPSIS
	This function is used to Delete all Site Columns as per Sites.xml

.DESCRIPTION
	This function will use the PnP cmdlets to Delete all Content Types that
	is configured as per SiteColumns.xml.

.EXAMPLE
	Remove-Fields $siteColumnfilePathfile

.INPUTS

.OUTPUTS
	Status - $true for when the function has been able to Delete the requested Site Columns as per xml
			 $false for when the function has not been able to Delete the requested Site Columns as per xml
#>

function Remove-Fields($siteColumnfilePathfile) {
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
  # Connect with the tenant admin credentials to the tenant
  Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
  $connection = Get-PnPConnection

  Write-Host "Delete All items from the Recycle Bin Started..."
  Clear-PnPRecycleBinItem -All -Force
  Write-Host "Delete All items from the Recycle Bin Completed..."

  Write-Host "Delete Site Columns Started..."
  $client.TrackEvent("Delete Site Columns Started...")
	 
  foreach ($field in $siteColumnfilePathfile.SiteFields.Field) {
    Remove-Field -field $field -connection $connection
  }

  Disconnect-PnPOnline

  $SiteColumnGroup = "TASMU"
  Remove-SiteColumnGroup $contenttypehub $SiteColumnGroup $tenantAdmin

}

<#
.SYNOPSIS
	This function is used to Delete all Taxanomy and respective Taxanomy Group as per Taxonomy.xml

.DESCRIPTION
	This function will use the PnP cmdlets to Delete all Taxanomy and respective Taxanomy Group that
	is configured as per Taxonomy.xml.

.EXAMPLE
	Remove-Fields $siteColumnfilePathfile

.INPUTS

.OUTPUTS
	Status - $true for when the function has been able to Delete all Taxanomy and respective Taxanomy Group as per xml
			 $false for when the function has not been able to Delete all Taxanomy and respective Taxanomy Group as per xml
#>

function Remove-TaxonomyGroup($termsfile) {
  $secstr = New-Object -TypeName System.Security.SecureString
  $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

  $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
  # Connect with the tenant admin credentials to the tenant
  Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
  $connection = Get-PnPConnection

  Write-Host "Delete Taxonomy Started..."
  $client.TrackEvent("Delete Taxonomy Started...")
	 
  foreach ($Group in $termsfile.TermStores.TermStore.Groups.Group) {
    try {
      $groupExists = Get-PnPTermGroup -identity $Group.Name -ErrorAction SilentlyContinue
		
      if ([bool] ($groupExists) -eq $true) {
        $groupName = $Group.Name
        Write-Host "Taxanomy Group $groupName Exists so, Remove-PnPTermGroup Started."
        $client.TrackEvent("Taxanomy Group $groupName Exists so, Remove-PnPTermGroup Started.")
				
        Remove-PnPTermGroup -GroupName $Group.Name -Force -Connection $connection
				
        Write-Host "Taxanomy Group $groupName Removed."
        $client.TrackEvent("Taxanomy Group $groupName Removed.")
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
  Disconnect-PnPOnline
}

<#
.SYNOPSIS
	This function is used to Delete all Site Column belonging to the TASMU group

.DESCRIPTION
	This function will use the CSOM commands to delete all site columns belonging to the TASMU group

.EXAMPLE
	Remove-SiteColumnGroup $SiteURL $SiteColumnGroup $tenantAdmin

.INPUTS

.OUTPUTS
	
#>

function Remove-SiteColumnGroup($SiteURL, $SiteColumnGroup, $tenantAdmin) {
  Try {
    #Setup the context
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
	 
    $Ctx.Load($Ctx.Web)
    $Ctx.Load($Ctx.Web.Fields)
    $Ctx.ExecuteQuery()
 
    #Get the site column Group
    $SiteColumns = $Ctx.Web.Fields | Where-Object { $_.Group -eq $SiteColumnGroup }
    if ($null -ne $SiteColumns) {
      #Loop Through Each Field
      ForEach ($Column in $SiteColumns) {
        try {
          Write-host "Removing Site Column:" $($Column.InternalName) -ForegroundColor Green
          $Column.DeleteObject()
          $Ctx.ExecuteQuery()
          Write-Host $column.InternalName 'removed successfully!!!' -ForegroundColor Green

          Remove-ItemsFromRecycleBin -SiteUrl $siteURL -tenantAdmin $tenantAdmin
        }
        catch {
          write-host -f Red "Error Removing Site Column!" $column.InternalName $_.Exception.Message
        }
      }
      Write-host -f Green "Site Columns Deleted Successfully!"
    }
    Else {
      Write-host -f Yellow "Site Column Group '$($SiteColumnGroup)' Does not Exist!"
    }   
  }
  Catch {
    write-host -f Red "Error Removing Site Columns!" $_.Exception.Message
  }
}

<#
.SYNOPSIS
	This function is used to Delete all Site Content Types belonging to the TASMU group

.DESCRIPTION
	This function will use the CSOM commands to delete all site cotent types belonging to the TASMU group

.EXAMPLE
	Remove-SiteContentTypeGroup $SiteURL $SiteColumnGroup $tenantAdmin

.INPUTS

.OUTPUTS
	
#>

Function Remove-SiteContentTypeGroup($SiteURL, $SiteColumnGroup, $tenantAdmin) {
  Try {
    #Setup the context
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
	 
    $Ctx.Load($Ctx.Web)
    $Ctx.Load($Ctx.Web.ContentTypes)
    $Ctx.ExecuteQuery()
 
    #Get the site column Group
    $SiteCTs = $Ctx.Web.ContentTypes | Where-Object { $_.Group -eq $SiteColumnGroup }
    if ($null -ne $SiteCTs) {
      #Loop Through Each Field
      ForEach ($CT in $SiteCTs) {
        try {
          if ($CT.ReadOnly) {
            Write-Host $CT.Name 'is readonly. Making it false before removing' -ForegroundColor Green
            $CT.ReadOnly = $false
            $CT.Update($False) # Update children
            $Ctx.ExecuteQuery()
          }
          Write-host "Removing Site Content Type:" $CT.Name -ForegroundColor Green
          $CT.DeleteObject()
          $Ctx.ExecuteQuery()

          Remove-ItemsFromRecycleBin -SiteUrl $SiteURL -tenantAdmin $tenantAdmin
        }
        catch {
          write-host -f Red "Error Removing Site Content Type!" $CT.name $_.Exception.Message
          Remove-ContentType -SiteURL $SiteURL -ContentTypeName $CT.Name -tenantAdmin $tenantAdmin
        }
      }
      Write-host -f Green "Site Content Type Deleted Successfully!"
    }
    Else {
      Write-host -f Yellow "Site CT Group '$($SiteColumnGroup)' Does not Exist!"
    }   
  }
  Catch {
    write-host -f Red "Error Removing Site Content Type!" $_.Exception.Message
  }
}

<#
.SYNOPSIS
	This function is used to remove all deletes sites 

.DESCRIPTION
	This function will use the PnP commands to remove all deleted sites

.EXAMPLE
	Remove-DeletedSites $tenantUrl $tenantAdmin

.INPUTS

.OUTPUTS
	
#>

function Remove-DeletedSites {
  param (
    $tenantUrl,
    $tenantAdmin
  )
	
  try {
    Connect-SPOService -Url $tenantUrl -Credential $tenantAdmin
    $allDeletedSites = Get-SPODeletedSite
    if ($null -ne $allDeletedSites) {
      foreach ($deletedSite in $allDeletedSites) {  
        Remove-SPODeletedSite -Identity $deletedSite.Url -NoWait -Confirm:$false
      }
    }
  }
  catch {
    Write-Error $_.Exception.Message
  }
}


<#
.SYNOPSIS
	This function is used to remove all TASMU related App as per the Apps.xml file 

.DESCRIPTION
	This function will use the PnP commands to remove Apps from tenant app catalog

.EXAMPLE
	Remove-TenantApp $tenantUrl $tenantAdmin

.INPUTS

.OUTPUTS
	
#>

function Remove-TenantApp {
  param (
    $tenantUrl
  )

  try {
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    $tenantApps = Get-PnPApp -Scope Tenant
    $appsPath = $PSScriptRoot + '\resources\Apps.xml'
    [xml]$appFile = Get-Content -Path $appsPath
    foreach ($app in $appFile.Apps.app) {
      if ($null -ne $tenantApps) {
        foreach ($tenantApp in $tenantApps) {
          if ($tenantApp.Title -eq $app.Title) {
            try {
              Uninstall-PnPApp -Identity $tenantApp.Id
              Remove-PnPApp -Identity $tenantApp.Id
              Write-Host 'App '$app.Title' removed from tenant App Catalog'  -ForegroundColor Green
            }
            catch {
              write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
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


<#
.SYNOPSIS
	This function is used to remove items from Recylce Bin

.DESCRIPTION
	This function will use the PnP commands to remove items from Recycle Bin

.EXAMPLE
	Remove-ItemsFromRecycleBin $SiteUrl $tenantAdmin

.INPUTS

.OUTPUTS
	
#>

function Remove-ItemsFromRecycleBin {
  param (
    $SiteUrl,
    $tenantAdmin
  )
  try {
    #Setup the context
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
	 
    #Move All Deleted Items to 2nd Stage Recycle bin
    $Ctx.Site.RecycleBin.MoveAllToSecondStage()
    $Ctx.ExecuteQuery()
    Write-Host 'Moving all deleted items to 2nd stage recycle bin' -ForegroundColor Yellow
    #Delete All Items from 2nd Stage Recycle bin
    $Ctx.Site.RecycleBin.DeleteAllSecondStageItems()
    $Ctx.ExecuteQuery()
    Write-Host 'All items are deleted from 2nd stage recycle bin' -ForegroundColor Green
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }
}

function Remove-AppFromSite {
  param (
    $siteUrl,
    $tenantAdmin,
    $appName
  )
	
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    $App = Get-PnPApp | Where-Object { $_.Title -eq $appName }
    if ([bool]($App) -eq $true) {
      Write-Host $appName 'found at ' $siteUrl
      Write-Host 'Unistalling and removing ' $appName 'from ' $siteUrl
      Uninstall-PnPApp -Identity $App.Id
      Remove-PnPApp -Identity $App.Id
      Write-Host $appName 'is unistalled and removed from the site collection ' $siteUrl
    }
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }

}

function Get-AppsFromXmlFileAndRemove {
  param (
    $siteUrl,
    $tenantAdmin,
    $scope
  )

  try {
    $appsPath = $PSScriptRoot + '\resources\Apps.xml'
    [xml]$appFile = Get-Content -Path $appsPath
    foreach ($app in $appFile.Apps.app) {
      if ($app.Scope -eq $scope) {
        Remove-AppFromSite -siteUrl $siteUrl -tenantAdmin $tenantAdmin -appName $app.Title
      }
    }
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }
}

function Remove-Lists {
  param (
    $siteUrl,
    $tenantAdmin,
    $nodeLevel
  )
	
  try {
    foreach ($itemList in $nodeLevel.ListAndContentTypes) {
      Remove-List -listName $itemList.ListName -siteUrl $siteUrl -tenantAdmin $tenantAdmin
    }
  }
  catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
  }
}

function Remove-ProductLookupFields {
  param (
    $siteUrl,
    $tenantAdmin
  )
  
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    $fieldProductIdExists = Get-PnPField -Identity Product_x003a_ProductId
    if ([bool]($fieldProductIdExists) -eq $true) {
      Remove-PnPField -Identity Product_x003a_ProductId -Force
      
    }
    $fieldProductArabicNameExists = Get-PnPField -Identity Product_x003a_arProductName
    if ([bool]($fieldProductArabicNameExists) -eq $true) {
      Remove-PnPField -Identity Product_x003a_arProductName -Force
    }
    $fieldProductShortDescriptionExists = Get-PnPField -Identity Product_x003a_ProductShortDescription
    if ([bool]($fieldProductShortDescriptionExists) -eq $true) {
      Remove-PnPField -Identity Product_x003a_ProductShortDescription -Force
    }
    $fieldProductArabicShortDescriptionExists = Get-PnPField -Identity Product_x003a_arProductShortDescription
    if ([bool]($fieldProductArabicShortDescriptionExists) -eq $true) {
      Remove-PnPField -Identity Product_x003a_arProductShortDescription -Force
    }
    $fieldProductNameExists = Get-PnPField -Identity ProductName
    if ([bool]($fieldProductNameExists) -eq $true) {
      Remove-PnPField -Identity ProductName -Force
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

function Get-ContentTypeReferences() {
  param (
    $SiteURL,
    $ContentTypeName,
    $tenantAdmin
  )
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
  Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

  $admin = $tenantAdmin.UserName
  $password = $tenantAdmin.Password
  $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)

  try {
    Write-host -f Yellow "Processing Site:" $SiteURL
 
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $credentials
     
    #Get All Lists of the Web
    $Ctx.Load($Ctx.Web)
    $Ctx.Load($Ctx.Web.Lists)
    $Ctx.Load($ctx.Web.Webs)
    $Ctx.ExecuteQuery()
 
    #Get content types of each list from the web
    $ContentTypeUsages = @()
    foreach ($List in $Ctx.Web.Lists) {
      $ContentTypes = $List.ContentTypes
      $Ctx.Load($ContentTypes)
      $Ctx.Load($List.RootFolder)
      $Ctx.ExecuteQuery()
             
      #Get List URL
      If ($Ctx.Web.ServerRelativeUrl -ne "/") {
        $ListURL = $("{0}{1}" -f $Ctx.Web.Url.Replace($Ctx.Web.ServerRelativeUrl, ''), $List.RootFolder.ServerRelativeUrl)
      }
      else {
        $ListURL = $("{0}{1}" -f $Ctx.Web.Url, $List.RootFolder.ServerRelativeUrl)
      }
   
      #Get each content type data
      foreach ($CType in $ContentTypes) {
        If ($CType.Name -eq $ContentTypeName) {
          $ContentTypeUsage = New-Object PSObject
          $ContentTypeUsage | Add-Member NoteProperty SiteURL($SiteURL)
          $ContentTypeUsage | Add-Member NoteProperty ListName($List.Title)
          $ContentTypeUsage | Add-Member NoteProperty ListURL($ListURL)
          $ContentTypeUsage | Add-Member NoteProperty ContentTypeName($CType.Name)
          $ContentTypeUsages += $ContentTypeUsage
          Write-host -f Green "Found the Content Type at:" $ListURL
          #delete the list/library first and then delete it from the recycle bin stage 1 & stage 2
          Remove-List -siteUrl $SiteURL -listName $list.Title -tenantAdmin $tenantAdmin
        }
      }
    }
    #Iterate through each subsite of the current web and call the function recursively
    foreach ($Subweb in $Ctx.web.Webs) {
      #Call the function recursively to process all subsites underneaththe current web
      Get-ContentTypeReferences $Subweb.url $ContentTypeName
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

function Remove-ContentType() {
  param
  (
    $SiteURL,
    $ContentTypeName,
    $tenantAdmin
  )
 
  try {
    $admin = $tenantAdmin.UserName
    $password = $tenantAdmin.Password
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
 
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $Credentials
     
    #Get the content type from web
    $ContentTypeColl = $Ctx.Web.ContentTypes
    $Ctx.Load($ContentTypeColl)
    $Ctx.ExecuteQuery()
         
    #Check if the content type exists in the site       
    $ContentType = $ContentTypeColl | Where-Object { $_.Name -eq $ContentTypeName }
    If ($Null -eq $ContentType) {
      Write-host "Content Type '$ContentTypeName' doesn't exists in '$SiteURL'" -f Yellow
    }
    else {
      #delete the content type
      $ContentType.DeleteObject()
      $Ctx.ExecuteQuery()
 
      Write-host "Content Type '$ContentTypeName' deleted successfully!" -ForegroundColor Green
    }
  }
  catch {
    write-host -f Red "Error Deleting Content Type!" $_.Exception.Message
    Get-ContentTypeReferences -ContentTypeName $ContentTypeName -SiteURL $SiteURL -tenantAdmin $tenantAdmin
    #Try to delete the content type again
    $ContentType = Get-PnPContentType -Identity $ContentTypeName
    If ($ContentType) {
      Write-Host 'Content type :' $ContentType 'found.Trying to delete it' -ForegroundColor Yellow
      Remove-PnPContentType -Identity $ContentTypeName -Force
      Write-Host $ContentType 'deleted successfully' -ForegroundColor Green
    }
  }
}

function Remove-Field {
  param (
    $field,
    $connection
  )
  
  try {
    $getField = Get-PnpField -identity $field.ColumnName -Connection $connection -ErrorAction SilentlyContinue
  
    if ([bool] ($getField) -eq $true) {
      $colName = $field.ColumnName
      Write-Host "Field $colName Exists so, Remove-PnPField Started."
      $client.TrackEvent("Field  $colName Exists so, Remove-PnPField Started.")
      
      Remove-PnPField -Identity $field.ColumnName -Force -Connection $connection
      
      Write-Host "Field  $colName  Removed."
      $client.TrackEvent("Field  $colName  Removed.")
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

function Remove-List {
  param (
    $listName,
    $siteUrl,
    $tenantAdmin
  )
  
  try {
    Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    $removedList = Remove-PnPList -Identity $listName -Force
    Write-Host $listName 'deleted successfully from the site ' $siteUrl -ForegroundColor Green
    Write-Host 'Emptying the recycle bin' -ForegroundColor Yellow
    Remove-ItemsFromRecycleBin -SiteUrl $siteUrl -tenantAdmin $tenantAdmin
  }
  catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage -foreground Red

    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

Complete-Cleanup