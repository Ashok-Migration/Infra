[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$searchServiceName,
	[Parameter(Mandatory = $true)]
	[string]$resourceGroupName,
	[Parameter(Mandatory = $true)]
	[string]$storageResourceGroup,
	[Parameter(Mandatory = $true)]
	[string]$storageAccountName,
	[Parameter(Mandatory = $true)]
	[string]$schemaFile,
	[Parameter(Mandatory = $true)]
	[string]$url
)

$storageAccount = Get-AzureRmStorageAccount -StorageAccountName $storageAccountName -ResourceGroupName $storageResourceGroup
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageResourceGroup -Name $storageAccountName)[0].Value

$searchApiKey = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $resourceGroupName -ServiceName $searchServiceName
$body = $(get-content $schemaFile) | ConvertFrom-JSON
$body.credentials.connectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageAccountName + ';AccountKey=' + $storageAccountKey + ';EndpointSuffix=core.windows.net' 

$headers = @{
'api-key' = $searchApiKey.Primary
'Content-Type' = 'application/json' 
'Accept' = 'application/json' }
$jsonBody = $body | ConvertTo-Json
Invoke-RestMethod -TimeoutSec 10000 -Uri $url -Method Put -Headers $headers -Body $jsonBody
