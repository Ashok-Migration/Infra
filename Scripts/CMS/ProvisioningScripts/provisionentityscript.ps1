<#
.DESCRIPTION
    This Script is for Intiating scripts execution from Azure Build Pipeline for provisioning Entities for each Sector

.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    scope                   - This is the scope for Search Configuration of the tenant which will be used for running the script, example, Subscription
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Entity sites and provisions other components as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : provisionentityscript.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
28/12/2020  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
	$tenant,
    $TemplateParametersFile,
    $sp_user,
    $sp_password,
    $scope,
    $InstrumentationKey
)

Write-host "Started provisioning entities on " $tenant -ForegroundColor Yellow

Import-PackageProvider -Name "NuGet" -RequiredVersion "3.0.0.1" -Force
Install-Module SharePointPnPPowerShellOnline -Force -Verbose -Scope CurrentUser

$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
 
    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    }

    $RoleName = $JsonParameters.RoleName.value
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    $client.InstrumentationKey = $InstrumentationKey 
    if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
        $client.Context.Cloud.RoleName = $RoleName
    }
function Create-NewSiteCollection() {
    
    $filePath = $PSScriptRoot + '\resources\Entities.xml'
    $tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
    $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"

    [xml]$sitefile = Get-Content -Path $filePath
    ProvisionSiteCollections $sitefile

    Write-host "Completed" -ForegroundColor Green
    $client.TrackEvent("Completed.")
}

#region --Site collection Creation--
function ProvisionSiteCollections($sitefile) {
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
     
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin

    foreach ($globalhubsite in $sitefile.sites.globalhubsite.site) {
        foreach ($sectorhubsite in $globalhubsite.sectorhubsite.site) {
            $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
            $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue

            if ([bool] ($siteExits) -eq $false) {
                Write-Host "Sector $sectorhubSiteUrl not found" -ForegroundColor Red
                $client.TrackEvent("Sector $sectorhubSiteUrl not found")
            }
            else {
                #Entity provisioning 
                foreach ($entityassociatedsite in $sectorhubsite.entityassociatedsite.site) {
                    $entitySiteUrl = $urlprefix + $entityassociatedsite.Alias
              
                    Create-SiteCollection $entityassociatedsite.Type $entityassociatedsite.Title $entityassociatedsite.Alias $entitySiteUrl
                                     
                }
            }
        
        }
    }  
       
    Disconnect-PnPOnline
}

function Create-SiteCollection($Type, $Title, $Alias, $entitySiteUrl) {
    try {
        $siteExits = Get-PnPTenantSite -Url $entitySiteUrl -ErrorAction SilentlyContinue
        
        #Check for existence of Site 
        if ([bool] ($siteExits) -eq $false) {
            #Create new site if site collection does not exist      
            
            try {
                Write-Host "Site collection not found ,so creating a new $entitySiteUrl ....."
                $client.TrackEvent("Site collection not found ,so creating a new $entitySiteUrl .....")
            
                New-PnPSite -Type $Type -Title $Title -Url $entitySiteUrl -SiteDesign Blank
                $client.TrackEvent("Site collection created.. $entitySiteUrl") 
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Host $ErrorMessage -foreground Yellow

                $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                $telemtryException.Exception = $_.Exception.Message  
                $client.TrackException($telemtryException)
            }
        }
        else {
            Write-Host "Site Collection- $siteTitle already exists"
            $client.TrackEvent("Site Collection- $siteTitle already exists")
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    } 
}
  
#region To check if all Content type exists in Global site 

function checkContentTypeExists() {
    Write-host "Check if Content Type Exists started..." -ForegroundColor Green
    $filePath = $PSScriptRoot + '.\resources\Entities.xml'

    [xml]$sitefile = Get-Content -Path $filePath
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr 

    $urlprefix = "https://" + $tenant + ".sharepoint.com/sites/"
    
    $isContentTypeAvailable = $true
    foreach ($site in $sitefile.sites.globalhubsite.site.sectorhubsite.site) {
        foreach ($entity in $site.entityassociatedsite.site) {
            $entitysite = $entity.alias    
            $entitySiteUrl = $urlprefix + $entitysite
            Connect-PnPOnline -Url $entitySiteUrl -Credentials $tenantAdmin
            $connection = Get-PnPConnection
            
            foreach ($itemList in $sitefile.sites.entitySPList.ListAndContentTypes) {
                $ListBase = Get-PnPContentType -Identity $itemList.ContentTypeName -ErrorAction SilentlyContinue -Connection $connection
                if ($ListBase -eq $null) {
                    $isContentTypeAvailable = $false
                    Write-host $itemList.ContentTypeName "not available in" $entitySiteUrl -ForegroundColor Yellow
                }
            }
            Disconnect-PnPOnline  
        }
    }
    Write-host "Check if Content Type Exists completed..." -ForegroundColor Green
    return $isContentTypeAvailable
}

function ProvisionSiteComponents 
{
    $filePath = $PSScriptRoot + '\resources\Entities.xml'
    [xml]$sitefile = Get-Content -Path $filePath
    $tenantUrl = "https://" + $tenant + "-admin.sharepoint.com/"
	$urlprefix = "https://"+$tenant+".sharepoint.com/sites/"

	$secstr = New-Object -TypeName System.Security.SecureString
	$sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}

	$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
	# Connect with the tenant admin credentials to the tenant
	Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
	$connection = Get-PnPConnection

	foreach($globalconfigsite in $sitefile.sites.Configsite.site)
	{
		$globalconfigSiteUrl = $urlprefix + $globalconfigsite.Alias
		$siteExits = Get-PnPTenantSite -Url $globalconfigSiteUrl -ErrorAction SilentlyContinue

		if ([bool] ($siteExits) -eq $true) {  
			AddCustomQuickLaunchNavigationGlobal $globalconfigSiteUrl $sitefile.sites.globalConfigNav
		}
	}

	Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
	$connection = Get-PnPConnection
	foreach($globalhubsite in $sitefile.sites.globalhubsite.site)
	 {

		$globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
		$siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
			
		if ([bool] ($siteExits) -eq $true) {
			AddCustomQuickLaunchNavigationGlobal $globalhubSiteUrl $sitefile.sites.globalNav
		}
				
		foreach($sectorhubsite in $globalhubsite.sectorhubsite.site)
		{
			Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
			$connection = Get-PnPConnection

		   $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
				   
		   $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
		   
		   if ([bool] ($siteExits) -eq $true) {
			   
			   AddCustomQuickLaunchNavigationSector $sectorhubSiteUrl $sitefile.sites.sectorNav.QuickLaunchNav
			   AddCustomTopNavigationSector $sectorhubSiteUrl $sitefile.sites.sectorNav.TopNav
		   } 
	   
		    #Entity provisioning   
		   foreach($entityassociatedsite in $sectorhubsite.entityassociatedsite.site)
		    {
				Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
	$connection = Get-PnPConnection

		       $entitySiteUrl = $urlprefix + $entityassociatedsite.Alias
				   
		       $siteExits = Get-PnPTenantSite -Url $entitySiteUrl -ErrorAction SilentlyContinue
					
		       if ([bool] ($siteExits) -eq $true) {
				   
		           #Register the created Team Site as Associated Site for SectorHubSite
		           Add-PnPHubSiteAssociation -Site $entitySiteUrl -HubSite $sectorhubSiteUrl

		           EnableMegaMenu $entitySiteUrl
		           ListandLibrary $entitySiteUrl $sitefile.sites.entitySPList
		           CreateNewGroupAddUsers $entitySiteUrl $sitefile.sites.entitySPGroup $entityassociatedsite.Title
		           AddUsersToDefaultSPGroup $entitySiteUrl $sitefile.sites.entitySPGroup $entityassociatedsite.Title
				   AddCustomQuickLaunchNavigationEntity $entitySiteUrl $sitefile.sites.entityNav.QuickLaunchNav
				   UpdateTopNavForExistingSectors $sectorhubsite.Title $sitefile.sites.sectorNav.TopNav $entityassociatedsite.Alias $entityassociatedsite.Title
		           ApplyTheme $sitefile.sites.entitytheme.Name $entitySiteUrl $tenantAdmin $tenantUrl
									
		           CreateModernPage $entitySiteUrl $sitefile.sites.entityPageWebpart
		           AddWebpartToPage $entitySiteUrl $sitefile.sites.entityPageWebpart
					 $webpartkeyHeight = 1
				   UpdateListViewWebPartProperties $sitefile.sites.entityPageWebpart.page.name $webpartkeyHeight
				   UpdateRegionalSettings $entitySiteUrl $tenantAdmin
		           #UploadFiles $entitySiteUrl $sitefile.sites.entityUploadFiles
		           Update-SiteColumns $entitySiteUrl $sitefile.sites.updateSiteColumns.entityChange $tenantAdmin
		           UpdateViewForTasksList 'My Tasks' $entitySiteUrl
				   
		           #Check and add the app catalog             
		           CheckAndCreateAppCatalog $entitySiteUrl             
		           #Check and add the spfx webpart   
		           $appName = "sector-custom-style-client-side-solution"          
		           AddSPFxWebPart $entitySiteUrl $tenantAdmin $appName

		           #Uncomment and run below line on new site creation only, else keep commented
		           AddEntryInConfigurationListForEntitySite $globalconfigSiteUrl $entitySiteUrl $sitefile.sites.entityAddItemConfigurationList.item $entityassociatedsite.Title
				   
		       }               
		     }          

		  }
	 }

	Disconnect-PnPOnline   
}

function UpdateTopNavForExistingSectors($sectorhubsiteTitle,$topNav,$entityUrl,$entityTitle)
{
	foreach ($level1 in $topNav.Level1) {

		foreach ($level2 in $level1.Level2) {
			if($level2.nodeName -eq $sectorhubsiteTitle)
			{
			 continue
			}
		   
		   $sectorUrl='https://'+$tenant + '.sharepoint.com/sites/'+$level2.url
		   Write-Host 'Updating top navigation of '$sectorUrl
		   Connect-PnPOnline -Url $sectorUrl -Credentials $tenantAdmin
		
			$rootNavNode=Get-PnPNavigationNode -Location TopNavigationBar | Where-Object {$_.Title -eq $level1.nodeName}
			if($null -ne $rootNavNode)
		 {
			$TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id
	 
			$child=$TopNav.Children | Where-Object {$_.Title -eq $sectorhubsiteTitle}
					 
			if($null -ne $child)
				{
				  $level3currentURL=$urlprefix+$entityUrl
				  $navNode=AddPnPNavigationNode $entityTitle $level3currentURL $child.Id
	
				  $client.TrackEvent("Navigation node created, $level3.nodeName") 
			
		 }}
		
		
		   Disconnect-PnPOnline 
		   }	
	}
    
}

function AddCustomTopNavigationSector($url, $nodeLevel)
{
  try
   {
     $client.TrackEvent("Configure Custom Navigation, Started.")
    Write-Host 'Updating top navigation for '$url -foreground Green
     $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
	 
	 
     foreach($level1 in $nodeLevel.Level1){
	
		$rootNavNode=Get-PnPNavigationNode -Location TopNavigationBar | Where-Object {$_.Title -eq $level1.nodeName}
	    if($null -ne $rootNavNode)
     {
		$TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id
      foreach($level2 in $level1.Level2){
 
			$child=$TopNav.Children | Where-Object {$_.Title -eq $level2.nodeName}
				 
			if($null -ne $child)
			{
         	 foreach($level3 in $level2.Level3){
              $level3url=$level3.url
              $level3currentURL=$urlprefix+$level3url
              $navNode=AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id

              $client.TrackEvent("Navigation node created, $level3.nodeName") 
        
	 }}}}
    
    }
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
    Disconnect-PnPOnline
}

function AddEntryInConfigurationListForEntitySite($globalconfigSiteUrl,$SiteUrl,$node,$value )
{
	try
	{
		Write-Host "Add Entry In Configuration List started for $SiteUrl....."
		$client.TrackEvent("Add Entry In Configuration List started for $SiteUrl...")

		$connection = Connect-PnPOnline -Url $globalconfigSiteUrl -Credentials $tenantAdmin

		$entityApprovers=$node.Approvers.Replace('Entity',$value)
		$entityTranslators=$node.Translators.Replace('Entity',$value)
		$reference=Add-PnPListItem -List $node.configListName -Values @{"SiteURL" = $SiteUrl;"SiteLevel" = $node.SiteLevel; "ListNames"=$node.ListNames; "Entity"=$value;"Approvers"=$entityApprovers;"Translators"=$entityTranslators}
	}
	catch
	{
	   $ErrorMessage = $_.Exception.Message
	   Write-Host $ErrorMessage -foreground Yellow

	   $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
	   $telemtryException.Exception = $_.Exception.Message  
	   $client.TrackException($telemtryException)
	}
}

function AddSPFxWebPart($siteUrl, $tenantAdmin, $appTitle){
	try{
		Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
		$tenantApps = Get-PnPApp -Scope Tenant
		if($tenantApps -ne $null){
			foreach($app in $tenantApps){
				if($app.Title -eq $appTitle){
					Install-PnPApp -Identity $app.Id
					Write-Host "App $appTitle deployed for the site $SiteUrl " 
				}
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage "Unable to install the app to the site $siteUrl. Check package path $path " -foreground Yellow
		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	}
}

function CheckAndCreateAppCatalog($siteUrl){     
	try{         
		Write-Host "Creating app catalog for the site url  $SiteUrl "             
		$reference=Add-SPOSiteCollectionAppCatalog -Site $siteUrl             
		Write-Host "App catalog for the site url  $SiteUrl is created "         
	}     
	catch{         
		$ErrorMessage = $_.Exception.Message         
		Write-Host $ErrorMessage "In Site $siteUrl " -foreground Yellow         
		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"        
		$telemtryException.Exception = $_.Exception.Message
		$client.TrackException($telemtryException)     
	} 
}

function UpdateView($url, $tenantAdmin, $viewName, $ListName) {
	try {
		#Setup the context
		Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
		Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
        
		$admin = $tenantAdmin.UserName
		$password = $tenantAdmin.Password
		$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
		$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($url)
		$Ctx.Credentials = $credentials
		$List = $Ctx.Web.Lists.GetByTitle($ListName)
		$View = $List.Views.GetByTitle($viewName)
		$Ctx.ExecuteQuery()
		if ($null -ne $View) {
			#Define the CAML Query
			$Query = "<OrderBy><FieldRef Name='Modified' Ascending='FALSE'/></OrderBy>"
			#Update the View
			$View.ViewQuery = $Query
			$View.Update()
			$Ctx.ExecuteQuery()
 
			Write-host "View Updated Successfully!" -f Green
		}
		else {
			Write-host "View '$ViewName' Doesn't exist in the List!"  -f Yellow
		}
	}
	catch {
		write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
	}
}

function UpdateViewForTasksList($listNameForView, $siteUrlNew)
{   
   try {
		$connection = Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin -ErrorAction Stop

		$allItemViewMyTasks = Get-PnPView -List $listNameForView -Identity 'All Items' -ErrorAction SilentlyContinue
		
		if ([bool]($allItemViewMyTasks) -eq $true) {
			 $PnPContext = Get-PnPContext
			 $allItemViewMyTasks.ViewQuery = "<Where><Eq><FieldRef Name='cmsAssignedToUser'/><Value Type='Integer'><UserID Type='Integer'/></Value></Eq></Where>"
			 $allItemViewMyTasks.Update()
			 $PnPContext.ExecuteQuery()
			 Write-Host "All Items - View updated for $listNameForView list."
			 $client.TrackEvent("All Items - View updated for $listNameForView list.")
		}
		else {
			Write-Host "View not found in List $listNameForViews site- $siteUrlNew "
			$client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")
		}

	   $HomeViewMyTasks = Get-PnPView -List $listNameForView -Identity 'Home' -ErrorAction SilentlyContinue

		if ([bool]($HomeViewMyTasks) -eq $true) {

			 $PnPContext = Get-PnPContext
			 $HomeViewMyTasks.ViewQuery = "<Where><Eq><FieldRef Name='cmsAssignedToUser'/><Value Type='Integer'><UserID Type='Integer'/></Value></Eq></Where>"
			 $HomeViewMyTasks.Update()
			 $PnPContext.ExecuteQuery()
			 Write-Host "Home - View updated for $listNameForView list."
			 $client.TrackEvent("Home - View updated for $listNameForView list.")
		}
		else {
			Write-Host "View already exists in List $listNameForView site- $siteUrlNew "
			$client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")
		}
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage "in Site $siteUrlNew  List $listNameForView " -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		DeleteListOnFailure $siteUrlNew $listNameForView
	}
	#Disconnect-PnPOnline
}

function DeletelistOnFailure($siteUrlNew, $listName)
{
	try
	{
		Write-Host "Clean up: Delete List on failure started for: $listName"
		$client.TrackEvent("Clean up: Delete List on failure started for: $listName") 

		#Connect to PNP Online
		Connect-PnPOnline -Url $siteUrlNew -Credential $tenantAdmin -ErrorAction Stop
		 
		#Check if List exists
		#$List = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
		#if($List -ne $Null)
		if(Get-PnPList -Identity $listName)
		{
			#sharepoint online powershell remove list
			Remove-PnPList -Identity $listName -Force -ErrorAction Stop
			Write-host "List '$listName' Deleted Successfully!"
			$client.TrackEvent("List '$listName' Deleted Successfully!, Site URL, $url")
		}
		else
		{
			Write-host -f Yellow "Could not find List '$listName'"
			$client.TrackEvent("Could not find List '$listName', Site URL, $url")
		}

		Write-Host "Clean up: Delete List on failure completed for: $listName"
		$client.TrackEvent("Clean up: Delete List on failure completed for: $listName")
	 }
	 catch
	 {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	 }
}

function Update-SiteColumns($url, $node, $tenantAdmin) {

	try {
		$context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
		$admin = $tenantAdmin.UserName
		$password = $tenantAdmin.Password
		$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
		$context.Credentials = $credentials
		$web = $context.Web
		$context.Load($web)
		$context.Load($web.Fields) 
		$context.Load($web.ContentTypes)
		$context.ExecuteQuery()

		foreach($objfield in $node.changeDateOnly){

			try
			{
				Write-Host "Update-SiteColumns, DateTime to Date for Content Type started for- "+ $objfield.ListName -foreground Green
				$client.TrackEvent("Update-SiteColumns, DateTime to Date for Content Type started for- "+ $objfield.ListName)           
				Connect-PnPOnline -Url $url -Credentials $tenantAdmin
            	$field = Get-PNPField -identity $objfield.ColumnInternalName -List $objfield.ListName
            	[xml]$schemaXml = $field.SchemaXml
            	$schemaXml.Field.Format=$objfield.DisplayFormat
            	$updateField = Set-PnPField -List $objfield.ListName  -Identity $objfield.ColumnInternalName -Values @{ SchemaXml = $schemaXml.OuterXml }
			}
			catch{
				$ErrorMessage = $_.Exception.Message
				Write-Host $ErrorMessage -foreground Yellow
	
				$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
				$telemtryException.Exception = $_.Exception.Message  
				$client.TrackException($telemtryException)
			}
		}

		foreach($objfield in $node.changeContentTierChoice){

		try
		{
			Write-Host "Update-SiteColumns, Choice value for Content Type started for- "+ $objfield.ListName -foreground Green
			$client.TrackEvent("Update-SiteColumns, Choice value for Content Type started for- "+ $objfield.ListName)           
			#Get the List
			$List = $context.Web.Lists.GetByTitle($objfield.ListName)
			$context.Load($List)
			$context.ExecuteQuery()
 
			#Get the field
			$Field = $List.Fields.GetByInternalNameOrTitle($objfield.ColumnInternalName)
			$context.Load($Field)
			$context.ExecuteQuery()
 
			#Cast the field to Choice Field
			$ChoiceField = New-Object Microsoft.SharePoint.Client.FieldMultiChoice($context, $Field.Path)
			$context.Load($ChoiceField)
			$context.ExecuteQuery()

			$Choices = $objfield.choicevalue.Split(",")
 
			#$choiceField.Choices.Clear()
			$ChoiceField.Choices = $Choices
			$ChoiceField.DefaultValue = $objfield.DefaultValue           
			$ChoiceField.UpdateAndPushChanges($True)
			$context.ExecuteQuery()
						   
		}
		catch{
			$ErrorMessage = $_.Exception.Message
			Write-Host $ErrorMessage -foreground Yellow

			$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
			$telemtryException.Exception = $_.Exception.Message  
			$client.TrackException($telemtryException)
		}
	  }

		Connect-PnPOnline -Url $url -Credentials $tenantAdmin

		#region Updating the change Title Fields
		foreach($item in $node.changeTitle){
			Write-Host "Update-SiteColumns, "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
			$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
			if([bool]($field) -eq $true){
				$field.Title = $item.NewTitle
				$field.Update()
				$field.Context.ExecuteQuery()
			}

		}
		#endregion

		#region Change the required value
		foreach($item in $node.changeRequiredField){
			try{
				Write-Host "Update-SiteColumns, "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
				$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
				if([bool]($field) -eq $true){
					if($item.Required -eq "True"){
						$field.Required = $true
					}
					else{
						$field.Required = $false
					}
					$field.Update()
					$field.Context.ExecuteQuery()
				}
			}
			catch{
				
			}
		}
		#endregion

		#region Hide columns
		foreach($item in $node.hideColumn){
			try{
				Write-Host "Update-SiteColumns, "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
				$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
				if([bool]($field) -eq $true){
					$field.Hidden = $true
					$field.Update()
					$field.Context.ExecuteQuery()
				}
			}
			catch{
				$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
				if([bool]($field) -eq $true){
					$field.ReadOnlyField = $true
					$field.Update()
					$field.Context.ExecuteQuery()
				}
			}
		}
		#endregion

		#region Update multi select column
		<#foreach($item in $node.updateUserSelectionMode){
			try{
				Write-Host "Update-SiteColumns, "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
				$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
				if([bool]($field) -eq $true){
					$field.Required = $false
					$field.Update()
					$field.Context.ExecuteQuery()
				}
			}
			catch{
				
			}
		}#>
		#endregion

		#region Remove from edit form
		foreach($item in $node.removeFromEditForm){
			Write-Host "Update-SiteColumns, "$item.ColumnInternalName" for the list: "$item.ListName -foreground Green
			$field = Get-PnPField -List $item.ListName -Identity $item.ColumnInternalName
			if([bool]($field) -eq $true){
				$field.SetShowInEditForm($false)
				$field.SetShowInNewForm($false)
				$field.Update()
				$field.Context.ExecuteQuery()
			}
		}
		#endregion
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	}
}

function UpdateRegionalSettings($url, $tenantAdmin){
	try{
		#Load SharePoint CSOM Assemblies
		Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
		Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
  
		#Config parameters for SharePoint Online Site URL and Timezone description
		$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($url)
		$admin = $tenantAdmin.UserName
		$password = $tenantAdmin.Password
		$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
		$Ctx.Credentials = $credentials
		$Web = $Ctx.Web
		$regionalSettings = $Web.RegionalSettings
		$timezones = $Web.RegionalSettings.TimeZones
		$Ctx.Load($regionalSettings)
		$Ctx.Load($timezones)
		$Ctx.ExecuteQuery()
		$Web.RegionalSettings.LocaleId = 16385 # Arabic(Qatar)
		$Web.RegionalSettings.WorkDayStartHour = 480 # 8 AM
		$Web.RegionalSettings.WorkDayEndHour = 1020 # 5 PM
		$Web.RegionalSettings.FirstDayOfWeek = 0 # Sunday
		$Web.RegionalSettings.Time24 = $False
		$Web.RegionalSettings.CalendarType = 10 #Gregorian Arabic Calendar
		$Web.RegionalSettings.AlternateCalendarType = 0 #None
		$Web.RegionalSettings.WorkDays = 124
		$TimezoneName ="(UTC+03:00) Kuwait, Riyadh"
		$NewTimezone = $Timezones | Where {$_.Description -eq $TimezoneName}
		$Ctx.Web.RegionalSettings.TimeZone = $NewTimezone
		$Web.Update()
		$Ctx.ExecuteQuery()
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	}
}

function UpdateListViewWebPartProperties($page, $webpartkeyHeight){
	$wpList = Get-PnPClientSideComponent -Page $page
    foreach($wp in $wpList)
    {
        try{
			if($wp.Title -eq "List"){
				Write-Host "Webpart " $wp.InstanceId " PropertiesJson is : " $wp.PropertiesJson
				$prop = $wp.PropertiesJson
				$property = $prop | ConvertFrom-Json
				$property.webpartHeightKey = $webpartkeyHeight
				$prop = $property | ConvertTo-Json
				Write-Host "Updated PropertiesJson is " $prop
				Set-PnPClientSideWebPart -Page $page -Identity $wp.InstanceId -PropertiesJson $prop
			}
		}
		catch{
			$ErrorMessage = $_.Exception.Message
			Write-Host $ErrorMessage -foreground Yellow  

			$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
			$telemtryException.Exception = $_.Exception.Message  
			$client.TrackException($telemtryException)
		}
    }
}

function AddWebpartToPage($url, $nodeLevel)
{
	try {
		#Load SharePoint CSOM Assemblies
		Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
		Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
		$client.TrackEvent("Page creation & Webpart addition to page started.") 
		 
		Connect-PnPOnline -Url $url -Credentials $tenantAdmin -ErrorAction Stop

		$pagename=$nodeLevel.webpartSection.pagename
		$page = Get-PnPClientSidePage -Identity $pagename -ErrorAction Stop           
		
		if($page -ne $null)
		{
		Add-PnPClientSidePageSection -Page $page -SectionTemplate $nodeLevel.webpartSection.SectionTemplate -ErrorAction Stop

		#Write-host "Disabling Commnets on page:$Page"
		#Set-PnPClientSidePage -Identity $page -CommentsEnabled:$False

		
		foreach($webpartSection in $nodeLevel.webpartSection){
		
			  foreach($webpartSection in $webpartSection.webpart){
			 
				if($webpartSection.DefaultWebPartType -eq 'List'){
					Write-host "Updating the web part " $webpartSection.ListTitleDisplay
					$admin = $tenantAdmin.UserName
					$password = $tenantAdmin.Password
					$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
					$context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
					$context.Credentials = $credentials

						try {
						$web = $context.Web
						$list = $web.Lists.GetByTitle($webpartSection.ListTitle)
						$ListView = $list.views.GetByTitle($webpartSection.ViewName)                        
						$context.Load($list)
						$context.Load($ListView)
						$context.ExecuteQuery()
						}
						catch {
							Write-Host $_.Exception.Message -ForegroundColor Yellow
						}

					if($webpartSection.hideCommandBar -eq "True"){
						$jsonProperties = '{"selectedListId":"'+ $list.Id+ '","listTitle":"'+$webpartSection.ListTitleDisplay+'","webpartHeightKey":1,"hideCommandBar":true,"selectedViewId":"'+ $ListView.Id + '"}'
					}
					else{
						$jsonProperties = '{"selectedListId":"'+ $list.Id+ '","listTitle":"'+$webpartSection.ListTitleDisplay+'","webpartHeightKey":1,"hideCommandBar":false,"selectedViewId":"'+ $ListView.Id + '"}'
					}
					
					$listWebpart = Add-PnPClientSideWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -WebPartProperties $jsonProperties -ErrorAction Stop
					Write-Host "Webpart " $listWebpart.InstanceId " added successfully with properties " $listWebpart.PropertiesJson
					 #Set-PnPClientSideWebPart -Page $page -Identity $listWebpart.InstanceId -PropertiesJson $jsonProperties
				  }
				  
				  if($webpartSection.DefaultWebPartType -eq 'SiteActivity'){
					 Add-PnPClientSideWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -WebPartProperties @{"title"="Recent Activity"; maxItems="9"} -ErrorAction Stop
				  }

				  if($webpartSection.DefaultWebPartType -eq 'QuickLinks'){

						$item0Title=$webpartSection.items.item[0].Title
						$item0Url=$url+"/Lists/"+$webpartSection.items.item[0].ListUrl
						
						$item1Title=$webpartSection.items.item[1].Title
						$item1Url=$url+"/Lists/"+$webpartSection.items.item[1].ListUrl

						$item2Title=$webpartSection.items.item[2].Title
						$item2Url=$url+"/Lists/"+$webpartSection.items.item[2].ListUrl

						$item3Title=$webpartSection.items.item[3].Title
						$item3Url=$url+"/Lists/"+$webpartSection.items.item[3].ListUrl

						$item4Title=$webpartSection.items.item[4].Title
						$item4Url=$url+"/Lists/"+$webpartSection.items.item[4].ListUrl

						$item5Title=$webpartSection.items.item[5].Title
						$item5Url=$url+"/Lists/"+$webpartSection.items.item[5].ListUrl

						$item6Title=$webpartSection.items.item[6].Title
						$item6Url=$url+"/Lists/"+$webpartSection.items.item[6].ListUrl

						$item7Title=$webpartSection.items.item[7].Title
						$item7Url=$url+"/Lists/"+$webpartSection.items.item[7].ListUrl

						$item8Title=$webpartSection.items.item[8].Title
						$item8Url=$url+"/Lists/"+$webpartSection.items.item[8].ListUrl

						$item9Title=$webpartSection.items.item[9].Title
						$item9Url=$url+"/Lists/"+$webpartSection.items.item[9].ListUrl

						$item10Title=$webpartSection.items.item[10].Title
						$item10Url=$url+"/Lists/"+$webpartSection.items.item[10].ListUrl

$jsonProps = '
{"controlType":3,"id":"41d11bca-2e0b-47c8-a6e8-185a9d7c5dd9","position":{"zoneIndex":1,"sectionIndex":1,"controlIndex":1,"layoutIndex":1},"webPartId":"c70391ea-0b10-4ee9-b2b4-006d3fcad0cd","webPartData":{"id":"c70391ea-0b10-4ee9-b2b4-006d3fcad0cd","instanceId":"41d11bca-2e0b-47c8-a6e8-185a9d7c5dd9","title":"Quick links","description":"Add links to important documents and pages.","serverProcessedContent":{"htmlStrings":{},"searchablePlainTexts":{"title":"Quick Links","items[0].title":"'+$item0Title+'","items[1].title":"'+$item1Title+'","items[2].title":"'+$item2Title+'","items[3].title":"'+$item3Title+'","items[4].title":"'+$item4Title+'","items[5].title":"'+$item5Title+'","items[6].title":"'+$item6Title+'","items[7].title":"'+$item7Title+'","items[8].title":"'+$item8Title+'","items[9].title":"'+$item9Title+'","items[10].title":"'+$item10Title+'"},"imageSources":{},"links":{"baseUrl":"'+$url+'","items[0].sourceItem.url":"'+$item0Url+'","items[1].sourceItem.url":"'+$item1Url+'","items[2].sourceItem.url":"'+$item2Url+'","items[3].sourceItem.url":"'+$item3Url+'","items[4].sourceItem.url":"'+$item4Url+'","items[5].sourceItem.url":"'+$item5Url+'","items[6].sourceItem.url":"'+$item6Url+'","items[7].sourceItem.url":"'+$item7Url+'","items[8].sourceItem.url":"'+$item8Url+'","items[9].sourceItem.url":"'+$item9Url+'","items[10].sourceItem.url":"'+$item10Url+'"},"componentDependencies":{"layoutComponentId":"706e33c8-af37-4e7b-9d22-6e5694d92a6f"}},"dataVersion":"2.2","properties":{"items":[{"sourceItem":{"itemType":5,"fileExtension":"","progId":""},"thumbnailType":3,"id":11,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":10,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":9,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":8,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":7,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":6,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":5,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":4,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":3,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":2,"description":"","altText":""},{"sourceItem":{"itemType":4,"fileExtension":"","progId":""},"thumbnailType":3,"id":1,"description":"","altText":""}],"isMigrated":true,"layoutId":"List","shouldShowThumbnail":true,"imageWidth":100,"buttonLayoutOptions":{"showDescription":false,"buttonTreatment":2,"iconPositionType":2,"textAlignmentVertical":2,"textAlignmentHorizontal":2,"linesOfText":2},"listLayoutOptions":{"showDescription":false,"showIcon":false},"waffleLayoutOptions":{"iconSize":1,"onlyShowThumbnail":false},"hideWebPartWhenEmpty":true,"dataProviderId":"QuickLinks","webId":"93012ab1-1675-4c10-a48d-9318b877ab5e","siteId":"8051fa3b-1aeb-4793-8354-d5c2eb571b6d"}},"emphasis":{},"reservedHeight":270,"reservedWidth":744,"addedFromPersistedData":true}
'

					 #Add-PnPClientSideWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -WebPartProperties @{"title"="Quick Links";"isMigrated"=1;"layoutId"="CompactCard";"shouldShowThumbnail"=1;"buttonLayoutOptions"=@{"showDescription"=0;"buttonTreatment"=2;"iconPositionType"=2;"textAlignmentVertical"=2;"textAlignmentHorizontal"=2;"linesOfText"=2};"listLayoutOptions"=@{"showDescription"=0;"showIcon"=1};"waffleLayoutOptions"=@{"iconSize"=1;"onlyShowThumbnail"=0};"hideWebPartWhenEmpty"=1;"dataProviderId"="QuickLinks"} -ErrorAction Stop
					 Add-PnPClientSideWebPart -Page $page -DefaultWebPartType QuickLinks -WebPartProperties $jsonProps -Section $webpartSection.Section -Column $webpartSection.Column -Order 3
				  }

				  if($webpartSection.DefaultWebPartType -eq 'ContentRollup'){
					 Add-PnPClientSideWebPart -Page $page -DefaultWebPartType $webpartSection.DefaultWebPartType -Section $webpartSection.Section -Column $webpartSection.Column -Order 2 -WebPartProperties @{"title"="Recent documents"; "count"=5} -ErrorAction Stop

				  }
							   
				}

		}
		}
		else
			 {
				 Write-Host "Page does not exist or is not modern $webpart.pagename"
				 $client.TrackEvent("Page does not exist or is not modern $webpart.pagename")
			 }
	}

	 
	catch {  
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow  

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		DeletePageOnFailure $pagename
	}
}

function DeletePageOnFailure($pagename)
{
	try
	{
		Write-Host "Clean up: Delete Page on failure started for: $pagename"
		$client.TrackEvent("Clean up: Delete Page on failure started for: $pagename") 

		Connect-PnPOnline -Url $url -Credentials $tenantAdmin -ErrorAction Stop

		$pagename=$nodeLevel.webpartSection.pagename
		$page = Get-PnPClientSidePage -Identity $pagename -ErrorAction SilentlyContinue           
		
		if($page -ne $null)
		{
		   Remove-PnPClientSidePage $pagename -ErrorAction Stop
		}

		Write-Host "Clean up: Delete Page on failure completed for: $pagename"
		$client.TrackEvent("Clean up: Delete Page on failure completed for: $pagename")
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	}
}

function CreateModernPage($url, $nodeLevel)
{
	try
	{
		Connect-PnPOnline -Url $url -Credential $tenantAdmin
		foreach($modernPage in $nodeLevel.page){
		
		$modernPagename=$modernPage.name
		$page = Get-PnPClientSidePage -Identity $modernPage.name -ErrorAction SilentlyContinue           
		
		if($page -eq $null)
		{            
			Add-PnPClientSidePage -Name $modernPagename -LayoutType Home -ErrorAction Stop
			$client.TrackEvent("Page created, $modernPage.name")
			Set-PnPHomePage -RootFolderRelativeUrl SitePages/$modernPagename.aspx
			Set-PnPClientSidePage -Identity $modernPagename -CommentsEnabled:$false -LayoutType Home -ErrorAction Stop
		}
		else
		{
			Write-Host "Page Already exists $page"
			$client.TrackEvent("Page Already exists $page")
		}
	  }
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		DeletePageOnFailure $modernPagename
	}
}

function ApplyTheme($themeName, $url, $tenantAdmin, $tenantUrl)
{
		
	$themeSector = @{
		"themePrimary" = "#009cad";
		"themeLighterAlt" = "#f2fbfc";
		"themeLighter" = "#cbeef2";
		"themeLight" = "#a1e0e7";
		"themeTertiary" = "#52c2ce";
		"themeSecondary" = "#16a7b7";
		"themeDarkAlt" = "#008c9c";
		"themeDark" = "#007784";
		"themeDarker" = "#005761";
		"neutralLighterAlt" = "#faf9f8";
		"neutralLighter" = "#f3f2f1";
		"neutralLight" = "#edebe9";
		"neutralQuaternaryAlt" = "#e1dfdd";
		"neutralQuaternary" = "#d0d0d0";
		"neutralTertiaryAlt" = "#c8c6c4";
		"neutralTertiary" = "#c2c2c2";
		"neutralSecondary" = "#858585";
		"neutralPrimaryAlt" = "#4b4b4b";
		"neutralPrimary" = "#333333";
		"neutralDark" = "#272727";
		"black" = "#1d1d1d";
		"white" = "#ffffff";
	}

	try
	{
		$client.TrackEvent("Apply Theme started.")
		if($themeName -eq "TASMU Sector") {
			try{
				$theme = Get-SPOTheme -Name $themeName
				Connect-PnPOnline -Url $url -Credentials $tenantAdmin
				Set-PnPWebTheme -Theme $themeName -WebUrl $url
				Write-Host "Theme updated for the site " $url
			} catch{
				Connect-SPOService -Url $tenantUrl -Credential $tenantAdmin
				Add-SPOTheme -Identity $themeName -Palette $themeSector -IsInverted $false -Overwrite
				Connect-PnPOnline -Url $url -Credentials $tenantAdmin
				Set-PnPWebTheme -Theme $themeName -WebUrl $url
				Write-Host "Theme updated for the site " $url
			}
		} 
		#else {
			#Set-PnPWebTheme -Theme $themeName -WebUrl $url
		#}
		$client.TrackEvent("Apply Theme completed.")
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	}
}

function AddCustomQuickLaunchNavigationSector($url, $nodeLevel)
{
  try
   {
	   Write-Host -ForegroundColor Green 'Updating QuickLaunch navigation for '$url 
	 $client.TrackEvent("Configure Custom Navigation, Started.")

	 $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin

	 foreach($level1 in $nodeLevel.Level1){

	 $isPresent=$false
	 $allNavigationNodeQuickLaunch=Get-PnPNavigationNode -Location QuickLaunch
	 foreach($NavigationNodeQuickLaunch in $allNavigationNodeQuickLaunch){
			if($NavigationNodeQuickLaunch.Title -eq $level1.nodeName)
			{
				$isPresent=$true
			}
		}


	 if($level1.count -eq 3 -and $isPresent -eq $false)
	 {
		$rootNavurl=$level1.url
		$rootNavcurrentURL=$url+"/Lists/"+$rootNavurl

		$rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Url $rootNavcurrentURL -Location "QuickLaunch"
		$client.TrackEvent("Root navigation node created, $level1.nodeName")
	 }
	 elseif($isPresent -eq $false)
	 {
		$rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Location "QuickLaunch"
		$client.TrackEvent("Root navigation node created, $level1.nodeName")
	 }
	 elseif($isPresent -eq $true)
	 {
		$rootNavNode=Get-PnPNavigationNode -Location "QuickLaunch" | Where-Object {$_.Title -eq $level1.nodeName}
	 }
	 

	  foreach($level2 in $level1.Level2){
		
			$TopNav = Get-PnPNavigationNode -id  $rootNavNode.Id
			if($TopNav.Children){
				$child=$TopNav.Children | Where-Object {$_.Title -eq $level2.nodeName}
				if($null -ne $child)
				{
					continue
				}
			}

			if($level1.count -eq 1)
			{
				$level2sector=$urlprefix+$level2.sector
				if($level2sector -eq $url)
				{
					$level2url=$level2.url
					$level2currentURL=$urlprefix+$level2url
					$navNode = AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
				}               

			}
			if($level1.count -eq 2)
			{
				$level2url=$level2.url
				$level2currentURL=$url+"/Lists/"+$level2url
				$navNode = AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
			}
			if($level1.count -eq 3)
			{
				$level2url=$level2.url
				$level2currentURL=$url+"/Lists/"+$level2url
				$navNode = AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
			}
			if($level1.count -eq 4)
			{
				$level2url=$level2.url
				$navNode = AddPnPNavigationNode $level2.nodeName $level2url $TopNav.Id
			}
		
			
			$client.TrackEvent("Navigation node created, $level2.nodeName")
		
			$TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id

			if($TopNav.Children){
			
			$child = $TopNav.Children | Select Title, Url, Id
			
				foreach($child in $TopNav.Children){ 
				 
					foreach($level3 in $level2.Level3){

						if($child.Title -eq $level2.nodeName){

						$level3url=$level3.url
						$level3currentURL=$urlprefix+$level3url

						$navNode = AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id

						$client.TrackEvent("Navigation node created, $level3.nodeName") 
		
			}}}}}
		 
	}
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		RemoveCustomNavigationQuickLaunchOnfailure $url $nodeLevel
	}
	Disconnect-PnPOnline
}

function AddCustomQuickLaunchNavigationEntity($url, $nodeLevel)
{
  try
   {
	   Write-Host 'Adding QuickLaunch navigation for '$url
	 $client.TrackEvent("Configure Custom Navigation, Started.")

	 $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
	 Remove-PnPNavigationNode -Title Documents -Location QuickLaunch -Force
     Remove-PnPNavigationNode -Title Pages -Location QuickLaunch -Force
	 Remove-PnPNavigationNode -Title "Site contents" -Location QuickLaunch -Force
	 foreach($level1 in $nodeLevel.Level1){

	 $isPresent=$false
	 $allNavigationNodeQuickLaunch=Get-PnPNavigationNode -Location QuickLaunch
	 foreach($NavigationNodeQuickLaunch in $allNavigationNodeQuickLaunch){
			if($NavigationNodeQuickLaunch.Title -eq $level1.nodeName)
			{
				$isPresent=$true
			}
		}

	if($isPresent -eq $false)
	 {
	 if($level1.count -eq 3)
	 {
		$rootNavurl=$level1.url
		$rootNavcurrentURL=$url+"/Lists/"+$rootNavurl

		$rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Url $rootNavcurrentURL -Location "QuickLaunch"
	 }
	 else
	 {
		$rootNavNode = Add-PnPNavigationNode -Title $level1.nodeName -Location "QuickLaunch"
	 }
	 $client.TrackEvent("Root navigation node created, $level1.nodeName")

	  foreach($level2 in $level1.Level2){
		
			$TopNav = Get-PnPNavigationNode -id  $rootNavNode.Id

			if($level1.count -eq 1)
			{
				$level2sector=$urlprefix+$level2.sector
				if($level2sector -eq $url)
				{
					$level2url=$level2.url
					$level2currentURL=$urlprefix+$level2url
					$navNode = AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
				}               

			}
			if($level1.count -eq 2)
			{
				$level2url=$level2.url
				$level2currentURL=$url+"/Lists/"+$level2url
				$navNode = AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
			}
			if($level1.count -eq 3)
			{
				$level2url=$level2.url
				$level2currentURL=$url+"/Lists/"+$level2url
				$navNode = AddPnPNavigationNode $level2.nodeName $level2currentURL $TopNav.Id
			}
			if($level1.count -eq 4)
			{
				$level2url=$level2.url
				$navNode = AddPnPNavigationNode $level2.nodeName $level2url $TopNav.Id
			}
		
			
			$client.TrackEvent("Navigation node created, $level2.nodeName")
		
			$TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id

			if($TopNav.Children){
			
			$child = $TopNav.Children | Select Title, Url, Id
			
				foreach($child in $TopNav.Children){ 
				 
					foreach($level3 in $level2.Level3){

						if($child.Title -eq $level2.nodeName){

						$level3url=$level3.url
						$level3currentURL=$urlprefix+$level3url

						$navNode = AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id

						$client.TrackEvent("Navigation node created, $level3.nodeName") 
		
			}}}}}}
		 
	}
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		RemoveCustomNavigationQuickLaunchOnfailure $url $nodeLevel
	}
	Disconnect-PnPOnline
}

function RemoveCustomNavigationQuickLaunchOnfailure($url, $nodeLevel)
{
   try
   {
	Write-Host "Clean up: Remove Custom Navigation QuickLaunch on failure started for site: $url"
	$client.TrackEvent("Clean up: Remove Custom Navigation QuickLaunch on failure started for site: $url")

	$connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
	$navigationNodeCollection = Get-PnPNavigationNode -Location QuickLaunch

	foreach($level1 in $nodeLevel.Level1){

		foreach($navigationNode in $navigationNodeCollection){

			if($navigationNode.Title -eq $level1.nodeName)
			{
				Remove-PnPNavigationNode -Title $navigationNode.Title -Location QuickLaunch -Force
			}
		}    
	  }
	  
	  Write-Host "Clean up: Remove Custom Navigation QuickLaunch on failure completed for site: $urll"
	  $client.TrackEvent("Clean up: Remove Custom Navigation QuickLaunch on failure completed for site: $url")
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	}
}

function AddPnPNavigationNode($Title, $Url, $Parent){
    Add-PnPNavigationNode -Title $Title -Url $Url -Location "QuickLaunch" -Parent $Parent
}

function AddUsersToDefaultSPGroup($url, $nodeLevel, $siteAlias) {

    $siteUrl = $url
    $connection = Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    
    
    try {
 
       foreach($SPGroup in $nodeLevel.defaultgroup){
         $SPGroupName= $siteAlias+' '+$SPGroup.Name
         $GroupPresent = Get-PnPGroup $SPGroupName -Connection $connection -ErrorAction SilentlyContinue
         
    if ([bool]($GroupPresent) -eq $true) {
          Write-Host "Group found. Adding users in $SPGroupName group in $siteUrl"
          $client.TrackEvent("Group found. Adding users inw $SPGroupName group in $siteUrl")
             
          #add users in group
 
          if($SPGroup.isUsers -eq $true)
             {
                 $web=Get-PnPWeb  
                 $ctx= $web.Context  
                 $newGroupName=$web.SiteGroups.GetByName($SPGroupName)  
                 $ctx.Load($newGroupName)  
                 $ctx.ExecuteQuery()
 
             foreach($user in $SPGroup.users){
 
                 try {                  
                     $userName=$user.email  
                     $userInfo = $web.EnsureUser($userName)  
                     $ctx.Load($userInfo)  
                     $addUser = $GroupPresent.Users.AddUser($userInfo)  
                     $ctx.Load($addUser)  
                     $ctx.ExecuteQuery()
                 }
                 catch {                    
                     $ErrorMessage = $_.Exception.Message
                     Write-Host $ErrorMessage -foreground Yellow
 
                     $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                     $telemtryException.Exception = $_.Exception.Message  
                     $client.TrackException($telemtryException)
                 }
             }
           }
 
          if($SPGroup.isADGroup -eq $true)
             {
                 $web=Get-PnPWeb  
                 $ctx= $web.Context  
                 $newGroupName=$web.SiteGroups.GetByName($SPGroupName)  
                 $ctx.Load($newGroupName)  
                 $ctx.ExecuteQuery()
 
             foreach($ADGroupUser in $SPGroup.ADGroup){
 
                 try {
                                    
                     $ADGroup = $web.EnsureUser($ADGroupUser)                    
                     #sharepoint online powershell add AD group to sharepoint group
                     $Result = $GroupPresent.Users.AddUser($ADGroup)
                     $ctx.Load($Result)
                     $ctx.ExecuteQuery()
                 }
                 catch {                    
                     $ErrorMessage = $_.Exception.Message
                     Write-Host $ErrorMessage -foreground Yellow
 
                     $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                     $telemtryException.Exception = $_.Exception.Message  
                     $client.TrackException($telemtryException)
                 }
             }
           }
 
          if($SPGroup.SecurityGroup -ne '')
             {
                 # Add Security group as member to Sharepoint group
                 Add-PnPUserToGroup -Identity $SPGroup.Name -LoginName $SPGroup.SecurityGroup
             }
         }
         
     else {
               Write-Host "$SPGroupName not found in $siteUrl"
               $client.TrackEvent("$SPGroupName not found in $siteUrl")
          }
        }
       }
       catch {            
           Write-Host $_.Exception.Message -ForegroundColor Red
       }
         Disconnect-PnPOnline
 }

function CreateNewGroupAddUsers($url, $nodeLevel, $siteAlias) {

    $siteUrl = $url
    $connection = Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
    
    
    try {
 
       foreach($SPGroup in $nodeLevel.group){
         if($siteAlias -eq "TASMU CMS"){
             $SPGroupName= 'Global '+$SPGroup.Name
         }
         else{
             $SPGroupName= $siteAlias+' '+$SPGroup.Name
         }
         $groupExists = Get-PnPGroup $SPGroupName -Connection $connection -ErrorAction SilentlyContinue
         
         if ([bool]($groupExists) -eq $false) {
             Write-Host "Group not found. Creating new $($SPGroup.Name) group in $siteUrl"
             $client.TrackEvent("Group not found. Creating new $($SPGroup.Name) group in $siteUrl")
             
             $newGroup = New-PnPGroup -Title $SPGroupName -Description $SPGroup.Description
             Set-PnPGroupPermissions -Identity $SPGroupName -AddRole $SPGroup.Role
         }
         else {
               Write-Host "$($SPGroup.Name) already exists in $siteUrl"
               $client.TrackEvent("$($SPGroup.Name) already exists in $siteUrl")
          }
 
          #add users in group
          $GroupPresent= Get-PnPGroup -Identity $SPGroupName
 
          if ([bool]($GroupPresent) -eq $true) {
 
            if($SPGroup.isUsers -eq $true)
             {
                 $web=Get-PnPWeb  
                 $ctx= $web.Context  
                 $newGroupName=$web.SiteGroups.GetByName($SPGroupName)  
                 $ctx.Load($newGroupName)  
                 $ctx.ExecuteQuery()
 
             foreach($user in $SPGroup.users){
 
                 try {                  
                     $userName=$user.email  
                     $userInfo = $web.EnsureUser($userName)  
                     $ctx.Load($userInfo)  
                     $addUser = $GroupPresent.Users.AddUser($userInfo)  
                     $ctx.Load($addUser)  
                     $ctx.ExecuteQuery()
                 }
                 catch {                    
                     $ErrorMessage = $_.Exception.Message
                     Write-Host $ErrorMessage -foreground Yellow
 
                     $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                     $telemtryException.Exception = $_.Exception.Message  
                     $client.TrackException($telemtryException)
                 }
             }
           }
 
           if($SPGroup.isADGroup -eq $true)
             {
                 $web=Get-PnPWeb  
                 $ctx= $web.Context  
                 $newGroupName=$web.SiteGroups.GetByName($SPGroupName)  
                 $ctx.Load($newGroupName)  
                 $ctx.ExecuteQuery()
 
             foreach($ADGroupUser in $SPGroup.ADGroup){
 
                 try {
                                    
                     $ADGroup = $web.EnsureUser($ADGroupUser)                    
                     #sharepoint online powershell add AD group to sharepoint group
                     $Result = $GroupPresent.Users.AddUser($ADGroup)
                     $ctx.Load($Result)
                     $ctx.ExecuteQuery()
                 }
                 catch {                    
                     $ErrorMessage = $_.Exception.Message
                     Write-Host $ErrorMessage -foreground Yellow
 
                     $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
                     $telemtryException.Exception = $_.Exception.Message  
                     $client.TrackException($telemtryException)
                 }
             }
           }
         
 
           if($SPGroup.SecurityGroup -ne '')
             {
                 # Add Security group as member to Sharepoint group
                 Add-PnPUserToGroup -Identity $SPGroupName -LoginName $SPGroup.SecurityGroup
             }
         }       
       }      
     }   
     catch {            
           Write-Host $_.Exception.Message -ForegroundColor Red
       }
         Disconnect-PnPOnline
 }
 
function ListandLibrary($url, $nodeLevel) {

	Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
	Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

	$admin = $tenantAdmin.UserName
	$password = $tenantAdmin.Password
	$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)


		#create all list
		$siteUrlNew = $url

		EnableSitePagesFeatureAtSiteLevel $siteUrlNew

		#create all List & Libraries
		$client.TrackEvent("List and Library creation started.")
		
		foreach ($itemList in $nodeLevel.ListAndContentTypes) {
			if ($itemList.ListName -eq "Documents" -or $itemList.ListName -eq "Site Pages" -or $itemList.ListName -eq "Image Gallery") {
				$ListURL = $itemList.ListName
			}
			else {
				$ListURL = "Lists/" + $itemList.ListName
			}
			
			$ListURL = $ListURL -replace '\s', ''
			
			Create-ListAddContentType $tenantAdmin $siteUrlNew $itemList.ListName $itemList.ListTemplate $ListURL $itemList.ContentTypeName $itemList.Field.LookupListName $itemList.Field.LookupField $itemList.projectedField $itemList.Field.ColumnName $itemList.Field.ColumnTitle $itemList.Field.Type $itemList.columnItem $itemList.Data.Item $itemList.ParentCTName $itemList.GroupName

			if(Get-PnPList -Identity $itemList.ListName){     
				ViewCreation $itemList.ListName $siteUrlNew $itemList.defaultviewfields $itemList.ListTemplate
			}

			if($itemList.customView -ne ''){
				if(Get-PnPList -Identity $itemList.ListName){
					CustomViewCreation $itemList.ListName $siteUrlNew $itemList.customView $itemList.customViewfields
				}
			}
			if(Get-PnPList -Identity $itemList.ListName)
			{
				# Enable document set content type only for Services List
				if($itemList.ListName -eq 'Services')
				{
					EnabledocsetFeatureOnTargetSite $siteUrlNew $itemList.ListName
				}
			} 
		}
}

function Create-ListAddContentType($tenantAdmin, $siteUrlNew, $ListName, $ListTemplate, $ListURL, $ContentTypeName, $LookupListName, $LookupField, $ProjectedFields, $LookupFieldColumnName, $LookupFieldColumnTitle, $LookupFieldType, $ColumnItems, $Items, $ParentContentTypeName, $GroupName) {
	Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
	Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')

	$admin = $tenantAdmin.UserName
	$password = $tenantAdmin.Password
	$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)

	try {
		# Connect with the tenant admin credentials to the tenant
		$connection = Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin -ErrorAction Stop

		#foreach ($field in $fields) {
			if([bool]$LookupFieldColumnName -eq $true -and [bool]$LookupListName -eq $true -and [bool]$LookupField -eq $true){
				CreateLookupColumnForList -SiteURL $siteUrlNew -ListName $ListName -Name $LookupFieldColumnName -DisplayName $LookupFieldColumnTitle -LookupListName $LookupListName -LookupField $LookupField -LookupType $LookupFieldType -ProjectedFields $ProjectedFields -GroupName $GroupName $connection
			}
	   # }
		
		if([bool]($ParentContentTypeName) -eq $true){
			#Call the function to Create ContentType
			Create-ContentType $globalhubSiteUrl $ContentTypeName $ContentTypeName $ParentContentTypeName $GroupName $connection

			foreach($columnItem in $ColumnItems){
				AddColumns-ContentType $globalhubSiteUrl $columnItem.ContentTypeName $columnItem.ColumnName $connection $columnItem.Required
			} 
		}

		$ListExist = Get-PnPList -Identity $ListURL -ErrorAction Stop
		if ([bool]($ListExist) -eq $false) {
			Write-Host "List not found in $siteUrlNew creating new List - $ListName .."
			$client.TrackEvent("List not found in $siteUrlNew creating new List - $ListName ..")

			if ($ListName -eq "Documents") {                
				New-PnPList -Title $ListName -Template $ListTemplate -ErrorAction Stop
			}
			else {
				if ($ListName -ne "Site Pages") {
					$newList = New-PnPList -Title $ListName -Template $ListTemplate -Url $ListURL -ErrorAction Stop
					$client.TrackEvent("List/Library created, $ListName")
				}
			}

			$List = Get-PnPList -Identity $ListURL -ErrorAction Stop
			if($ContentTypeName -ne '')
			{

			$ListBase = Get-PnPContentType -Identity $ContentTypeName -ErrorAction Stop -Connection $connection
			Set-PnPList -Identity $ListName -EnableContentTypes $true -EnableVersioning $true
			
			<#if($ContentTypeName -ne 'Item'){
				# make the content type read-only false
				Try {
					#Setup the context
					$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrlNew)
					$Ctx.Credentials = $credentials
		 
					#Get the content type from the web
					$ContentTypeColl = $Ctx.Web.ContentTypes
					$Ctx.Load($ContentTypeColl)
					$Ctx.ExecuteQuery()
  
					#Get the content type to Add
					$CType = $ContentTypeColl | Where {$_.Name -eq $ContentTypeName}
					If($CType -ne $Null)
					{
						$CType.ReadOnly=$false
						$CType.Update($True)
						$Ctx.ExecuteQuery()
 
						Write-host "Content Type $ContentTypeName is Set to Read Only False!" -ForegroundColor Green
					}
					else
					{
						Write-host "Content Type $ContentTypeName Doesn't Exist!" -ForegroundColor Yellow
					}
				}
				Catch {
					write-host -f Red "Error Setting Content Type $ContentTypeName to Read Only false!" $_.Exception.Message
				}
			}#>

			# Add the lookup columns to the list
			<#foreach($columnItem in $ColumnItems){
				Add-PnPFieldToContentType -Field $columnItem.ColumnName -ContentType $ContentTypeName
				$siteColumn = $columnItem.ColumnName
				Write-host "Site Column '$siteColumn' Added to List '$ListName' Successfully!" -f Green
			} #>

			$contentTypeToList = Add-PnPContentTypeToList -List $List -ContentType $ListBase -DefaultContentType -ErrorAction Stop
			$client.TrackEvent("Content Type, $ContentTypeName added to List, $ListName")

			if($ListName -eq "My Tasks")
			{
				#$secondContentTypeName="TASMU MyTask Translator"
				$secondContentTypeName="TASMU Translation Tasks"
				$secondListBase = Get-PnPContentType -Identity $secondContentTypeName -ErrorAction Stop -Connection $connection
				$contentTypeToList = Add-PnPContentTypeToList -List $List -ContentType $secondListBase -ErrorAction Stop
				$client.TrackEvent("Content Type, $secondContentTypeName added to List, $ListName")                
			}

			#remove content type which gets created by default

			if($ListTemplate -eq 'GenericList')
			{
				#Get the content type
				$BaseItemContentType = Get-PnPContentType -Identity "Item" -Connection $connection -ErrorAction Stop
 
				If($BaseItemContentType)
				{
					Remove-PnPContentTypeFromList -List $List -ContentType $BaseItemContentType -ErrorAction Stop
					$client.TrackEvent("Default Content Type, $BaseItemContentType deleted from List, $ListName")
				}
			}
			if($ListTemplate -eq 'DocumentLibrary')
			{
				#Get the content type
				$BaseDocContentType = Get-PnPContentType -Identity "Document" -Connection $connection -ErrorAction Stop
 
				If($BaseDocContentType)
				{
					Remove-PnPContentTypeFromList -List $List -ContentType $BaseDocContentType -ErrorAction Stop
					$client.TrackEvent("Default Content Type, $BaseDocContentType deleted from Library, $ListName")
				}
			}
			if($ListTemplate -eq 'PictureLibrary')
			{
				#Get the content type
				$BasePicContentType = Get-PnPContentType -Identity "Picture" -Connection $connection -ErrorAction Stop
 
				If($BasePicContentType)
				{
					Remove-PnPContentTypeFromList -List $List -ContentType $BasePicContentType -ErrorAction Stop
					$client.TrackEvent("Default Content Type, $BasePicContentType deleted from picture Library, $ListName")
				}
			}
			}

			#Adding data to the created list
			foreach ($item in $Items) {
				$hash = $null
				$hash = @{}
				foreach($attr in $item.Attributes)
				{
				$hash.add($attr.Name,$attr.Value)
				}
				Write-Host "Adding item to " $ListName
				$client.TrackEvent("Adding item to $ListName")
				Add-PnPListItem -List  'TranslateConfig' -Values $hash
			}
		}
		else {
			Write-Host "$ListName already exists in $siteUrlNew"
			$client.TrackEvent("$ListName already exists in $siteUrlNew")
		} 
		#Disconnect-PnPOnline
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		#DeleteListOnFailure $siteUrlNew $ListName
	}
}

function Create-ContentType($contenttypehub, $ContentTypeName, $ContentTypeDesc, $ParentCTName, $GroupName, $connection) {
	try {
		$ContentTypeExist = Get-PnPContentType -Identity $ContentTypeName -ErrorAction Stop -Connection $connection
		#Check for existence of  site content type
		if ([bool]($ContentTypeExist) -eq $false) {
			Write-Host "Content Type not found ,so creating a new contenttype- $ContentTypeName....."
			$client.TrackEvent("Content Type not found ,so creating a new contenttype- $ContentTypeName.....")
			$ParentCT = Get-PnPContentType -Identity $ParentCTName -Connection $connection
			$contentTypeNew = Add-PnPContentType -Name $ContentTypeName -Description $ContentTypeDesc -Group $GroupName -ParentContentType $ParentCT -ErrorAction Stop -Connection $connection
		}
		else {
			Write-Host "$ContentTypeName already exists"
			$client.TrackEvent("$ContentTypeName already exists")

		}  
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow
		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	} 
}

Function CreateLookupColumnForList()
{
	param
	(
		[Parameter(Mandatory=$true)] [string] $SiteURL,
		[Parameter(Mandatory=$true)] [string] $ListName,
		[Parameter(Mandatory=$true)] [string] $Name,
		[Parameter(Mandatory=$true)] [string] $DisplayName,
		[Parameter(Mandatory=$false)] [string] $IsRequired = "FALSE",
		[Parameter(Mandatory=$false)] [string] $EnforceUniqueValues = "FALSE",
		[Parameter(Mandatory=$true)] [string] $LookupListName,
		[Parameter(Mandatory=$true)] [string] $LookupField,
		[Parameter(Mandatory=$true)] [string] $LookupType,
		[Parameter(Mandatory=$false)] [object] $ProjectedFields,
		[Parameter(Mandatory=$true)] [string] $GroupName,
		$connection
	)
	
	$fieldExists = Get-PNPField -identity $Name -ErrorAction SilentlyContinue
	$LookupListExist = Get-PnPList -Identity $LookupListName -Connection $connection -ErrorAction Stop
	if ([bool] ($fieldExists) -eq $false) {
		
		$LookupListID= $LookupListExist.id
		
		$web = Get-PnPWeb
		$LookupWebID=$web.Id

		$lookupColumnId = [GUID]::NewGuid() 
		$addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$LookupType'
		ID='{$lookupColumnId}' Mult='TRUE' Group='$GroupName' Sortable='FALSE' DisplayName='$DisplayName' Name='$Name' Description='$Description'
		Required='$IsRequired' EnforceUniqueValues='$EnforceUniqueValues' List='$LookupListID' 
		WebId='$LookupWebID' ShowField='$LookupField' />"

		foreach($columnItem in $ProjectedFields){
			$columnExists = Get-PNPField -identity $columnItem.ColumnName -ErrorAction SilentlyContinue
			if ([bool] ($columnExists) -eq $false) {
				# create the projected field
				$newID=[GUID]::NewGuid() 
				$ColumnTitle=$columnItem.ColumnTitle
				$ColumnName=$columnItem.ColumnName
				$showField = $columnItem.ShowField
				$projectedType = $columnItem.Type
				$addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$projectedType' DisplayName='$ColumnTitle' Name='$ColumnName' 
				ShowField='$showField' EnforceUniqueValues='FALSE' Group='$GroupName' Mult='TRUE' Sortable='FALSE' Required='FALSE' Hidden='FALSE' ReadOnly='TRUE' CanToggleHidden='FALSE' 
				ID='$newID' UnlimitedLengthInDocumentLibrary='FALSE' FieldRef='$lookupColumnId' List='$LookupListID' />"
			}
		}
	}
}

function AddColumns-ContentType($contenttypehub, $ContentTypeName, $ColumnName, $connection, $required) {
	try {
		Write-Host "Column not added, so adding column - $ColumnName to contenttype - $ContentTypeName....."
		$client.TrackEvent("Column not added, so adding column - $ColumnName to contenttype - $ContentTypeName.....")
		if ($required -eq "False") {
			$columnToContentType = Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection
		}
		else {
			$columnToContentType = Add-PnPFieldToContentType -Field $ColumnName -ContentType $ContentTypeName -ErrorAction Stop -Connection $connection -Required
		}  
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage -foreground Yellow
		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)
	} 
}

function ViewCreation($listNameForView, $siteUrlNew, $fields, $ListTemplate) {
	
	$client.TrackEvent("View creation started for list, $listNameForView.")
	#Connect with the tenant admin credentials to the tenant
	#Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin

	try {
			 
		 if($ListTemplate -eq 'DocumentLibrary')
		 {
			$viewExists = Get-PnPView -List $listNameForView -Identity "All Documents" -ErrorAction SilentlyContinue
			$defaultviewName='All Documents'
		 }
		 else
		 {
			$viewExists = Get-PnPView -List $listNameForView -Identity "All Items" -ErrorAction SilentlyContinue
			$defaultviewName='All Items'
		 }
		 
		 
		 foreach($field in $fields)
		 {
		   $defaultviewfields+= @($field.name)
		 }

		$client.TrackEvent("Fields ready for default view creation.")

		if ([bool]($viewExists) -eq $false) {
			Write-Host "View not found ,so creating a new View in $listNameForView"
			$client.TrackEvent("View not found ,so creating a new View in $listNameForView")
			$newView = Add-PnPView -List $listNameForView -Title $defaultviewName -Fields $defaultviewfields -SetAsDefault -ErrorAction Stop

		}
		else {
			Write-Host "View already exists in List $listNameForView site- $siteUrlNew "
			$client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")
			Add-ColumnToDefaultView -SiteUrl $siteUrlNew -Fields $defaultviewfields -ListName $listNameForView
			
			#delete the LinkTitle from default view
			Update-ColumnToDefaultView -ListName $listNameForView $defaultviewName $siteUrlNew
		}
		#region update the sorting order for the view 
		UpdateView $siteUrlNew $tenantAdmin $defaultviewName $listNameForView
		#endregion
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage "in Site $siteUrlNew  List $listNameForView " -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		DeleteListOnFailure $siteUrlNew $listNameForView
	}
	#Disconnect-PnPOnline
}

function Update-ColumnToDefaultView($ListName,$ViewName,$url)
{
	Try {
		#Connect to PNP Online
		Connect-PnPOnline -Url $url -Credential $tenantAdmin
 
		#Get the Context
		$Context = Get-PnPContext
 
		#Get the List View from the list
		$ListView  =  Get-PnPView -List $ListName -Identity $ViewName -ErrorAction Stop

		$ColumnName="LinkTitle"
 
		#Check if view doesn't have the column already
		If($ListView.ViewFields -contains $ColumnName)
		{
			#Remove Column from View
			$ListView.ViewFields.Remove($ColumnName)
			$ListView.Update()
			$Context.ExecuteQuery()
			Write-host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
		}
		else
		{
			Write-host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
		}

		$ColumnName="LinkFilename"

		#Check if view doesn't have the column already
		If($ListView.ViewFields -contains $ColumnName)
		{
			#Remove Column from View
			$ListView.ViewFields.Remove($ColumnName)
			$ListView.Update()
			$Context.ExecuteQuery()
			Write-host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
		}
		else
		{
			Write-host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
		}

		$ColumnName="DocIcon"
		#Check if view doesn't have the column already
		If($ListView.ViewFields -contains $ColumnName)
		{
			#Remove Column from View
			$ListView.ViewFields.Remove($ColumnName)
			$ListView.Update()
			$Context.ExecuteQuery()
			Write-host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
		}
		else
		{
			Write-host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
		}

		$ColumnName="Editor"

		#Check if view doesn't have the column already
		If($ListView.ViewFields -contains $ColumnName)
		{
			#Remove Column from View
			$ListView.ViewFields.Remove($ColumnName)
			$ListView.Update()
			$Context.ExecuteQuery()
			Write-host -f Green "Column '$ColumnName' Removed from View '$ViewName'!"
		}
		else
		{
			Write-host -f Yellow "Column '$ColumnName' doesn't exist in View '$ViewName'!"
		}
	}
	catch {
		write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
	}
}

function Add-ColumnToDefaultView($SiteUrl, $Fields, $ListName) {
	Write-Host "Updating view for $ListName..."
	$client.TrackEvent("Updating view for $ListName...")
	$admin = $tenantAdmin.UserName
	$password = $tenantAdmin.Password
	$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
	$context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
	$context.Credentials = $credentials
	$web = $context.Web
	$list = $web.Lists.GetByTitle($ListName)
	$defaultFields = $list.DefaultView.ViewFields
	
	$context.Load($web)
	$context.Load($web.Lists)
	$context.Load($list.Fields)
	$context.Load($defaultFields)
	$context.ExecuteQuery()

	try {
		[int]$fieldOrder = 0
		foreach ($f in $Fields) {
			$field = $list.Fields | Where-Object { $_.InternalName -eq $f } | Select-Object -First 1
			if ($null -ne $field) {
				$isField = $defaultFields | Where-Object { $_ -eq $field.Title -or $_ -eq $field.InternalName }
				if ($null -eq $isField) {
					$defaultFields.Add($field.InternalName)
				}
				$defaultFields.MoveFieldTo($field.InternalName, $fieldOrder)
			}      
			$list.DefaultView.Update()
			$fieldOrder++
		}

		# If view contains Pinned column, then sort with Pinned then Modified Date
		$isContainsPinned = $list.Fields | Where-Object { $_.InternalName -eq 'Pinned' }
		if ($null -ne $isContainsPinned) {
			$viewQuery = '<OrderBy><FieldRef Name="Pinned" Ascending="FALSE" /><FieldRef Name="Modified" Ascending="FALSE" /></OrderBy>'
			$list.DefaultView.ViewQuery = $viewQuery
			$list.DefaultView.Update()
		}
		else {
			$viewQuery = '<OrderBy><FieldRef Name="Modified" Ascending="FALSE" /></OrderBy>'
			$list.DefaultView.ViewQuery = $viewQuery
			$list.DefaultView.Update()
		}
		$context.ExecuteQuery()
	}
	catch {
		Write-Host $_.Exception.Message -ForegroundColor Red

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		DeleteListOnFailure $SiteUrl $ListName
	}
}
function CustomViewCreation($listNameForView, $siteUrlNew, $customViewName, $fields)
{
	#Connect with the tenant admin credentials to the tenant
	#Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin

	try {
		$viewExists = Get-PnPView -List $listNameForView -Identity $customViewName -ErrorAction SilentlyContinue

		if ([bool]($viewExists) -eq $false) {
			Write-Host "View not found ,so creating a new View in $listNameForView"
			$client.TrackEvent("View not found ,so creating a new View in $listNameForView")

			foreach($field in $fields)
			{
			   $customViewfields+= @($field.name)
			}
			
			$newView = Add-PnPView -List $listNameForView -Title $customViewName -Fields $customViewfields -ErrorAction Stop
			Write-Host "$customViewName - View created in $listNameForView"
			$client.TrackEvent("$customViewName - View created in $listNameForView")
		}
		else {
			Write-Host "View already exists in List $listNameForView site- $siteUrlNew "
			$client.TrackEvent("View already exists in List $listNameForView site- $siteUrlNew ")
		}
		#region update the sorting order for the view 
		UpdateView $siteUrlNew $tenantAdmin $customViewName $listNameForView
		#endregion
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage "in Site $siteUrlNew  List $listNameForView " -foreground Yellow

		$telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
		$telemtryException.Exception = $_.Exception.Message  
		$client.TrackException($telemtryException)

		DeleteListOnFailure $siteUrlNew $listNameForView
	}
	#Disconnect-PnPOnline
}

function EnabledocsetFeatureOnTargetSite($siteUrlNew, $ListName) 
{
	$client.TrackEvent("Enabling docset feature on target site Started.")
	Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin
	$connection = Get-PnPConnection

	#activate feature for site pages
	Write-Host "Enabling docset feature on target site - 3bae86a2-776d-499d-9db8-fa4cdc7884f8"
	$client.TrackEvent("Enabling feature for site pages - 3bae86a2-776d-499d-9db8-fa4cdc7884f8")
	
	Enable-PnPFeature -Identity 3bae86a2-776d-499d-9db8-fa4cdc7884f8 -Connection $connection -Scope Site -Force

	Set-PnPList -Identity $ListName -EnableContentTypes $true
	Add-PnPContentTypeToList -List $ListName -ContentType "Document Set"
		
	Disconnect-PnPOnline
}

function EnableSitePagesFeatureAtSiteLevel($siteUrlNew) 
{
	$client.TrackEvent("Enable SitePages Feature At SiteLevel Started.")
	Connect-PnPOnline -Url $siteUrlNew -Credentials $tenantAdmin
	$connection = Get-PnPConnection

	#activate feature for site pages
	Write-Host "Enabling feature for site pages - b6917cb1-93a0-4b97-a84d-7cf49975d4ec"
	$client.TrackEvent("Enabling feature for site pages - b6917cb1-93a0-4b97-a84d-7cf49975d4ec")
	
	Enable-PnPFeature -Identity b6917cb1-93a0-4b97-a84d-7cf49975d4ec -Connection $connection -Scope Web -Force
	#enable Team Collaboration Lists feature
	Write-Host "Enabling feature for Team Collaboration Lists - 00bfea71-4ea5-48d4-a4ad-7ea5c011abe5"
	$client.TrackEvent("Enabling feature for Team Collaboration Lists - 00bfea71-4ea5-48d4-a4ad-7ea5c011abe5")
	
	Enable-PnPFeature -Identity 00bfea71-4ea5-48d4-a4ad-7ea5c011abe5 -Connection $connection -Scope Web -Force

		
	Disconnect-PnPOnline
}

function EnableMegaMenu($url)
{
    try
    {
        $client.TrackEvent("MegaMenu Enable Started...")
        $web = Get-PnPWeb
        $web.MegaMenuEnabled = $true
        $web.Update()
        $client.TrackEvent("MegaMenu Enable Completed...")
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
}

function AddCustomQuickLaunchNavigationGlobal($url, $nodeLevel)
{
  try
   {
	 Write-host "Updating navigation for "$url -ForegroundColor Green 
     $client.TrackEvent("Configure Custom Navigation, Started.")

	 $connection = Connect-PnPOnline -Url $url -Credentials $tenantAdmin
	 
	 foreach($level1 in $nodeLevel.Level1){
	
		$rootNavNode=Get-PnPNavigationNode -Location QuickLaunch | Where-Object {$_.Title -eq $level1.nodeName}
	    if($null -ne $rootNavNode)
     {
		$TopNav = Get-PnPNavigationNode -Id $rootNavNode.Id
      foreach($level2 in $level1.Level2){
 
			$child=$TopNav.Children | Where-Object {$_.Title -eq $level2.nodeName}
				 
			if($null -ne $child)
			{
         	 foreach($level3 in $level2.Level3){
              $level3url=$level3.url
              $level3currentURL=$urlprefix+$level3url
              $navNode=AddPnPNavigationNode $level3.nodeName $level3currentURL $child.Id

              $client.TrackEvent("Navigation node created, $level3.nodeName") 
        
	 }}}}
    
    }

    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)

        RemoveCustomNavigationQuickLaunchOnfailure $url $nodeLevel
    }
    Disconnect-PnPOnline
}

Create-NewSiteCollection

do {
    Write-host "Sleep started for 3 minutes..." -ForegroundColor Green
    start-sleep -s 180
    Write-host "Sleep completed for 3 minutes..." -ForegroundColor Green
    $isExists = $true
    $isExists = checkContentTypeExists
}
until ($isExists -eq $true)

if ($isExists -eq $true) {
    Write-host "All Content types are available, Starting the provisioning script..." -ForegroundColor Green
    ProvisionSiteComponents 
}
Write-Host -ForegroundColor Green 'Completed'