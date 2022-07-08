[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$mappingsCSVPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantName = 'tasmusqcp.onmicrosoft.com'
)

Connect-AzAccount -Tenant $tenantName -SubscriptionId $subscriptionId 

$mappings = import-csv $mappingsCSVPath

foreach ($mapping in $mappings) {
    $group = Get-AzureADGroup -SearchString $mapping.GroupName
    if ([string]::IsNullOrEmpty($group) -or [string]::IsNullOrEmpty($group[0].ObjectId)) {
        Write-Host "Group: '$($mapping.GroupName)' not found!'" 
        continue
    }

    $objectId = $group.ObjectId
    $rgName = $mapping.ResourceGroup

    $rg = Get-AzResourceGroup -Name $rgName
    if ([string]::IsNullOrEmpty($rg) -or [string]::IsNullOrEmpty($rg.ResourceId)) {
        Write-Host "ResourceGroup: '$($rg)' not found!'" 
        continue
    }
    
    $roleName = $mapping.RoleName
    $assignment = Get-AzRoleAssignment -ObjectId $objectId -ResourceGroupName $rgName -RoleDefinitionName $roleName

    if ($assignment -eq $null) {
        Write-Host "Assigning Role:'$($roleName)' on Rg:'$($rgName)' to group:'$($mapping.GroupName)'"
        New-AzRoleAssignment -ObjectId $objectId -ResourceGroupName $rgName -RoleDefinitionName $roleName

    }
    else {
        Write-Host "Role:'$($roleName)' on Rg:'$($rgName)' for group:'$($mapping.GroupName)' already exists"        
    }
}