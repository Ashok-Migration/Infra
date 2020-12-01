<#
.DESCRIPTION
    This Script is for Deleting all Site collections, Site content types, Site columns & taxanomy columns as per the input from the XML file
    XML files it will look for inputs are
    Site.xml, ContentType.xml, SiteColumns.xml, Taxonomy.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the Clean up script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Delete all Site collections, Site content types, Site columns & taxanomy columns as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : CompleteCleanup.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
17/07/2020  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
    $tenant,
    $TemplateParametersFile,
    $sp_user,
    $sp_password,
    $InstrumentationKey
)

function Complete-Cleanup() 
{
    $TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
 
    $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    }

    $RoleName = $JsonParameters.RoleName.value

    Add-Type -Path (Resolve-Path $PSScriptRoot'\Assemblies\Microsoft.ApplicationInsights.dll')
    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    $client.InstrumentationKey = $InstrumentationKey 
    $client.Context.Cloud.RoleName = $RoleName

    $filePath = $PSScriptRoot + '\resources\Site.xml'
    [xml]$sitefile = Get-Content -Path $filePath

    $siteContentTypePath = $PSScriptRoot + '\resources\ContentType.xml'
    [xml]$scXML = Get-Content -Path $siteContentTypePath

    $siteColumnfilePath = $PSScriptRoot + '\resources\SiteColumns.xml'
    [xml]$siteColumnfilePathfile = Get-Content -Path $siteColumnfilePath

    $termsPath = $PSScriptRoot + '\resources\Taxonomy.xml'
    [xml]$termsfile = Get-Content -Path $termsPath

    $serchConfigPath= $PSScriptRoot + '\resources\SearchConfiguration.xml'
    $tenantUrl="https://"+$tenant+"-admin.sharepoint.com/"
    $urlprefix = "https://"+$tenant+".sharepoint.com/sites/"
    $contenttypehub="https://"+ $tenant+".sharepoint.com/sites/contentTypeHub"

    CompleteCleanup $sitefile $scXML $siteColumnfilePathfile $termsfile

    Write-host "Completed" -ForegroundColor Green
    $client.TrackEvent("Completed.")

   }

<#
.SYNOPSIS
    This function is used for calling all the methods for cleanup

.DESCRIPTION
    This function is responsible for calling all the methods for cleanup.

.EXAMPLE
    CompleteCleanup $sitefile $scXML $siteColumnfilePathfile $termsfile

.INPUTS

.OUTPUTS
    Status - $true for when the function has been able to call all the methods for cleanup
             $false for when the function has not been able to call all the methods for cleanup
#>

function CompleteCleanup($sitefile,$scXML,$siteColumnfilePathfile,$termsfile)
{
    #delete Sites
    DeleteSiteCollections $sitefile

    #delete ContentTypes from Contenttypehub
    DeleteContentTypes $scXML

    #delete Site Columns from Contenttypehub
    DeleteSiteColumns $siteColumnfilePathfile

    #delete Taxanomy from Term Store
    DeleteTaxanomyGroup $termsfile

}

<#
.SYNOPSIS
    This function is used to Delete all SiteCollections as per Sites.xml

.DESCRIPTION
    This function will use the PnP cmdlets to Delete all site collection that
    is configured as per Sites.xml.

.EXAMPLE
    DeleteSiteCollections $sitefile

.INPUTS

.OUTPUTS
    Status - $true for when the function has been able to Delete the requested site collection as per xml
             $false for when the function has not been able to Delete the requested site collection as per xml
#>

function DeleteSiteCollections($sitefile) 
{
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}

    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $tenantUrl -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    Write-Host "Delete Site Collections Started..."
    $client.TrackEvent("Delete Site Collections Started...")

    foreach($globalhubsite in $sitefile.sites.globalhubsite.site)
     {
        try
        {
        $globalhubSiteUrl = $urlprefix + $globalhubsite.Alias
        $siteExits = Get-PnPTenantSite -Url $globalhubSiteUrl -ErrorAction SilentlyContinue
            
        if ([bool] ($siteExits) -eq $true) {
            
            Write-Host "Site Exists so, Remove-PnPTenantSite Started for $globalhubSiteUrl"
            $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $globalhubSiteUrl")
            
            Remove-PnPTenantSite -Url $globalhubSiteUrl -Force -SkipRecycleBin
            
            Write-Host "Remove-PnPTenantSite Completed for $globalhubSiteUrl"
            $client.TrackEvent("Remove-PnPTenantSite Completed for $globalhubSiteUrl")
        }
                
        foreach($sectorhubsite in $globalhubsite.sectorhubsite.site)
        {
           $sectorhubSiteUrl = $urlprefix + $sectorhubsite.Alias
                   
           $siteExits = Get-PnPTenantSite -Url $sectorhubSiteUrl -ErrorAction SilentlyContinue
           
           if ([bool] ($siteExits) -eq $true) {
               
               Write-Host "Site Exists so, Remove-PnPTenantSite Started for $sectorhubSiteUrl"
               $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $sectorhubSiteUrl")
               
               Remove-PnPTenantSite -Url $sectorhubSiteUrl -Force -SkipRecycleBin

               Write-Host "Remove-PnPTenantSite Completed for $sectorhubSiteUrl"
               $client.TrackEvent("Remove-PnPTenantSite Completed for $sectorhubSiteUrl")
           }           

           foreach($orgassociatedsite in $sectorhubsite.orgassociatedsite.site)
            {

               $orgSiteUrl = $urlprefix + $orgassociatedsite.Alias
                                       
               $siteExits = Get-PnPTenantSite -Url $orgSiteUrl -ErrorAction SilentlyContinue
                    
               if ([bool] ($siteExits) -eq $true) {
                   
                   Write-Host "Site Exists so, Remove-PnPTenantSite Started for $orgSiteUrl"
                   $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $orgSiteUrl")
                   
                   Remove-PnPTenantSite -Url $orgSiteUrl -Force -SkipRecycleBin

                   Write-Host "Remove-PnPTenantSite Completed for $orgSiteUrl"
                   $client.TrackEvent("Remove-PnPTenantSite Completed for $orgSiteUrl")
               }               
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
         }

       }

       foreach($globalsite in $sitefile.sites.Configsite.site)
     {
        try
        {
        $globalSiteUrl = $urlprefix + $globalsite.Alias
        $siteExits = Get-PnPTenantSite -Url $globalSiteUrl -ErrorAction SilentlyContinue
            
        if ([bool] ($siteExits) -eq $true) {
            
            Write-Host "Site Exists so, Remove-PnPTenantSite Started for $globalSiteUrl"
            $client.TrackEvent("Site Exists so, Remove-PnPTenantSite Started for $globalSiteUrl")
            
            Remove-PnPTenantSite -Url $globalSiteUrl -Force -SkipRecycleBin
            
            Write-Host "Remove-PnPTenantSite Completed for $globalSiteUrl"
            $client.TrackEvent("Remove-PnPTenantSite Completed for $globalSiteUrl")
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
}

    Disconnect-PnPOnline
}

<#
.SYNOPSIS
    This function is used to Delete all Content Types as per Sites.xml

.DESCRIPTION
    This function will use the PnP cmdlets to Delete all Content Types that
    is configured as per ContentType.xml.

.EXAMPLE
    DeleteContentTypes $scXML

.INPUTS

.OUTPUTS
    Status - $true for when the function has been able to Delete the requested Content Types as per ContentType.xml
             $false for when the function has not been able to Delete the requested sContent Types as per ContentType.xml
#>
function DeleteContentTypes($scXML)
{
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}

    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    Write-Host "Delete Content Types Started..."
    $client.TrackEvent("Delete Content Types Started...")

    foreach($contentItem in $scXML.Main.siteContentTypes.contentItem)
     {
        try
        {
            $ContentTypeExist = Get-PnPContentType -Identity $contentItem.ContentTypeName -ErrorAction SilentlyContinue
        
            if ([bool] ($ContentTypeExist) -eq $true) {
                $ct=$contentItem.ContentTypeName
                Write-Host "ContentType $ct Exists so, Remove-PnPContentType Started."
                $client.TrackEvent("ContentType $ct Exists so, Remove-PnPContentType Started.")
                
                Remove-PnPContentType -Identity $contentItem.ContentTypeName -Force -Connection $connection
                
                Write-Host "ContentType $ct Removed."
                $client.TrackEvent("ContentType $ct Removed.")
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
   }
    Disconnect-PnPOnline
}

<#
.SYNOPSIS
    This function is used to Delete all Site Columns as per Sites.xml

.DESCRIPTION
    This function will use the PnP cmdlets to Delete all Content Types that
    is configured as per SiteColumns.xml.

.EXAMPLE
    DeleteSiteColumns $siteColumnfilePathfile

.INPUTS

.OUTPUTS
    Status - $true for when the function has been able to Delete the requested Site Columns as per xml
             $false for when the function has not been able to Delete the requested Site Columns as per xml
#>

function DeleteSiteColumns($siteColumnfilePathfile)
{
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}

    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    Write-Host "Delete Site Columns Started..."
    $client.TrackEvent("Delete Site Columns Started...")
     
    foreach($field in $siteColumnfilePathfile.SiteFields.Field)
     {
        try
        {
            $getField = Get-PNPField -identity $field.ColumnName -ErrorAction SilentlyContinue
        
            if ([bool] ($getField) -eq $true) {
                $colName=$field.ColumnName
                Write-Host "Field $colName Exists so, Remove-PnPField Started."
                $client.TrackEvent("Field  $colName Exists so, Remove-PnPField Started.")
                
                Remove-PnPField -Identity $field.ColumnName -Force -Connection $connection
                
                Write-Host "Field  $colName  Removed."
                $client.TrackEvent("Field  $colName  Removed.")
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
        }
    Disconnect-PnPOnline
}

<#
.SYNOPSIS
    This function is used to Delete all Taxanomy and respective Taxanomy Group as per Taxonomy.xml

.DESCRIPTION
    This function will use the PnP cmdlets to Delete all Taxanomy and respective Taxanomy Group that
    is configured as per Taxonomy.xml.

.EXAMPLE
    DeleteSiteColumns $siteColumnfilePathfile

.INPUTS

.OUTPUTS
    Status - $true for when the function has been able to Delete all Taxanomy and respective Taxanomy Group as per xml
             $false for when the function has not been able to Delete all Taxanomy and respective Taxanomy Group as per xml
#>

function DeleteTaxanomyGroup($termsfile)
{
    $secstr = New-Object -TypeName System.Security.SecureString
    $sp_password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}

    $tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
    # Connect with the tenant admin credentials to the tenant
    Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
    $connection = Get-PnPConnection

    Write-Host "Delete Taxonomy Started..."
    $client.TrackEvent("Delete Taxonomy Started...")
     
    foreach($Group in $termsfile.TermStores.TermStore.Groups.Group)
     {
        try
        {
            $groupExists = Get-PnPTermGroup -identity $Group.Name -ErrorAction SilentlyContinue
        
            if ([bool] ($groupExists) -eq $true) {
                $groupName=$Group.Name
                Write-Host "Taxanomy Group $groupName Exists so, Remove-PnPTermGroup Started."
                $client.TrackEvent("Taxanomy Group $groupName Exists so, Remove-PnPTermGroup Started.")
                
                Remove-PnPTermGroup -GroupName $Group.Name -Force -Connection $connection
                
                Write-Host "Taxanomy Group $groupName Removed."
                $client.TrackEvent("Taxanomy Group $groupName Removed.")
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
        }
    Disconnect-PnPOnline
}


Complete-Cleanup