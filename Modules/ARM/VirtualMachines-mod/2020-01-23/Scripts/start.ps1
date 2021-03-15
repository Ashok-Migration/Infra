#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#cls
$logfolder = "C:\Temp2\"
$fileName = "Report"
$enddate = (Get-Date).tostring("yyyyMMddhhmmss")
$logFileName = $fileName +"_"+ $enddate+"_Log.txt"
$directoryPathForLog= $logfolder + $logFileName
if(!(Test-Path -path $logfolder))  
{  
 New-Item -ItemType directory -Path $logfolder 
 Write-Host "Folder path has been created successfully at: " $logfolder   
 }
else 
{ 
Write-Host "The given folder path $logfolder already exists"; 
}

Start-Transcript -path $directoryPathForLog -NoClobber
write-host "******************************************"
get-date
write-host "**********stoping print spooler**********"
stop-Service -Name "Spooler" -Force 
get-Service -Name "Spooler"

write-host "**********set path**********"
Set-Location Modules\ARM\VirtualMachines\2020-01-23\Scripts
Get-Location

write-host "**********disk initializetion**********"
.\InitializeDisksWindows.ps1


write-host "**********installing module**********"
Install-PackageProvider -Name NuGet -Force 
install-module AuditPolicyDSC -SkipPublisherCheck -Force
install-module ComputerManagementDsc -SkipPublisherCheck -Force
install-module SecurityPolicyDsc -SkipPublisherCheck -Force

write-host "**********Hardanning  process**********"
.\AzSC_WindowsServer2019-tasmu-v1.ps1
Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048

write-host "**********starting Hardanning  process**********"

Start-DscConfiguration -Path .\AzSC_WindowsServer2019 -Force -Wait -Verbose 
# Start-DscConfiguration -Path .\Modules\ARM\VirtualMachines\2020-01-23\Scripts\AzSC_WindowsServer2019 -Force -Verbose –Wait
write-host " **************************************"

write-host " restarting computer"
#Restart-Computer

get-date
write-host "******************************************"
stop-Transcript