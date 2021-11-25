<#
.DESCRIPTION
    This Script is for used as a prerequisite for running the Azure build pipeline for PnP.Powershell

.INPUTS
    

.OUTPUTS
    Uninstall SharePointPnPPowerShellOnline and then Install SharePointPnPPowerShellOnline

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : pnppowershellprerequisites.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
18/02/2021  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>

Write-Host 'Checking the current version of PnP.Powershell installed' -ForegroundColor Yellow
$pnpPowerShellModule = Get-InstalledModule -Name PnP.PowerShell -ErrorAction SilentlyContinue
if($null -ne $pnpPowerShellModule){
    Write-host 'Current installed version module for PnP.PowerShell is ' $pnpPowerShellModule.Version -ForegroundColor Green
    if($pnpPowerShellModule.Version -ne '1.2.0'){
        Write-Host 'Incompatible version of PnP.Powershell is installed. Uninstalling ...' -ForegroundColor Green
        Uninstall-Module -Name PnP.PowerShell -AllVersions -ErrorAction SilentlyContinue -Force
    }
}

Write-Host "Uninstalling SharePointPnPPowerShellOnline module" -ForegroundColor Green
$module = Get-InstalledModule -Name SharePointPnPPowerShellOnline -ErrorAction SilentlyContinue 

if($null -ne $module){
    Write-Host 'SharePointPnPPowerShellOnline moudule found. Uninstalling ...' -ForegroundColor Green
    Uninstall-Module -Name SharePointPnPPowerShellOnline -AllVersions -ErrorAction SilentlyContinue -Force
}
else{
    Write-Host 'SharePointPnPPowerShellOnline moudule not found.' -ForegroundColor Yellow
}

Write-host "Installing PnP.PowerShell module" -ForegroundColor Green
$pnpPowerShellModule = Get-InstalledModule -Name PnP.PowerShell -ErrorAction SilentlyContinue
if($null -eq $pnpPowerShellModule){
    Write-host "PnP.PowerShell module not found. Installing ..." -ForegroundColor Green
    Install-Module -Name PnP.PowerShell -RequiredVersion 1.2.0 -Force
}
else{
    Write-host 'Current installed version module for PnP.PowerShell is ' $pnpPowerShellModule.Version -ForegroundColor Green
}

Write-host "Sleep started for 15 seconds..." -ForegroundColor Green
start-sleep -s 15
Write-host "Sleep completed for 15 seconds..." -ForegroundColor Green
Write-host "Registering PnP Management Shell Access" -ForegroundColor Green
#Register-PnPManagementShellAccess
Write-host "Success"