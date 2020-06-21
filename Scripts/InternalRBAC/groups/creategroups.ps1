[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantName = 'tasmusqcp.onmicrosoft.com',

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$securityGroupsCSVPath
)
#Connect to the tenant
Connect-AzureAD -TenantDomain $tenantName

#Create New Group from CSV
$groups = import-csv $securityGroupsCSVPath

foreach($group in $groups)
{
  $grp = Get-AzureADGroup -SearchString $group.DisplayName
  if ($grp -eq $null)
  {
      Write-Host "Creating Group:'$($group.DisplayName)', Description: $($group.Description), Info: '$($group.MailNickName)'"

      $groupInfo = New-AzureADGroup -DisplayName $group.DisplayName -Description $group.Description -SecurityEnabled $true -MailEnabled $false -MailNickName $group.MailNickName

      Write-Host "Created Group:'$($groupInfo.DisplayName)'"
  }
  else
  {
      Write-Host "Group:'$($grp.DisplayName)' already exists. Proceeding without creating."
      $groupInfo = $grp
  }
}