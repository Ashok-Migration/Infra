# FunctionApp

This module (2020-09-01) is used to deploy Function App QnA with Virtual Network Integration and Access Restrictions, to deploy without these 2 components use 2018-11-01 module.

## Resources

- Microsoft.Web/sites

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `alwaysOn` | bool | | | Prevents your app from being idled out due to inactivity.
| `functionAppName` | string | | | Required. The name of the function app.
| `appInsightsResourceId` | string | | | Resource Id of AppInsights.
| `hostingPlanName` | string | | | The name of hosting plan.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `storageAccountName` | string | | | The name of storage account.
| `storageResourceGroup` | string | | | The name of storage account resource group.
| `runtimeValue` | string | | `dotnet, dotnet-isolated, java, node, powershell, python` | The language worker runtime to load in the function app.
| `diagnosticLogsRetentionInDays` | int | 365 | minValue: 0, maxvalue: 365 | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string | null |  | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string | null |  | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string | null |  | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string | null |  | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `appConfigEndpoint` | string | | | App configuration endpoint.
| `serviceBusSecretUri` | string | | | Key vault URI for service bus connection string.
| `vnetName` | string | null | | The name of the virtual network to be created.
| `ipSecurityRestrictions` | array | [] |  |IP based access restrictions.
| `subnetResourceId` | string | null | | ResourceId of subnet.
| `blobAccountConnectionString` | securestring | null | | KeyVault reference for Connection String of blob account.
| `http20Enabled` | bool | false | | Configures a web site to allow clients to connect over http2.0.
| `ftpsState` | string | null | | State of FTP / FTPS service.
| `healthCheckPath` | string | `/` | | Health check path.


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

## Considerations

This is a generic module for deploying Function App QnA.

## Additional resources

- [Azure Functions documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
