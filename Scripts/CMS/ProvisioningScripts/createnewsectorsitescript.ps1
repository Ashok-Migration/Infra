<#
.DESCRIPTION
    This Script is for Creating all Blank Communication Sites as per the input from the XML file for Sector sites
    XML files it will look for inputs are
    Sectors.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Sector Sites as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : createnewsectorsitescript.ps1
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

function Create-NewSiteCollection() {
    $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
 
    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    }

    $RoleName = $JsonParameters.RoleName.value
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    $client.InstrumentationKey = $InstrumentationKey 
    if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
        $client.Context.Cloud.RoleName = $RoleName
    }
    $filePath = $PSScriptRoot + '\resources\Sectors.xml'
    $serchConfigPath = $PSScriptRoot + '\resources\SearchConfiguration.xml'
    $tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
    $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"

    [xml]$sitefile = Get-Content -Path $filePath
    ProvisionSiteCollections $sitefile

    Write-host "Completed" -ForegroundColor Green
    $client.TrackEvent("Completed.")
}


#region --Site collection Creation--
function ProvisionSiteCollections($sitefile) {
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
     
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin

    foreach ($globalhubsite in $sitefile.sites.globalhubsite.site) {
        foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {

            $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
           
            Create-SiteCollection $sectorhubsite.Type $sectorhubsite.Title $sectorhubsite.Alias  $sectorhubSiteUrl

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
            #    Create-SiteCollection $orgassociatedsite.Type $orgassociatedsite.Title $orgassociatedsite.Alias $isGlobalHubSite $globalhubSiteUrl $isSectorHubSite $sectorhubSiteUrl $isOrgSite $orgSiteUrl
            #                           
            #    }
        }
    }  
       
    Disconnect-PnPOnline
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
function Create-SiteCollection($Type, $Title, $Alias, $sectorhubSiteUrl) {
    try {
        $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
        
        #Check for existence of SPE Admin Site 
        if ([bool] ($siteExits) -eq $false) {
            #Create new site if site collection does not exist      
            
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


Create-NewSiteCollection