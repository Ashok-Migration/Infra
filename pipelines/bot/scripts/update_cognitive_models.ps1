#Requires -Version 6

Param(
    [switch] $RemoteToLocal,
    [switch] $useGov,
    [string] $luisAuthoringRegion,
    [string] $dispatchLuisAppId,
    [string] $generalluisAppId,    
    [string] $faqQnAKbId,
    [string] $chitchatQnAKbId,
    [string] $luisAuthoringKey,
	[string] $luisAccountName,
    [string] $luisAccountRegion,
	[string] $luisSubscriptionKey,
    [string] $luisEndpoint,
	[string] $resourceGroup,
    [string] $qnaSubscriptionKey,
    [switch] $useLuisGen,
    [string] $configFile,
    [string] $dispatchFolder = $(Join-Path $PSScriptRoot '..' 'Resources' 'Dispatch'),
    [string] $luisFolder,
	[string] $qnaEndpoint = "https://westus.api.cognitive.microsoft.com/qnamaker/v4.0",
    [string] $qnaFolder = $(Join-Path $PSScriptRoot '..' 'Resources' 'QnA'),
    [string] $lgOutFolder = $(Join-Path (Get-Location) 'Services'),
    [string] $logFile = $(Join-Path (Get-Location) "update_cognitive_models_log.txt"),
    [string[]] $excludedKbFromDispatch = @("Chitchat")
)

. $PSScriptRoot\luis_functionsorg.ps1
. $PSScriptRoot\qna_functions.ps1

# Reset log file
if (Test-Path $logFile) {
    Clear-Content $logFile -Force | Out-Null
}
else {
    New-Item -Path $logFile | Out-Null
}

# Check for AZ CLI and confirm version
if (Get-Command az -ErrorAction SilentlyContinue) {
    $azcliversionoutput = az -v
    [regex]$regex = '(\d{1,3}.\d{1,3}.\d{1,3})'
    [version]$azcliversion = $regex.Match($azcliversionoutput[0]).value
    [version]$minversion = '2.2.0'

    if ($azcliversion -ge $minversion) {
        $azclipassmessage = "AZ CLI passes minimum version. Current version is $azcliversion"
        Write-Debug $azclipassmessage
        $azclipassmessage | Out-File -Append -FilePath $logfile
    }
    else {
        $azcliwarnmessage = "You are using an older version of the AZ CLI, `
    please ensure you are using version $minversion or newer. `
    The most recent version can be found here: http://aka.ms/installazurecliwindows"
        Write-Warning $azcliwarnmessage
        $azcliwarnmessage | Out-File -Append -FilePath $logfile
    }
}
else {
    $azclierrormessage = 'AZ CLI not found. Please install latest version.'
    Write-Error $azclierrormessage
    $azclierrormessage | Out-File -Append -FilePath $logfile
}

if ($useGov) {
    $cloud = 'us'
}
else {
    $cloud = 'com'
}

Write-Host "> luis key ... $luisAuthoringKey"
Write-Host "> Getting config file ..." -NoNewline
$languageMap = @{ }
$config = Get-Content -Encoding utf8 -Raw -Path $configFile | ConvertFrom-Json
$config.cognitiveModels.PSObject.Properties | Foreach-Object { $languageMap[$_.Name] = $_.Value }
Write-Host "Done." -ForegroundColor Green

foreach ($langCode in $languageMap.Keys) {
    $models = $languageMap[$langCode]

        # Update each luis model based on local LU files
        foreach ($luisApp in $models.languageModels) {
            $lu = Get-Item -Path $(Join-Path $luisFolder $langCode "$($luisApp.id).lu")
            UpdateLUIS `
                -luFile $lu `
                -appId $luisApp.appid `
                -endpoint $luisEndpoint `
                -subscriptionKey $luisAuthoringKey `
                -culture $langCode `
                -version $luisApp.version `
                -log $logFile `
                -appName $luisApp.name

             if ($useLuisGen) {
                Write-Host "> Running LuisGen for $($luisApp.id) app ..." -NoNewline
                $luPath = $(Join-Path $luisFolder $langCode "$($luisApp.id).lu")
                RunLuisGen `
                    -luFile $(Get-Item $luPath) `
                    -outName "$($luisApp.id)" `
                    -outFolder $lgOutFolder `
                    -log $logFile
                Write-Host "Done." -ForegroundColor Green
            }
        }
}

Write-Host "> Update complete." -ForegroundColor Green