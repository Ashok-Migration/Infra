[CmdletBinding()]
param (
    $tenant,
    $sp_user,
    $sp_password
)

$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr

#Set Parameters
[System.Collections.ArrayList]$siteUrls = @()
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-marketplace")
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-sector-crosssector")
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-sector-healthcare")
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-sector-transportation")
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-sector-logistics")
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-sector-sports")
$siteUrls.Add("https://$($tenant).sharepoint.com/sites/cms-sector-environment")


[System.Collections.ArrayList]$listNames = @()
$listNames.Add("Product Media Assets")
$listNames.Add("Product Assets")
$listNames.Add("Media Assets")
$listNames.Add("Hero Web")
$listNames.Add("Hero Mobile")
$listNames.Add("Public Documents")
$listNames.Add( "Operation Documents")

[System.Collections.ArrayList]$fieldNames = @()
$fieldNames.Add("cdnurl")
$fieldNames.Add("cmsversion")



<# Functions starts #>

function Read-Sites {
    param (
        $siteUrls,
        $tenantAdmin,
        $listNames,
        $fieldNames
    )
    
    try {
        Write-Host "****************** Script Started *****************" -ForegroundColor Green
        # Connection 
        foreach ($siteUrl in $siteUrls) {
            try {
                 Write-host "`nChecking the site: $($siteUrl)`n" -ForegroundColor Green
                Connect-PnPOnline -Url $siteUrl -Credentials $tenantAdmin
                $ctx = Get-PnPContext
                Read-Lists -context $ctx -listNames $listNames -fieldNames $fieldNames 
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Host $ErrorMessage -foreground Red        
            }
        }        
        Write-Host "`n***************** Script End  *****************" -ForegroundColor Green
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red
    }
}
function Read-Lists {
    param (
        $context,
        $listNames,
        $fieldNames
    )
    
    try {
        foreach ($listName in $listNames) {
            try {
                $list = Get-PnpList | Where-Object { $_.Title -eq $listName }
                if ($null -ne $list) {
                    Write-host "`nChecking the list: $($list.Title)`n" -ForegroundColor Green
                    # list Fields 
                    $ctx.Load($list.Fields)
                    $ctx.ExecuteQueryAsync()
                    $fields = $list.Fields
                    foreach ($field in $fields) {
                        Update-FieldHiddenProperty -field $field -fieldNames $fieldNames
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Host $ErrorMessage -foreground Red        
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red
    }
}

function Update-FieldHiddenProperty {
    param (
        $field,
        $fieldNames
    )
    
    try {
        foreach ($fieldName in $fieldNames) {
            try {
                if ($field.InternalName -eq $fieldName) {
                    Write-Host "Checking the Hidden property for the field $($field.InternalName) for the list/library $($list.Title) : $($field.Hidden)" -ForegroundColor Yellow

                    # Not showing the field in New & Edit Forms
                    $field.SetShowInEditForm($false)
                    $field.SetShowInNewForm($false)

                    if ($field.Hidden -eq "True") {
                        $field.Hidden = $false
                        Write-Host "Hidden property value post update is : $($field.Hidden)" -f Yellow
                        Write-Host "$($field.Title) Hidden property is updated" -ForegroundColor Green
                    }
                    $field.Update()
                    $field.Context.ExecuteQuery()

                    break;
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Host $ErrorMessage -foreground Red        
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage -foreground Red
    }
}
<# Function ends #>

Read-Sites -siteUrls $siteUrls -tenantAdmin $tenantAdmin -listNames $listNames -fieldNames $fieldNames