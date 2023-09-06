[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$resourceCSVPath
)

#import users from csv
$resources = import-csv $resourceCSVPath

#define envs
[String[]]$envs = "sbx", "dev", "tst", "tra"

try {
    foreach ($env in $envs) {
        foreach ($resource in $resources) {
            $name = $resource.name.replace('*',$env)
            $rg = $resource.rg.replace('*',$env)
            $objectID = az storage account show -n $name -g $rg --query 'identity.principalId' -o tsv
            if ([string]::IsNullOrEmpty($objectID)) {
                Write-Host "Object ID for '$($name)' Not found!'"
            }
            else {
                Write-Host "Resource: '$($name)' Object ID: '$($objectID)'"
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