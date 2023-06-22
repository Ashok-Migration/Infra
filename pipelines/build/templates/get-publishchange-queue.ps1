

$global:buildQueueVariable = ""
$global:buildSeparator = ";"

Function AppendQueueVariable([string]$folderName)
{
	$folderNameWithSeparator = -join($folderName, $global:buildSeparator)

	if ($global:buildQueueVariable -notmatch $folderNameWithSeparator)
	{
        $global:buildQueueVariable = -join($global:buildQueueVariable, $folderNameWithSeparator)
	}
}

if ($env:BUILDQUEUEINIT)
{
	Write-Host "Build Queue Init: $env:BUILDQUEUEINIT"
	Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$env:BUILDQUEUEINIT"
	exit 0
}

# Get all files that were changed
$editedFiles = git diff HEAD HEAD~ --name-only

# Check each file that was changed and add that Service to Build Queue
$editedFiles | ForEach-Object {
    Switch -Wildcard ($_ ) {
        "marketplace/news/projects/tasmu-news/package.json" {
			Write-Host "news changed"
			AppendQueueVariable "news"
		}
		"marketplace/aboutTasmu/projects/tasmu-about/package.json" {
			Write-Host "about changed"
			AppendQueueVariable "about"
		}
		"marketplace/productAndService/projects/products-and-services/package.json" {
			Write-Host "productAndService changed"
			AppendQueueVariable "productAndService"
		}
		"marketplace/support/projects/tasmu-support/package.json" {
			Write-Host "support changed"
			AppendQueueVariable "support"
		}
		"marketplace/common-ui/projects/tasmu-common-ui/package.json" {
			Write-Host "common ui changed"
			AppendQueueVariable "commonui"
		}
		"marketplace/my-account/projects/tasmu-myaccount/package.json" {
			Write-Host "my account changed"
			AppendQueueVariable "myaccount"
		}
    }
}

Write-Host "Build Queue: $global:buildQueueVariable"
Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$global:buildQueueVariable"