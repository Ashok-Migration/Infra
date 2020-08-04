# AutomationAccounts

This module deploys an Azure Automation Account, with resource lock.

## Resources

- Microsoft.Automation/automationAccounts
- Microsoft.Automation/automationAccounts/providers/diagnosticsettings
- Microsoft.Automation/automationAccounts/providers/locks

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `automationAccountName` | | Required. Name of the Azure Automation Account
| `location` | `[resourceGroup().location]` | Optional. Location for all resources.
| `skuName` | `Basic` | Optional. Specifies the SKU for the Automation Account
| `softwareUpdateConfigurations` | [] | Optional. List of software update schedules.
| `diagnosticLogsRetentionInDays` | `365` | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `lockForDeletion` | `true` | Optional. Switch to lock Automation Account from deletion.
| `tags` | | Optional. Tags of the Automation Account resource.

### Parameter Usage: `softwareUpdateConfigurations`

```json
"softwareUpdateConfigurations": {
  "value": [{
          "name": "2019_12_UpdateLinuxMachines",
          "properties": {
              "updateConfiguration": {
                  "operatingSystem": "Linux",
                  "windows": null,
                  "linux": {
                      "includedPackageClassifications": "Critical, Security, Other",
                      "excludedPackageNameMasks": null,
                      "includedPackageNameMasks": null,
                      "rebootSetting": "IfRequired",
                      "IsInvalidPackageNameMasks": false
                  },
                  "targets": {
                      "azureQueries": [{
                          "scope": [
                              "/subscriptions/12345678-1234-1234-1234-123456789012"
                          ],
                          "tagSettings": {
                              "tags": {},
                              "filterOperator": "All"
                          },
                          "locations": []
                      }],
                      "nonAzureQueries": null
                  },
                  "duration": "PT2H",
                  "azureVirtualMachines": null,
                  "nonAzureComputerNames": null
              },
              "scheduleInfo": {
                  "frequency": "OneTime",
                  "timeZone": "UTC",
                  "startTime": "2019-12-04T10:00:00+01:00",
                  "nextRun": "2019-12-04T10:00:00+01:00"
              },
              "tasks": {
                  "preTask": null,
                  "postTask": null
              }
          }
      },
      {
          "id": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-weu-x-modules/providers/Microsoft.Automation/automationAccounts/acf-sb-ccoe-np-01-euw-aut-validate-01/softwareUpdateConfigurations/TestUpdateSchedule",
          "name": "2019_12_UpdateWindowsMachines",
          "properties": {
              "updateConfiguration": {
                  "operatingSystem": "Windows",
                  "windows": {
                      "includedUpdateClassifications": "Critical, Security, UpdateRollup, FeaturePack, ServicePack, Definition, Tools, Updates",
                      "excludedKbNumbers": null,
                      "includedKbNumbers": null,
                      "rebootSetting": "IfRequired",
                      "IsInvalidKbNumbers": false
                  },
                  "linux": null,
                  "targets": {
                      "azureQueries": [{
                          "scope": [
                              "/subscriptions/12345678-1234-1234-1234-123456789012"
                          ],
                          "tagSettings": {
                              "tags": {},
                              "filterOperator": "All"
                          },
                          "locations": []
                      }],
                      "nonAzureQueries": null
                  },
                  "duration": "PT2H",
                  "azureVirtualMachines": null,
                  "nonAzureComputerNames": null
              },
              "scheduleInfo": {
                  "frequency": "OneTime",
                  "timeZone": "UTC",
                  "startTime": "2019-12-04T10:00:00+01:00",
                  "nextRun": "2019-12-04T10:00:00+01:00"
              },
              "tasks": {
                  "preTask": null,
                  "postTask": null
              }
          }
      }
  ]
}
```

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

```json
"tags": {
    "value": {
        "Environment": "Non-Prod",
        "Contact": "test.user@testcompany.com",
        "PurchaseOrder": "1234",
        "CostCenter": "7890",
        "ServiceName": "DeploymentValidation",
        "Role": "DeploymentValidation"
    }
}
```

## Outputs

| Output Name | Description |
| :-          | :-          |
| `automationAccountResourceId` | The Resource Id of the Automation Account.
| `automationAccountResourceGroup` | The Resource Group the Automation Account was deployed to.
| `automationAccountName` | The Name of the Automation Account.

## Considerations

*N/A*

## Additional resources

- [An introduction to Azure Automation](https://docs.microsoft.com/en-us/azure/automation/automation-intro)
- [Microsoft.Automation automationAccounts template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.automation/allversions)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)