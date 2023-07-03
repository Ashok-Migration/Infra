[CmdletBinding()]
param (
    $tenant, # Enter the tenant name
    $sp_user,
    $sp_password,
    $InstrumentationKey
)


function UpdateArabicNavigation($url, $termsXML) {
	
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    $client.InstrumentationKey = $InstrumentationKey 
    if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
        $client.Context.Cloud.RoleName = $RoleName
    }
    try {
        Write-Host "Navigation update started"
        $client.TrackEvent("Configure Custom Arabic Navigation, Started.")
        $secstr = New-Object -TypeName System.Security.SecureString
        $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
        $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
        Connect-PnPOnline -Url $url -Credentials $tenantAdmin -ErrorAction Stop
        $allNavigationNodeQuickLaunch = Get-PnPNavigationNode -Location QuickLaunch
        Write-Host "updating" $url
        foreach ($NavigationLevel1Node in $allNavigationNodeQuickLaunch) {
            Write-Host "Site" $url
            $TopNav = Get-PnPNavigationNode -Id $NavigationLevel1Node.Id
            if ($TopNav.Children) {

                $child = $TopNav.Children | Select Title, Url, Id
			   
                foreach ($child in $TopNav.Children) {
                    $Level1Nav = Get-PnPNavigationNode -Id $child.Id
                    if ($Level1Nav.Children) {
                        $childLevel2 = $Level1Nav.Children | Select Title, Url, Id
                        foreach ($childLevel2 in $Level1Nav.Children) {
                            foreach ($engNode in $termsXML.Descendants("EngNode")) {
                                $EngName = Get-AttributeValue $engNode "nodeName"
                            
                                if ($childLevel2.Title -eq $EngName) {
                                    write-Host "updating" $childLevel2.Title
                                    $childLevel2.Title = Get-AttributeValue $engNode "arNodeName"
                                    $childLevel2.Update()
                                    $childLevel2.Context.ExecuteQuery()		 
                                }

                            }


                        }


                    }
                    foreach ($engNode in $termsXML.Descendants("EngNode")) {
                        $EngName = Get-AttributeValue $engNode "nodeName"
                       
                        if ($child.Title -eq $EngName) {
                            write-Host "updating" $child.Title
                            $child.Title = Get-AttributeValue $engNode "arNodeName"
                            $child.Update()
                            $child.Context.ExecuteQuery()		 
                        }
                    }

					
                }
            }
            foreach ($engNode in $termsXML.Descendants("EngNode")) {
                Write-Host "SiteUpdating" $url
                $EngName = Get-AttributeValue $engNode "nodeName"
               
                if ($NavigationLevel1Node.Title -eq $EngName) {
                    write-Host "updating" $NavigationLevel1Node.Title
                    $NavigationLevel1Node.Title = Get-AttributeValue $engNode "arNodeName"
                    $NavigationLevel1Node.Update()
                    $NavigationLevel1Node.Context.ExecuteQuery()		 
                }
            }
		
			
        } 
        $allNavigationNodeQuickLaunch = Get-PnPNavigationNode -Location TopNavigationBar
        Write-Host "updating" $url
        foreach ($NavigationLevel1Node in $allNavigationNodeQuickLaunch) {
            Write-Host "Site" $url
            $TopNav = Get-PnPNavigationNode -Id $NavigationLevel1Node.Id
            if ($TopNav.Children) {

                $child = $TopNav.Children | Select Title, Url, Id
			   
                foreach ($child in $TopNav.Children) {

                     $Level1Nav = Get-PnPNavigationNode -Id $child.Id
                        if ($Level1Nav.Children) {
                        $childLevel2 = $Level1Nav.Children | Select Title, Url, Id
                        foreach ($childLevel2 in $Level1Nav.Children) {
                            foreach ($engNode in $termsXML.Descendants("EngNode")) {
                                $EngName = Get-AttributeValue $engNode "nodeName"
                            
                                if ($childLevel2.Title -eq $EngName) {
                                    write-Host "updating" $childLevel2.Title
                                    $childLevel2.Title = Get-AttributeValue $engNode "arNodeName"
                                    $childLevel2.Update()
                                    $childLevel2.Context.ExecuteQuery()		 
                                }

                            }


                        }


                    }

                    foreach ($engNode in $termsXML.Descendants("EngNode")) {
                        $EngName = Get-AttributeValue $engNode "nodeName"
             
                        if ($child.Title -eq $EngName) {
                            write-Host "updating" $child.Title
                            $child.Title = Get-AttributeValue $engNode "arNodeName"
                            $child.Update()
                            $child.Context.ExecuteQuery()		 
                        }
                    }
					
                }
            }
            foreach ($engNode in $termsXML.Descendants("EngNode")) {
                Write-Host "SiteUpdating" $url
                $EngName = Get-AttributeValue $engNode "nodeName"
        
                if ($NavigationLevel1Node.Title -eq $EngName) {
                    write-Host "updating" $NavigationLevel1Node.Title
                    $NavigationLevel1Node.Title = Get-AttributeValue $engNode "arNodeName"
                    $NavigationLevel1Node.Update()
                    $NavigationLevel1Node.Context.ExecuteQuery()		 
                }
            }
		
			
        }
        Write-Host "Nav updation completed"
        $client.TrackEvent("Configure Custom Arabic Navigation, Completed.")
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Yellow

        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
	
}

function Get-AttributeValue($node, $attributeName) {

    $attributeValue = ''
    if ($node.Attribute($attributeName) -ne $null) {
        $attributeValue = $node.Attributes($attributeName).Value
    }

    return $attributeValue

}

function Get-TermsToUpdate($xmlTermsPath) {
    [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

    try {
        $xDoc = [System.Xml.Linq.XDocument]::Load($xmlTermsPath, [System.Xml.Linq.LoadOptions]::None)
        return $xDoc
    }
    catch {
        Write-Host "Unable to read taxonomy xml. Exception:" $_.Exception.Message -ForegroundColor Red
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
}

function UpdateArabicTitle($url, $termsXML) {
	
    Write-Host "Updating Title for $url"
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    $client.InstrumentationKey = $InstrumentationKey 
    if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
        $client.Context.Cloud.RoleName = $RoleName
    }
    Try {
        $client.TrackEvent("Update Arabic Title, Started.")
		
        $secstr = New-Object -TypeName System.Security.SecureString
        $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

        $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
        $admin = $tenantAdmin.UserName
        $password = $tenantAdmin.Password
        $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
        $context = New-Object Microsoft.SharePoint.Client.ClientContext($url)
        $context.Credentials = $credentials
        $web = $context.web
        $context.Load($web)
        $context.ExecuteQuery() 
        #Get the current site title
        Write-host "Site Title:"$web.title
        foreach ($engNode in $termsXML.Descendants("TitleNode")) {
            $EngName = Get-AttributeValue $engNode "nodeName"
            if ($EngName -eq $web.title) {
                $NewSiteTitle = Get-AttributeValue $engNode "arNodeName"
                Write-host "Site newsiteTitle '$NewSiteTitle'"
                #sharepoint online powershell change site title
                $web.title = $NewSiteTitle
                $Web.Update()
                $context.ExecuteQuery()
                Write-host "Site Title has been updated to '$NewSiteTitle'" -ForegroundColor Green 
            }
	 
        }
        $client.TrackEvent("Update Arabic Title, Completed.")
	
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        write-host -f Red "Error Updating Site Title!" $_.Exception.Message
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
		
    }
}

function UpdateArabicContent() {
    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    $client.InstrumentationKey = $InstrumentationKey 
    if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
        $client.Context.Cloud.RoleName = $RoleName
    }
    Try {
        $client.TrackEvent("Update Arabic Content,Started.")
	
        $tenantUrl = "https://" + $tenant + ".sharepoint.com"
        $secstr = New-Object -TypeName System.Security.SecureString
        $sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
        $filePath = $PSScriptRoot + '\resources\Arabic.xml'
        $termsXML = Get-TermsToUpdate($filePath)
        [xml]$sitefile = Get-Content -Path $filePath
        $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
        # Connect with the tenant admin credentials to the tenant
        #Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin -ErrorAction Stop
        #$sites = Get-PnPTenantSite -Filter "Url -like 'cms' -and Url -notlike '-my.sharepoint.com/' -and Url -notlike '/portals/'"
        foreach ($site in $sitefile.sites.SiteURLs.site) {
            UpdateArabicNavigation $site.url $termsXML
            UpdateArabicTitle $site.url $termsXML
        }
        $client.TrackEvent("Update Arabic Content, Completed.")
	
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        write-host -f Red "Error Updating Site Title!" $_.Exception.Message
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
		
    }
	

}

UpdateArabicContent