#Requires -Version 5.1
#Requires -Module Az.Resources
#Requires -Module Az.Storage
#Requires -Module Az.Network
#Requires -Module Az.Compute



Param(
    [string] $ResourceGroupLocation = 'westeurope',
    [string] $ResourceGroupName = 'DeployArcGIS',
    [switch] $UploadArtifacts,
    [string] $StorageAccountName,
    [string] $StorageContainerName = ($ResourceGroupName.ToLowerInvariant() -replace '[^a-zA-Z0-9]', '') + '-stageartifacts',
    [string] $TemplateFile = 'deploy.json',
    [string] $TemplateParametersFile = 'deploy.parameters.json',
    [string] $TemplateFileTemp = 'azuredeploytemp.json',
    [string] $ArtifactStagingDirectory = '.',
    [string] $DSCSourceFolder = 'DSC',
    [switch] $ValidateOnly,
    [switch] $DebugMode
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(' ','_'), '3.0.0')
} catch { }

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

$DebugLevel =  if($DebugMode){ "All" }else{ "None" }

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
Write-Host "Using template file:  $TemplateFile"
Write-Host "Using template parameters file:  $TemplateParametersFile"

if ($UploadArtifacts) {
    # Convert relative paths to absolute paths if needed
    $ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))
    $DSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $DSCSourceFolder))
    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    }
	
    $ArtifactsLocationName = '_artifactsLocation'
    $ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
    $OptionalParameters[$ArtifactsLocationName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    $OptionalParameters[$ArtifactsLocationSasTokenName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    $ServerContext = $JsonParameters | Select-Object -Expand 'serverContext' -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore

    Write-Host "start creating dsc configuration archive"
     # Create DSC configuration archive
    if (Test-Path $DSCSourceFolder) {
		$DSCSourceFilePaths = @(Get-ChildItem $DSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process {$_.FullName})
        foreach ($DSCSourceFilePath in $DSCSourceFilePaths) {
            $DSCArchiveFilePath = $DSCSourceFilePath.Substring(0, $DSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzVMDscConfiguration $DSCSourceFilePath -OutputArchivePath $DSCArchiveFilePath -Force -Verbose
        }
    }
    Write-Host "resource group name: $ResourceGroupName"
    Write-Host "storage account name: $StorageAccountName"
    $StorageAccount = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)
    if ($StorageAccount -eq $null) 
    {
         Write-Host "Storage account is not created...."

    }
   

    # Generate the value for artifacts location if it is not provided in the parameter file
    if ($OptionalParameters[$ArtifactsLocationName] -eq $null) {
        $OptionalParameters[$ArtifactsLocationName] = $StorageAccount.Context.BlobEndPoint + $StorageContainerName
    }

    Write-Host "optional param artifacts location: "$OptionalParameters[$ArtifactsLocationName]

    Write-Host "Copy files from the local storage staging location to the storage account container"
    # Copy files from the local storage staging location to the storage account container
    New-AzStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1

    $ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_.FullName}
    foreach ($SourcePath in $ArtifactFilePaths) {
		Set-AzStorageBlobContent -File $SourcePath -Blob $SourcePath.Substring($ArtifactStagingDirectory.length + 1) `
            -Container $StorageContainerName -Context $StorageAccount.Context -Force
    }
    Write-Host "Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file"
    # Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
    if ($OptionalParameters[$ArtifactsLocationSasTokenName] -eq $null) {
        $OptionalParameters[$ArtifactsLocationSasTokenName] = ConvertTo-SecureString -AsPlainText -Force `
            (New-AzStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }

    Write-Host "optional param artifacts location: "$OptionalParameters[$ArtifactsLocationSasTokenName]
}
$ddate = (Get-Date).tostring("yyyyMMddhhmmss")
Write-Host "Deployment started"
$DebugLevel =  if($DebugMode){ "All" }else{ "None" }
New-AzResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + $ddate) `
                                    -ResourceGroupName $ResourceGroupName `
                                    -TemplateFile $TemplateFile `
                                    -TemplateParameterFile $TemplateParametersFile `
                                    @OptionalParameters `
                                    -Force -Verbose `
                                    -ErrorVariable ErrorMessages `
                                    -DeploymentDebugLogLevel $DebugLevel

if ($ErrorMessages) {
    $err = ""
    @($ErrorMessages) | ForEach-Object { $err += $_.Exception.Message }
    Write-Error "Template deployment returned the following errors: $err"
}

