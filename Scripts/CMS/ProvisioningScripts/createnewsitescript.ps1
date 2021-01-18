<#
.DESCRIPTION
    This Script is for Creating all Blank Communication Sites as per the input from the XML file
    XML files it will look for inputs are
    Site.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Sites as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : createnewsitescript.ps1
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
    $scope,
    $InstrumentationKey
)

function Add-SiteCollections() {
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

    $filePath = $PSScriptRoot + '\resources\Site.xml'

    [xml]$sitefile = Get-Content -Path $filePath

    $serchConfigPath = $PSScriptRoot + '\resources\SearchConfiguration.xml'

    $tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
    $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"

    ProvisionSiteCollections $sitefile

    Write-host "Completed" -ForegroundColor Green
    $client.TrackEvent("Completed.")

}


#region --Site collection Creation--
function ProvisionSiteCollections($sitefile) {
    #$tenantAdmin = Get-Credential -Message "Enter Tenant Administrator Credentials"
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
     
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    foreach ($globalconfigsite in $sitefile.sites.Configsite.site) {
        $isGlobalHubSite = $True
        $globalconfigSiteUrl = $urlprefix + $globalconfigsite.Alias
        Add-Site $globalconfigsite.Type $globalconfigsite.Title $globalconfigsite.Alias $isGlobalHubSite $globalconfigSiteUrl '' '' '' ''
    }

    foreach ($globalhubsite in $sitefile.sites.globalhubsite.site) {
        $isGlobalHubSite = $True
        $globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
        Add-Site $globalhubsite.Type $globalhubsite.Title $globalhubsite.Alias $isGlobalHubSite $globalhubSiteUrl '' '' '' ''

        
        foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {
            Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
            $connection = Get-PnPConnection

            $isGlobalHubSite = $False
            $isSectorHubSite = $True
            $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
           
            Add-Site $sectorhubsite.Type $sectorhubsite.Title $sectorhubsite.Alias $isGlobalHubSite $globalhubSiteUrl $isSectorHubSite $sectorhubSiteUrl '' ''

            # Entity provisioning 
            #foreach($orgassociatedsite in $sectorhubsite.orgassociatedsite.site)
            # {
            #
            #    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
            #    $connection = Get-PnPConnection
            #
            #    $isGlobalHubSite = $False
            #    $isSectorHubSite = $False
            #    $isOrgSite = $True
            #    $orgSiteUrl = $urlprefix + $orgassociatedsite.Alias
            #    
            #    Add-Site $orgassociatedsite.Type $orgassociatedsite.Title $orgassociatedsite.Alias $isGlobalHubSite $globalhubSiteUrl $isSectorHubSite $sectorhubSiteUrl $isOrgSite $orgSiteUrl
            #                           
            #    }
        }
    }   
}

function SearchConfiguration($Scope, $serchConfigPath) {
    try {
        if (Test-Path $serchConfigPath) {
            $client.TrackEvent("Search Configuration Started at Tenent Level.")
            Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
            Set-PnPSearchConfiguration -Path $serchConfigPath -Scope $Scope
            $client.TrackEvent("Completed.")
        }
        else {
            $client.TrackEvent("Search Configuration Completed at Tenent Level.")
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
  
    Disconnect-PnPOnline
}


function Add-Site($Type, $Title, $Alias, $isGlobalHubSite, $globalhubSiteUrl, $isSectorHubSite, $sectorhubSiteUrl, $isOrgSite, $orgSiteUrl) {
    try {
        if ($isGlobalHubSite -eq $true) {
            $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
        }
        if ($isSectorHubSite -eq $true) {
            $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
        }
        
        #Check for existence of SPE Admin Site 
        if ([bool] ($siteExits) -eq $false) {
            #Create new site if site collection does not exist      
            
            if ($isGlobalHubSite) {
                try {
                    Write-Host "Site collection not found ,so creating a new $globalhubSiteUrl ....."
                    $client.TrackEvent("Site collection not found ,so creating a new $globalhubSiteUrl .....")
        
                    New-PnPSite -Type $Type -Title $Title -Url $globalhubSiteUrl -SiteDesign Blank -ErrorAction Stop
                    $client.TrackEvent("Site collection created.. $globalhubSiteUrl") 
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Host $ErrorMessage -foreground Yellow

                    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                    $telemtryException.Exception = $_.Exception.Message  
                    $client.TrackException($telemtryException)

                }
            }
                
            if ($isSectorHubSite) {
                try {
                    Write-Host "Site collection not found ,so creating a new $sectorhubSiteUrl ....."
                    $client.TrackEvent("Site collection not found ,so creating a new $sectorhubSiteUrl .....")
            
                    New-PnPSite -Type $Type -Title $Title -Url $sectorhubSiteUrl -SiteDesign Blank
                    $client.TrackEvent("Site collection created.. $sectorhubSiteUrl") 
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Host $ErrorMessage -foreground Yellow

                    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                    $telemtryException.Exception = $_.Exception.Message  
                    $client.TrackException($telemtryException)
                }
            }
        }
        else {
            Write-Host "Site Collection- $siteTitle already exists"
            $client.TrackEvent("Site Collection- $siteTitle already exists")
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
#endregion


Add-SiteCollections