

$global:buildQueueVariable = ""
$global:buildSeparator = ";"

Function AppendQueueVariable([string]$folderName) {
	$folderNameWithSeparator = -join ($folderName, $global:buildSeparator)

	if ($global:buildQueueVariable -notmatch $folderNameWithSeparator) {
		$global:buildQueueVariable = -join ($global:buildQueueVariable, $folderNameWithSeparator)
	}
}

if ($env:BUILDQUEUEINIT) {
	Write-Host "Build Queue Init: $env:BUILDQUEUEINIT"
	Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$env:BUILDQUEUEINIT"
	exit 0
}

# Get all files that were changed
$editedFiles = git diff origin/master... --name-only

# Check each file that was changed and add that Service to Build Queue
$editedFiles | ForEach-Object {
	Switch -Wildcard ($_ ) {
		"marketplace/marketplace/*" {
			Write-Host "Marketplace changed"
			AppendQueueVariable "marketPlace"
		}
		"marketplace/news/*" {
			Write-Host "news changed"
			AppendQueueVariable "news"
		}
		"marketplace/aboutTasmu/*" {
			Write-Host "about changed"
			AppendQueueVariable "about"
		}
		"marketplace/my-account/*" {
			Write-Host "my account changed"
			AppendQueueVariable "myaccount"
		}
		"marketplace/productAndService/*" {
			Write-Host "productAndService changed"
			AppendQueueVariable "productAndService"
		}
		"marketplace/support/*" {
			Write-Host "support changed"
			AppendQueueVariable "support"
		}
		"adminportal/*" {
			Write-Host "Admin portal changed"
			AppendQueueVariable "adminportal"
		}
		"powerbiembed/*" {
			Write-Host "Power Bi embed app changed"
			AppendQueueVariable "powerbiembed"
		}
		"marketplace/common-ui/*" {
			Write-Host "common ui changed"
			AppendQueueVariable "commonui"
		}
		"marketplace/eservices/*" {
			Write-Host "Eservices changed"
			AppendQueueVariable "eservices"
		}
		"marketplace/account/*" {
			Write-Host "Account changed"
			AppendQueueVariable "accountportal"
		}
		"authorizecard/*" {
			Write-Host "Authorize card changed"
			AppendQueueVariable "authorizecard"
		}
		# The rest of your path filters
	}
}

Write-Host "Build Queue: $global:buildQueueVariable"
Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$global:buildQueueVariable"