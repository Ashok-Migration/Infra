[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$targetGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$groupsCSVPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantName = 'tasmusqcp.onmicrosoft.com'
)

Connect-AzureAD -TenantDomain $tenantName

#import users from csv
$memberGroups = import-csv $groupsCSVPath

try {
    $targetGroup = Get-AzureADGroup -SearchString $targetGroupName
    if ([string]::IsNullOrEmpty($targetGroup) -or [string]::IsNullOrEmpty($targetGroup[0].ObjectId)) {
        Write-Host "Group: '$($targetGroupName)' Not found!'" 
        return
    }
    $groupInfo = $targetGroup[0]
    foreach ($memberGroup in $memberGroups) {
        
        $memberGroupInfo = Get-AzureADGroup -SearchString $memberGroup.Name
        if ([string]::IsNullOrEmpty($memberGroupInfo) -or [string]::IsNullOrEmpty($memberGroupInfo[0].ObjectId)) {
            Write-Host "Group: '$($memberGroup.Name)' Not found!'" 
        }
        else {
            $grpMember = Get-AzureADGroupMember -ObjectId $groupInfo.ObjectId | Where-Object { $_.objectId -eq $memberGroupInfo[0].ObjectId }
            if ($grpMember -ne $null) {
                Write-Host "Group: '$($memberGroupInfo[0].DisplayName)' already exists in the Group: '$($targetGroupName)'"
            }
            else {
                Add-AzureADGroupMember -ObjectId $groupInfo.ObjectId -RefObjectId $memberGroupInfo[0].ObjectId
                Write-Host "Group: '$($memberGroupInfo[0].DisplayName)' added to the Group: '$($groupInfo.DisplayName)'" 
            }
        }
    }
}
catch {
    ShowError $_.Exception.Message
}

function ShowError {
    $errorMessage = $args[0]
    write-host "------------------------------------------------------------------"
    Write-host "$errorMessage"
    write-host "------------------------------------------------------------------"
  }