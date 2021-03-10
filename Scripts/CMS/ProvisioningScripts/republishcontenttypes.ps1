
[CmdletBinding()]
param (
  $tenant,
  $sp_user,
  $sp_password
)

Write-host "Started" -ForegroundColor Green
Write-host $tenant -ForegroundColor Yellow

$paramslogin = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; }
$psspologin = Resolve-Path $PSScriptRoot".\spologin.ps1"
$loginResult = .$psspologin  @paramslogin
if ($null -ne $loginResult) {
  $webparams = @{tenant = $tenant; sp_user = $sp_user; sp_password = $sp_password; fedAuth = $loginResult.FedAuth; rtFA = $loginResult.RtFa }
}

$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
$tenantAdmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $sp_user, $secstr
$contenttypehub = "https://$tenant.sharepoint.com/sites/contenttypehub"
Connect-PnPOnline -Url $contenttypehub -Credentials $tenantAdmin

$CTs = Get-PnPContentType 
$tasmuCTs = $CTs | Where-Object { $_.Group -eq "TASMU" }
foreach ($ct in $tasmuCTs) {
  write-host "Re-publishing CT $($ct.Name): " -NoNewline    
    
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession 
  $cookieCollection = New-Object System.Net.CookieCollection 
  $cookie1 = New-Object System.Net.Cookie 
  $cookie1.Domain = "$tenant.sharepoint.com" 
  $cookie1.Name = "FedAuth" 
  $cookie1.Value = $fedAuth
  $cookieCollection.Add($cookie1) 
  $cookie2 = New-Object System.Net.Cookie 
  $cookie2.Domain = "$tenant.sharepoint.com" 
  $cookie2.Name = "rtFa" 
  $cookie2.Value = $rtFA
  $cookieCollection.Add($cookie2) 
  $session.Cookies.Add($cookieCollection) 

  $ctUrl = "https://$tenant.sharepoint.com/sites/contentTypeHub/_layouts/15/managectpublishing.aspx"
  $ctId = $ct.Id # "0x01005E7A4F91FBA12643B747364A2D99D156"
  $url = "$($ctUrl)?ctype=$ctId"

  $response = Invoke-WebRequest -Uri $url -Method Get -WebSession $session
  $form = $response.Forms[0]
  $fields = $form.Fields

  $body = New-Object 'system.collections.generic.dictionary[[string],[object]]'
  $fields.keys | ForEach-Object {
    $key = $_
    $value = $fields[$_]
    if ($key -contains "ctl00") {
      # Skip
    }
    else {
      $body[$key] = $value
    }
  }
  $body['ctl00$PlaceHolderMain$actionSection$RadioGroupAction'] = 'republishButton'
  $body['ctl00$PlaceHolderMain$ctl00$RptControls$okButton'] = 'OK'
  $response = Invoke-WebRequest -Uri $url -Method Post -WebSession $session -Body $body
  write-host "Done" -ForegroundColor Green 
}

Write-Host 'Content type re-published completed in Content Type Hub successfully' -ForegroundColor Green