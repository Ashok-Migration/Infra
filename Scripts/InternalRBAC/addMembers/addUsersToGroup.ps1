[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$groupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$usersCSVPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantName = 'tasmusqcp.onmicrosoft.com'
)

Connect-AzureAD -TenantDomain $tenantName

#import users from csv
$users = import-csv $usersCSVPath
$extension = "#EXT#@" + $tenantName

try {
    $group = Get-AzureADGroup -SearchString $groupName
    if ([string]::IsNullOrEmpty($group) -or [string]::IsNullOrEmpty($group[0].ObjectId)) {
        Write-Host "Group: '$($groupName)' Not found!'" 
        return
    }
    $groupInfo = $group[0]
    foreach ($user in $users) {
        $mail = ""

        if ($user.UserType -eq "Member") {
            $mail = $user.Email
        }
        else {
            $mail = -join ($user.Email.Replace("@", "_"), $extension)
        }

        $userInfo = Get-AzureADUser -objectId $mail
        if ([string]::IsNullOrEmpty($userInfo) -or [string]::IsNullOrEmpty($userInfo.ObjectId)) {
            Write-Host "User: '$($mail)' Not found!. Cannot add to the Group: '$($groupInfo.DisplayName)'" 
        }
        else {
            $grpUsr = Get-AzureADGroupMember -ObjectId $groupInfo.ObjectId | Where-Object { $_.objectId -eq $userInfo.ObjectId }
            if ($grpUsr -ne $null) {
                Write-Host "User: '$($mail)' already exists in the Group: '$($groupInfo.DisplayName)'"
            }
            else {
                Add-AzureADGroupMember -ObjectId $groupInfo.ObjectId -RefObjectId $userInfo.ObjectId
                Write-Host "User: '$($mail)' added to the Group: '$($groupInfo.DisplayName)'" 
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