<#
.DESCRIPTION
    This Script is for adding users to sharepoint groups

.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : AddUsers.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
12/10/2020  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
    $tenant,
    $TemplateParametersFile ,
    $sp_user,
    $sp_password ,
    $InstrumentationKey
)
Write-host "Started" -ForegroundColor Green
Write-host $tenant -ForegroundColor Yellow

$users = $PSScriptRoot + '.\Users.xml'

Import-PackageProvider -Name "NuGet" -RequiredVersion "3.0.0.1" -Force
#Install-Module SharePointPnPPowerShellOnline -Force -Verbose -Scope CurrentUser

$parentDirectory = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf('\'))

#Setup Telemetry
Add-Type -Path (Resolve-Path $parentDirectory'\Assemblies\Microsoft.ApplicationInsights.dll')
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($parentDirectory, $TemplateParametersFile))
# Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
$JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
if ( $null -ne ($JsonParameters | Get-Member -Type NoteProperty 'parameters')) {
    $JsonParameters = $JsonParameters.parameters
}
$RoleName = $JsonParameters.RoleName.value
$client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
$client.InstrumentationKey = $InstrumentationKey 
if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
    $client.Context.Cloud.RoleName = $RoleName
}

#setup Auth
$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

[xml]$usersfile = Get-Content -Path $users
$urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"

function AddUsers {

    
    foreach ($globalGroup in $usersfile.Groups.globalSPGroup) {
        $globalhubSiteUrl = $urlprefix + $globalGroup.Alias

        #Add users to non default SPGroups in marketplace
        AddUsersToSPGroup $globalhubSiteUrl $globalGroup $globalGroup.group

        #Ad users to default SPGroups in marketplace
        AddUsersToSPGroup $globalhubSiteUrl $globalGroup $globalGroup.defaultgroup
    }

    foreach ($sectorGroup in $usersfile.Groups.sectorSPGroup) {
        $sectorhubSiteUrl = $urlprefix + $sectorGroup.Alias

        #Add users to non default SPGroups in sectors
        AddUsersToSPGroup $sectorhubSiteUrl $sectorGroup $sectorGroup.group

        #Add users to default SPGroups in sectors
        AddUsersToSPGroup $sectorhubSiteUrl $sectorGroup $sectorGroup.defaultgroup
    }

    Write-Host 'completed' -ForegroundColor Green
    $client.TrackEvent('completed')
}


function AddUsersToSPGroup($url, $nodeLevel, $groups) {
    $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
    
    try {
 
        foreach ($SPGroup in $groups) {

            if ($nodeLevel.Alias -eq "cms-marketplace") {
                $SPGroupName = 'Global ' + $SPGroup.Name
            }
            else {
                $SPGroupName = $nodeLevel.Title + ' ' + $SPGroup.Name    
            }
            
                  
            $GroupPresent = Get-PnPGroup -Identity $SPGroupName -Connection $connection -ErrorAction SilentlyContinue
 
            if ([bool]($GroupPresent) -eq $true) {
                Write-Host "Adding users in $SPGroupName group in $url"
                $client.TrackEvent("Adding users in $SPGroupName group in $url")
             
                if ($SPGroup.isUsers -eq $true) {
                    $web = Get-PnPWeb  
                    $ctx = $web.Context  
                    $newGroupName = $web.SiteGroups.GetByName($SPGroupName)  
                    $ctx.Load($newGroupName)  
                    $ctx.ExecuteQuery()
 
                    foreach ($user in $SPGroup.users) {
 
                        try {                  
                            $userName = $user.email  
                            $userInfo = $web.EnsureUser($userName)  
                            $ctx.Load($userInfo)  
                            $addUser = $GroupPresent.Users.AddUser($userInfo)  
                            $ctx.Load($addUser)  
                            $ctx.ExecuteQuery()
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
 
                if ($SPGroup.isADGroup -eq $true) {
                    $web = Get-PnPWeb  
                    $ctx = $web.Context  
                    $newGroupName = $web.SiteGroups.GetByName($SPGroupName)  
                    $ctx.Load($newGroupName)  
                    $ctx.ExecuteQuery()
 
                    foreach ($ADGroupUser in $SPGroup.ADGroup) {
 
                        try {
                                    
                            $ADGroup = $web.EnsureUser($ADGroupUser)                    
                            #sharepoint online powershell add AD group to sharepoint group
                            $Result = $GroupPresent.Users.AddUser($ADGroup)
                            $ctx.Load($Result)
                            $ctx.ExecuteQuery()
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
          
                if ($SPGroup.SecurityGroup -ne '') {
                    # Add Security group as member to Sharepoint group
                    Add-PnPUserToGroup -Identity $SPGroupName -LoginName $SPGroup.SecurityGroup -Connection $connection
                }
            }
            else {
                Write-Host $SPGroupName ' not found in '$url  -ForegroundColor Red
                $client.TrackEvent('$SPGroupName not found in $url')
            }
                   
        }
       
    }   
    catch {            
        Write-Host $_.Exception.Message -ForegroundColor Red
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
    Disconnect-PnPOnline
}


AddUsers