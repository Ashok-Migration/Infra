[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$searchServiceName,
	[Parameter(Mandatory = $true)]
	[string]$resourceGroupName,
	[Parameter(Mandatory = $true)]
	[string]$schemaFile,
	[Parameter(Mandatory = $true)]
	[string]$url
)

$searchApiKey = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $resourceGroupName -ServiceName $searchServiceName


$headers = @{
'api-key' = $searchApiKey.Primary
'Content-Type' = 'application/json' 
'Accept' = 'application/json' }

Invoke-RestMethod -TimeoutSec 10000 -Uri $url -Method Put -Headers $headers -Body "$(get-content $schemaFile)"
