

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
$editedFiles = git diff HEAD HEAD~ --name-only

# Check each file that was changed and add that Service to Build Queue
$editedFiles | ForEach-Object {
	Switch -Wildcard ($_ ) {
		"src/services/Reference/*" {
			Write-Host "Reference changed"
			AppendQueueVariable "Reference"
		}
		"src/services/BOT/*" {
			Write-Host "BOT changed"
			AppendQueueVariable "MCSTASMUBot"
		}
		"src/services/Mcs.TASMU.CMS.Api/*" {
			Write-Host "cmscontentapi changed"
			AppendQueueVariable "cmscontentapi"
		}
		"src/services/Mcs.TASMU.CMS.Documents.Api/*" {
			Write-Host "cmsdocumentsapi changed"
			AppendQueueVariable "cmsdocumentsapi"
		}
		"src/services/Mcs.TASMU.CMS.MediaAssets.Api/*" {
			Write-Host "cmsmediaassetsapi changed"
			AppendQueueVariable "cmsmediaassetsapi"
		}
		"src/services/Mcs.Tasmu.KnowledgebaseArticle.Api/*" {
			Write-Host "Mcs.Tasmu.KnowledgebaseArticle.Api changed"
			AppendQueueVariable "KnowledgebaseArticle"
		}
		"src/services/Case/*" {
			Write-Host "Case changed"
			AppendQueueVariable "Case"
		}
		"src/services/FieldService/*" {
			Write-Host "FieldService changed"
			AppendQueueVariable "FieldService"
		}
		"src/services/Mcs.Tasmu.OrganisationProfile.Api/*" {
			Write-Host "OrganisationProfile changed"
			AppendQueueVariable "OrganisationProfile"
		}
		"src/services/Mcs.Tasmu.Profile.Api/*" {
			Write-Host "Profile changed"
			AppendQueueVariable "Profile"
		}		
		"src/services/Mcs.Tasmu.MarketplaceCatalogue.Api/*" {
			Write-Host "MarketplaceCatalogue changed"
			AppendQueueVariable "MarketplaceCatalogue"
		}
		"src/services/Mcs.Tasmu.Demographic.Api/*" {
			Write-Host "Demographic changed"
			AppendQueueVariable "Demographic"
		}
		"src/services/Mcs.Tasmu.Config.Api/*" {
			Write-Host "Config changed"
			AppendQueueVariable "Config"
		}
		"src/services/Notification/*" {
			Write-Host "Notification changed"
			AppendQueueVariable "Notification"
		}
		"src/services/SmsPublisher/*" {
			Write-Host "SmsPublisher changed"
			AppendQueueVariable "SmsPublisher"
		}
		"src/services/SmsProvider/*" {
			Write-Host "SmsProvider changed"
			AppendQueueVariable "SmsProvider"
		}
		"src/functions/Notification/*" { 
			Write-Host "Notification Function changed" 
			AppendQueueVariable "NotificationFunction"
		}
		"src/functions/SmartParking/*" { 
			Write-Host "SmartParking Function changed" 
			AppendQueueVariable "SmartParkingFunction"
		}		
		"src/functions/AzureSearch/*" { 
			Write-Host "AzureSearch Function changed" 
			AppendQueueVariable "AzureSearchFunction"
		}
		"src/services/Smartparking/*" { 
			Write-Host "Smartparking changed" 
			AppendQueueVariable "Smartparking"
		}
		"src/services/Mcs.Tasmu.PaymentGW.Api/*" { 
			Write-Host "PaymentGW changed" 
			AppendQueueVariable "PaymentGW"
		}
		"src/services/Mcs.Tasmu.Otp.Api/*" { 
			Write-Host "Otp changed" 
			AppendQueueVariable "otp"
		}
		"src/services/NotificationTemplate/*" { 
			Write-Host "NotificationTemplate changed" 
			AppendQueueVariable "NotificationTemplate"
		}
		"src/functions/QnAMakerSync/*" { 
			Write-Host "QnAMakerSync changed" 
			AppendQueueVariable "QnAMakerSync"
		}
		"src/consolejob/EventGridPublisher/*" { 
			Write-Host "EventGridPublisher changed" 
			AppendQueueVariable "EventGridPublisher"
		}
		"src/functions/File/*" { 
			Write-Host "File Function changed" 
			AppendQueueVariable "FileFunction"
		}	
		"src/functions/FieldService/*" { 
			Write-Host "Field Function changed" 
			AppendQueueVariable "FieldFunction"
		}
		"src/functions/ManageEvent/*" { 
			Write-Host "Manage Event Function changed" 
			AppendQueueVariable "ManageEventFunction"
		}
		"src/functions/PaymentPreferenceFunction/*" { 
			Write-Host "PaymentPreferenceFunction changed" 
			AppendQueueVariable "PaymentFunction"
		}
		"src/functions/ReconcileRefundFunction/*" { 
			Write-Host "ReconcileRefundFunction changed" 
			AppendQueueVariable "ReconcileRefundFunction"
		}
		"src/functions/CkanResourceCreationFunction/*" { 
			Write-Host "CkanResourceCreationFunction changed" 
			AppendQueueVariable "CkanResourceCreationFunction"
		}
		"src/functions/BlobEventCreator/*" { 
			Write-Host "BlobEventCreator changed" 
			AppendQueueVariable "BlobEventCreator"
		}
		"src/functions/SharePointNotify/*" { 
			Write-Host "SharePointNotify changed" 
			AppendQueueVariable "SharePointNotify"
		}
		"src/functions/BusinessProcess/*" { 
			Write-Host "BusinessProcess changed" 
			AppendQueueVariable "BusinessProcess"
		}
		"src/functions/Profile/*" { 
			Write-Host "ProfileFunction changed" 
			AppendQueueVariable "ProfileFunction"
		}
		"src/services/Mcs.Tasmu.Subscriptions.Api/*" { 
			Write-Host "Subscriptions changed" 
			AppendQueueVariable "Subscriptions"
		}
		"src/functions/Captcha/*" { 
			Write-Host "CaptchaFunction changed" 
			AppendQueueVariable "CaptchaFunction"
		}
		# The rest of your path filters
	}
}

Write-Host "Build Queue: $global:buildQueueVariable"
Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$global:buildQueueVariable"