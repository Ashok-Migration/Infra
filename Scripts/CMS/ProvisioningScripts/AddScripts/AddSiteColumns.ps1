<#
.DESCRIPTION
    This Script is for adding site columns to content type either in contenttypehub or in global/market place sitecollections
       **********  LOOKUP COLUMNS ARE NOT SUPPORTED    ********************
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : AddSiteColumns.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
12/09/2020  V1.0     Microsoft Services  Initial script creation
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
Write-host "Started" -ForegroundColor Green
Write-host $tenant -ForegroundColor Yellow
$arrContentTypesToPublish=@();

$siteColumns = $PSScriptRoot + '.\SiteColumns.xml'

Import-PackageProvider -Name "NuGet" -RequiredVersion "3.0.0.1" -Force
#Install-Module SharePointPnPPowerShellOnline -Force -Verbose -Scope CurrentUser

$parentDirectory = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf('\'))

$psfilepublishcontenttypescript = Resolve-Path $parentDirectory".\publishcontenttypes.ps1"
$psspologin = Resolve-Path $parentDirectory".\spologin.ps1"

$paramslogin = @{tenant=$tenant; sp_user=$sp_user; sp_password=$sp_password;}
$loginResult = .$psspologin  @paramslogin

#Setup Telemetry
Add-Type -Path (Resolve-Path $parentDirectory'\Assemblies\Microsoft.ApplicationInsights.dll')
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($parentDirectory, $TemplateParametersFile))
# Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
$JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
if ( $null -ne ($JsonParameters | Get-Member -Type NoteProperty 'parameters')) {
    $JsonParameters = $JsonParameters.parameters
}
$RoleName = $JsonParameters.RoleName.value
$client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
$client.InstrumentationKey = $InstrumentationKey 
if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
    $client.Context.Cloud.RoleName = $RoleName
}

#setup Auth
$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

[xml]$siteColumnsfile = Get-Content -Path $siteColumns

function AddSiteColumns {

    #check to see if the sitecolumns have mandatory columns in the xml provided
    $log = ValidateSiteColumns $siteColumnsfile
    
    if ($log -ne '') {
        Write-Host 'The following rows in SiteColumns.xml file have invalid/missing column attributes' -ForegroundColor Red
        Write-Host $log -ForegroundColor Red
    }
    else {
        
        Write-Host 'Connecting to sites...' -ForegroundColor Green
        $contenttypehub = "https://" + $tenant + ".sharepoint.com/sites/contentTypeHub"
        Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin
        $contenttypehubConnection = Get-PnPConnection

        $globalSite = "https://" + $tenant + ".sharepoint.com/sites/cms-global"
        Connect-PnPOnline -Url $globalSite -Credentials $tenantAdmin
        $globalSiteConnection = Get-PnPConnection

        $marketPlace = "https://" + $tenant + ".sharepoint.com/sites/cms-marketplace"
        Connect-PnPOnline -Url $marketPlace -Credentials $tenantAdmin
        $marketPlaceConnection = Get-PnPConnection

        foreach ($siteColumn in $siteColumnsfile.SiteFields.Field) {
            Write-Host 'Processing '$siteColumn.ColumnName -ForegroundColor Green
            $client.TrackEvent('Processing $siteColumn.ColumnName')

            #check if content type exists in contenttypehub
            $contentType = Get-PnPContentType -Identity $siteColumn.ContentType -Connection $contenttypehubConnection
             
            if ($null -eq $contentType) {
                #check if content type exists in cms-global
                $contentType = Get-PnPContentType -Identity $siteColumn.ContentType -Connection $globalSiteConnection
                if ($null -eq $contentType) {
                    #check if content type exists in cms-marketplace
                    $contentType = Get-PnPContentType -Identity $siteColumn.ContentType -Connection $marketPlaceConnection
                    if ($null -eq $contentType) {
                        Write-Host 'ContentType '$siteColumn.ContentType' not found in ContentTypeHub,cms-global and cms-marketplace' -ForegroundColor Red
                        $client.TrackEvent('ContentType $siteColumn.ContentType not found in contenttypehub, cms-global and cms-marketplace' )
                    }
                    else {
                        AddSiteColumnConditionally $siteColumn $contentType $marketPlaceConnection
                    }
                }
                else {
                    AddSiteColumnConditionally $siteColumn $contentType $globalSiteConnection
                }
            }
            else {
                AddSiteColumnConditionally $siteColumn $contentType $contenttypehubConnection
                $arrContentTypesToPublish+=$siteColumn.ContentType
            }
        }

       if($arrContentTypesToPublish.Length -gt 0 -and $null -ne $loginResult)
       {
           Write-Host 'Republishing content types' -ForegroundColor Green
           $client.TrackEvent('Publishing content types')
           $arrContentTypesToPublish=$arrContentTypesToPublish | Select-Object -Unique
           
           $webparams = @{tenant=$tenant; TemplateParametersFile=$TemplateParametersFile; sp_user=$sp_user; sp_password=$sp_password; InstrumentationKey=$InstrumentationKey; fedAuth=$loginResult.FedAuth; rtFA=$loginResult.RtFa;arrContentTypesToPublish=$arrContentTypesToPublish}
           .$psfilepublishcontenttypescript @webparams
       }

        Disconnect-PnPOnline
    } 
    Write-Host 'completed' -ForegroundColor Green
    $client.TrackEvent('completed')
}

function ValidateSiteColumns ($siteColumnsfile) {
    $log = ''
    $rowNo = 2
    foreach ($cols in $siteColumnsfile.SiteFields.Field) {
        $missingColumns = ''
        if ($null -eq $cols.ColumnName -or $cols.ColumnName -eq '') {
            $missingColumns += 'ColumnName;'
        }
        if ($null -eq $cols.ColumnTitle -or $cols.ColumnTitle -eq '') {
            $missingColumns += 'ColumnTitle;'
        }
        if ($null -eq $cols.GroupName -or $cols.GroupName -eq '') {
            $missingColumns += 'GroupName;'
        }
        if ($null -eq $cols.ColumnType -or $cols.ColumnType -eq '') {
            $missingColumns += 'ColumnType;'
        }
        elseif ($cols.ColumnType -eq 'Lookup') {
            $missingColumns += 'Lookup columns are not supported;'
        }
        if ($null -eq $cols.ColumnChoices -or $cols.ColumnChoices -eq '') {
            $missingColumns += 'ColumnChoices;'
        }
        if ($null -eq $cols.Required -or $cols.Required -eq '') {
            $missingColumns += 'Required;'
        }
        if ($null -eq $cols.Format -or $cols.Format -eq '') {
            $missingColumns += 'Format;'
        }
        if ($null -eq $cols.showInNewEditForm -or $cols.showInNewEditForm -eq '') {
            $missingColumns += 'showInNewEditForm;'
        }
        if ($null -eq $cols.ContentType -or $cols.ContentType -eq '') {
            $missingColumns += 'ContentType;'
        }
        if ($missingColumns -ne '') {
            $log += "Row $rowNo : $missingColumns `n"
        }
        $rowNo++
    }

    return $log
}

function Create-SiteColumn( $connection, $ColumnTitle, $ColumnName, $GroupName, $columnType, $ChoiceOptions, $Required, $Format, $TermSetPath, $showInNewEditForm, $isSingleSelect, $isRichText, $defaultValue, $enforceUniqueValues, $indexed, $columnFormatting, $message, $description, $validation) {
    Try {

        if ([string]::IsNullOrWhiteSpace($enforceUniqueValues)) {
            $enforceUniqueValues = 'FALSE'  
        }

        if ([string]::IsNullOrWhiteSpace($indexed)) {
            $indexed = 'FALSE'  
        }

        Write-Host "Site column not found ,so creating a new site column- $ColumnName....." -ForegroundColor Green
        $client.TrackEvent("Site column not found ,so creating a new site column- $ColumnName.....")

        if ($ColumnType -eq "Choice") {
            # Create new site column if site column does not exist                
            $Id = [GUID]::NewGuid()
            if ($null -eq $showInNewEditForm) {
                $showInNewEditForm = "TRUE"
            } 
            $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$columnType'
                DisplayName='$ColumnTitle'
                Required='$Required'
                Indexed='$indexed'
                Format='$Format'
				Group='$GroupName'                
                ShowInEditForm='$showInNewEditForm'
                ShowInNewForm='$showInNewEditForm'
                ID='$Id'
                Name='$ColumnName'>
                <Default>$defaultValue</Default> <CHOICES>$ChoiceOptions</CHOICES>
                </Field>"
        }
        elseif ($ColumnType -eq "Taxonomy") {
            if ($isSingleSelect -eq $True) {
                $addNewField = Add-PnPTaxonomyField -DisplayName $ColumnTitle -InternalName $ColumnName -TermSetPath $TermSetPath -Group $GroupName -Connection $connection
            }
            else {
                $addNewField = Add-PnPTaxonomyField -DisplayName $ColumnTitle -InternalName $ColumnName -TermSetPath $TermSetPath -Group $GroupName -MultiValue -Connection $connection
            }
        }
        elseif ($columnType -eq "Note") {
            if ($isRichText -eq $True) {
                $Id = [GUID]::NewGuid() 
                $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
				    DisplayName='$ColumnTitle' 
				    Required='$Required' 
				    EnforceUniqueValues='$enforceUniqueValues' 
				    Indexed='$indexed' Format='$Format' 
				    Group='$GroupName' 
				    FriendlyDisplayFormat='Disabled' 
				    StaticName='$ColumnName'
                    ID='$Id' 
                    UnlimitedLengthInDocumentLibrary ='TRUE'
				    Name='$ColumnName'
                    RichText='TRUE'
                    RichTextMode='FullHtml'
                    ShowInEditForm='$showInNewEditForm'
                    ShowInNewForm='$showInNewEditForm'>
		            </Field>"
            }
            else {
                $Id = [GUID]::NewGuid() 
                $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
				    DisplayName='$ColumnTitle' 
				    Required='$Required' 
				    EnforceUniqueValues='$enforceUniqueValues' 
				    Indexed='$indexed' Format='$Format' 
				    Group='$GroupName' 
				    FriendlyDisplayFormat='Disabled' 
				    StaticName='$ColumnName'
                    ID='$Id' 
                    UnlimitedLengthInDocumentLibrary ='TRUE'
				    Name='$ColumnName'
                    ShowInEditForm='$showInNewEditForm'
                    ShowInNewForm='$showInNewEditForm'>
		            </Field>"
            }
        } 
        elseif ($columnType -eq "Number") {
            $Id = [GUID]::NewGuid() 
            #$fieldXml = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Name='$ColumnName' ID='{$Id}' Decimals='0' Min='0' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Group='$GroupName'></Field>"
            if ($null -ne $validation) {
                $validation = $validation.Replace('>', '&gt;').Replace('<', '&lt;')
            }
            $fieldXml = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Name='$ColumnName' ID='{$Id}' Decimals='0' Min='0' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Group='$GroupName' Description='$description'><Validation Message='$message'>$validation</Validation></Field>"

            $addNewField = Add-PnPFieldFromXml -Connection $connection $fieldXml
        }
        elseif ($columnType -eq "Boolean") {
            $Id = [GUID]::NewGuid()
            if ($null -eq $showInNewEditForm) {
                $showInNewEditForm = "TRUE"
            }
            $addNewField = Add-PnPFieldFromXml -Connection $connection "<Field Type='$ColumnType'
				DisplayName='$ColumnTitle' 
				Required='$Required' 
				EnforceUniqueValues='$enforceUniqueValues' 
				Indexed='$indexed' 
				Group='$GroupName' 
				FriendlyDisplayFormat='Disabled' 
                StaticName='$ColumnName'
                ShowInEditForm='$showInNewEditForm'
                ShowInNewForm='$showInNewEditForm'
                ID='$Id' 
                Name='$ColumnName'>
                <Default>$defaultValue</Default>
		        </Field>"
        }
        else {
            $Id = [GUID]::NewGuid()
            $fieldXML = ""
            if ($null -eq $showInNewEditForm) {
                $showInNewEditForm = "TRUE"
            }
            if ($null -eq $defaultValue) {
                
                $fieldXML = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Format='$Format' Group='$GroupName' FriendlyDisplayFormat='Disabled' StaticName='$ColumnName' ShowInEditForm='$showInNewEditForm' ShowInNewForm='$showInNewEditForm' ID='$Id' Name='$ColumnName'></Field>"

            }
            else {
                $fieldXML = "<Field Type='$ColumnType' DisplayName='$ColumnTitle' Required='$Required' EnforceUniqueValues='$enforceUniqueValues' Indexed='$indexed' Format='$Format' Group='$GroupName' FriendlyDisplayFormat='Disabled' StaticName='$ColumnName' ShowInEditForm='$showInNewEditForm' ShowInNewForm='$showInNewEditForm' ID='$Id' Name='$ColumnName'><Default>$defaultValue</Default></Field>"
            }
            $addNewField = Add-PnPFieldFromXml -Connection $connection $fieldXML -ErrorAction Stop
        }
            
        $getField = Get-PNPField -identity $ColumnName -Connection $connection -ErrorAction SilentlyContinue

        if ($null -ne $columnFormatting) {
            $getField | Set-PnPField -Values @{CustomFormatter = $columnFormatting } -Connection $connection
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red
        
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    } 
}
function AddSiteColumnConditionally($siteColumn, $contentType, $connection) {
    
    try {
        Write-Host 'ContentType '$siteColumn.ContentType 'found at'$connection.Url -ForegroundColor Green
        $contentType.Context.Load($contentType.Fields)
        $contentType.Context.ExecuteQuery()

        #Check if content type already has the column
        $field = $contentType.Fields | Where-Object { $_.InternalName -eq $siteColumn.ColumnName }
        if ($null -eq $field) {
            #check if that sitecolumn is already created
            $field = Get-PNPField -identity $siteColumn.ColumnName -Connection $connection -ErrorAction SilentlyContinue
        
            if ($null -ne $field) {
                Write-Host 'Adding '$siteColumn.ColumnName' to ContentType '$siteColumn.ContentType' as it already exists' -ForegroundColor Green
                $client.TrackEvent('Adding $siteColumn.ColumnName to ContentType $siteColumn.ContentType as it already exists')

                if ($siteColumn.Required -eq "False") {
                    Add-PnPFieldToContentType -Field $siteColumn.ColumnName -ContentType $siteColumn.ContentType -ErrorAction Stop -Connection $connection
                }
                else {
                    Add-PnPFieldToContentType -Field $siteColumn.ColumnName -ContentType $siteColumn.ContentType -ErrorAction Stop -Connection $connection -Required
                }
            }
            else {

                $columnName = $siteColumn.ColumnName
                $columnTitle = $siteColumn.ColumnTitle
                $groupName = $siteColumn.GroupName
                $columnType = $siteColumn.ColumnType
                $columnFormatting = $siteColumn.ColumnFormatting
                $description = $siteColumn.Description
                $message = $siteColumn.Message
                $validation = $siteColumn.Validation

                $columnChoices = ''

                if ($columnType -eq 'Choice') {
                    $ChoiceOptions = ""
                    $Choices = $siteColumn.choicevalue.Split(",")
                    foreach ($Choice in $Choices) {
                        $ChoiceOptions = $ChoiceOptions + "<CHOICE>$Choice</CHOICE>"
                    }
                }

                $required = $siteColumn.Required
                $format = $siteColumn.Format
                $TermSetPath = $siteColumn.TermSetPath
                $isSingleSelect = $siteColumn.isSingleSelect
                $showInNewEditForm = $siteColumn.showInNewEditForm
                $isRichText = $siteColumn.isRichText
                $defaultValue = $siteColumn.DefaultValue
                $enforceUniqueValues = $siteColumn.EnforceUniqueValues
                $indexed = $siteColumn.Indexed

                Create-SiteColumn $connection $columnTitle $columnName $groupName $columnType $ChoiceOptions $required $format $TermSetPath $showInNewEditForm $isSingleSelect $isRichText $defaultValue $enforceUniqueValues $indexed $columnFormatting $message $description $validation

                Write-Host 'Adding '$siteColumn.ColumnName' to ContentType '$siteColumn.ContentType -ForegroundColor Green
                $client.TrackEvent('Adding $siteColumn.ColumnName to ContentType $siteColumn.ContentType')

                if ($siteColumn.Required -eq "False") {
                    Add-PnPFieldToContentType -Field $siteColumn.ColumnName -ContentType $siteColumn.ContentType -ErrorAction Stop -Connection $connection
                }
                else {
                    Add-PnPFieldToContentType -Field $siteColumn.ColumnName -ContentType $siteColumn.ContentType -ErrorAction Stop -Connection $connection -Required
                }
            }
        }
        else {
            Write-host $siteColumn.ColumnName ' already exists in the ContentType '$siteColumn.ContentType -ForegroundColor Red
            $client.TrackEvent('$siteColumn.ColumnName already exists in the ContentType $siteColumn.ContentType')
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red
    
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
        $telemtryException.Exception = $_.Exception.Message  
        $client.TrackException($telemtryException)
    }
}

AddSiteColumns