param (
    $tenant,
    $sp_user,
    $sp_password
) 


function Get-Resx($xmlFile) {
    [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null
 
    try {
        $xDoc = [System.Xml.Linq.XDocument]::Load($xmlFile, [System.Xml.Linq.LoadOptions]::None)
        return $xDoc
    }
    catch {
        Write-Host "Unable to read taxonomy xml. Exception:" $_.Exception.Message -ForegroundColor Red
    }
}

 
$SiteURL = "https://" + $tenant + ".sharepoint.com/sites/cms-marketplace"

$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
Connect-PnPOnline -Url $SiteURL -Credentials $tenantAdmin -ErrorAction Stop

$files = Get-PnPFolderItem -FolderSiteRelativeUrl "Shared Documents/ResourceFiles"
foreach ($File in $Files) { 
    $filePath = "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\" + $File.Name 
    Get-PnPFile -Url $File.ServerRelativeUrl -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY -FileName $File.Name -AsFile
    
    $xdocument = Get-Resx($filePath)
 
    Write-Host "File Updation Started "+$filePath -ForegroundColor Green

    Import-Csv -Path $PSScriptRoot\resources\Translations.csv | ForEach-Object {
        foreach ($entry in $xdocument.Descendants("value")) {
            if ($entry.Value -eq $_.English) {
                $entry.Value = $_.Arabic
                $xdocument.Save($filePath);
            }
        }
    }

    Add-PnPFile -Path $filePath -Folder "Shared Documents/ResourceFiles" 

    

}  
write-host $SiteURL
Write-Host "Files Updated Successfully" -ForegroundColor Green  
