[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CSVPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantName = 'tasmusqcp.onmicrosoft.com'
)

Connect-AzureAD -TenantDomain $tenantName

$invitations = import-csv $CSVPath

$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo

$messageInfo.customizedMessageBody = "Hello! You are invited to TASMU Central Platform Azure DevOps"

foreach ($email in $invitations)
   {New-AzureADMSInvitation `
      -InvitedUserEmailAddress $email.InvitedUserEmailAddress `
      -InvitedUserDisplayName $email.Name `
      -InviteRedirectUrl https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform `
      -InvitedUserMessageInfo $messageInfo `
      -SendInvitationMessage $true
   }

