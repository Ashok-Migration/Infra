[CmdletBinding()]
param (
    $tenant, # Enter the tenant name
    $sp_user,
    $sp_password
)

function Invoke-HttpPost($endpoint, $body, $headers, $session)
{
  $params = @{}
  $params.Headers = $headers
  $params.uri = $endpoint
  $params.Body = $body
  $params.Method = "POST"
  $params.WebSession = $session

  $response = Invoke-WebRequest @params -ContentType "application/soap+xml; charset=utf-8" -UseDefaultCredentials -UserAgent ([string]::Empty)
  $content = $response.Content

  return $content
}

$spUrl = "https://$tenant-admin.sharepoint.com"
$loginUrl = "https://login.microsoftonline.com/extSTS.srf"
$xmlContent = @"
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
      xmlns:a="http://www.w3.org/2005/08/addressing"
      xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <s:Header>
    <a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action>
    <a:ReplyTo>
      <a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address>
    </a:ReplyTo>
    <a:To s:mustUnderstand="1">https://login.microsoftonline.com/extSTS.srf</a:To>
    <o:Security s:mustUnderstand="1"
       xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <o:UsernameToken>
        <o:Username>$sp_user</o:Username>
        <o:Password>$sp_password</o:Password>
      </o:UsernameToken>
    </o:Security>
  </s:Header>
  <s:Body>
    <t:RequestSecurityToken xmlns:t="http://schemas.xmlsoap.org/ws/2005/02/trust">
      <wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy">
        <a:EndpointReference>
          <a:Address>$spUrl</a:Address>
        </a:EndpointReference>
      </wsp:AppliesTo>
      <t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType>
      <t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType>
      <t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType>
    </t:RequestSecurityToken>
  </s:Body>
</s:Envelope>
"@

$msoContent = Invoke-HttpPost $loginUrl $xmlContent # Invoke-WebRequest -Uri $loginUrl -Body $xmlContent -ContentType "application/soap+xml; charset=utf-8" -UseDefaultCredentials -UserAgent ([string]::Empty) # Invoke-HttpPost $loginUrl $xmlContent
[regex]$binarySecurityTokenRegex = "BinarySecurityToken Id=.*>([^<]+)<"
$binarySecurityTokenMatch = $binarySecurityTokenRegex.Match($msoContent).Groups[1]
$binaryToken = $binarySecurityTokenMatch.Value

$wsinginUrl = "https://$tenant.sharepoint.com/_forms/default.aspx?wa=wsignin1.0"
$wsinginResponse = Invoke-WebRequest -Method Post -Uri $wsinginUrl -Body $binaryToken
$cookies = $wsinginResponse.Headers.'Set-Cookie'

[regex]$rtFaRegex = "rtFa=([^;]+);\s"
$rtFaMatch = $rtFaRegex.Match($cookies).Groups[1]
$rtFa = $rtFaMatch.Value
$rtFa

[regex]$fedauthRegex = "FedAuth=([^;]+);\s"
$fedauthMatch = $fedauthRegex.Match($cookies).Groups[1]
$fedauth = $fedauthMatch.Value
$fedauth

return @{
  FedAuth = $fedauth;
  RtFa = $rtFa;
}