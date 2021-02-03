$XMLfile = $PSScriptRoot + '\resources\ResourceFileTranslation\TASMU CMS.ar-SA.resx'
 
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
 
$xdocument = Get-Resx($XMLfile)
 
Write-Host "File Updation Started for "+$XMLfile -ForegroundColor Green

Import-Csv -Path $PSScriptRoot\resources\ResourceFileTranslation\Translations.csv | ForEach-Object {
    foreach ($entry in $xdocument.Descendants("value"))
    {
        if ($entry.Value -eq $_.English) {
            Write-Host "Match Found"
            $entry.Value = $_.Arabic
            $xdocument.Save($XMLfile);
        }
    }
}

Write-Host "File Updated Successfully" -ForegroundColor Green