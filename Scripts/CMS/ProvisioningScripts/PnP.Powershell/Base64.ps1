param (
	$filePath,
	$tenant,
	$sp_user,
	$sp_password
)

$fileContentBytes = get-content $filePath -Encoding Byte 


$SiteURL = "https://" + $tenant + ".sharepoint.com/sites/cms-marketplace"
$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
Connect-PnPOnline -Url $SiteURL -Credentials $tenantAdmin -ErrorAction Stop

[System.Convert]::ToBase64String($fileContentBytes) | Out-File $env:BUILD_ARTIFACTSTAGINGDIRECTORY/base64.txt
Add-PnPFile -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY/base64.txt -Folder "Shared Documents"

Write-Host "FileName - base64.txt uploaded in the Documents library on marketplace site in your tenant"
Write-Host $SiteURL
Write-Host "Please delete that file once you are done with the updation of Cms-Function-CerficatePfxKey value in the ADO"