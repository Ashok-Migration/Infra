[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$mappingsCSVPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantName = 'tasmusqcp.onmicrosoft.com'
)

Connect-AzAccount -Tenant $tenantName
$mappings = import-csv $mappingsCSVPath

foreach ($mapping in $mappings) {
    $group = Get-AzureADGroup -SearchString $mapping.GroupName
    if ([string]::IsNullOrEmpty($group) -or [string]::IsNullOrEmpty($group[0].ObjectId)) {
        Write-Host "Group: '$($mapping.GroupName)' not found!'" 
        return
    }

    $roleName = $mapping.RoleName
    Set-AzContext -SubscriptionId $mapping.SubscriptionId
    $scope = "/subscriptions/$($mapping.SubscriptionId)"
    

    $objectId = $group.ObjectId
    $assignment = Get-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $roleName -Scope $scope

    if ($assignment -eq $null) {
        Write-Host "Assigning Role:'$($roleName)' on Susbcription:'$($mapping.SubscriptionId)' to group:'$($mapping.GroupName)'"
        New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName $roleName -Scope $scope
    }
    else {
        Write-Host "Role:'$($roleName)' on Susbcription:'$($mapping.SubscriptionId)' for group:'$($mapping.GroupName)' already exists"        
    }
}