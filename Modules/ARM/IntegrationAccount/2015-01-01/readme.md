# Integration Account

This module is used to deploy an Integration Account.

## Resources

- Microsoft.Logic/IntegrationAccounts

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `name` | string |  |  | Name of the integration account.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `sku` | string |  |  | The sku for integration account.
| `integrationAccountApiVersion` | string | 2016-06-01 | | API version for integration account.
| `diagnosticLogsRetentionInDays` | int | 365 |  | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string |  |  | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string |  |  | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string |  |  | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string |  |  | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.

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

This is a generic module for deploying Integration Account.

## Additional resources

- [Azure Integration Account documentation](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-create-integration-account?tabs=azure-portal)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
