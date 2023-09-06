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
[String[]]$envs = "dev", "sbx", "tst", "tra", "uat"

try {
    foreach ($env in $envs) {
        foreach ($resource in $resources) {
            $name = $resource.name.replace('*',$env)
            $rg = $resource.rg.replace('*',$env)
            $type = $resource.type
            $workspaceId = az monitor diagnostic-settings list --resource $name --resource-group $rg --resource-type $type  --query 'value[0].workspaceId' -o tsv
            if ([string]::IsNullOrEmpty($workspaceId)) {
                Write-Host "Workspace for '$($name)' Not found!'"
            }
            else {
                $workspaceName = az resource show --ids $workspaceId --query name -o tsv
                Write-Host "Resource: '$($name)' Log Workspace: '$($workspaceName)'"
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