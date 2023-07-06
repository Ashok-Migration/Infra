# ApiManagement

This module is used to deploy an Azure APIM.

## Resources

- Microsoft.ApiManagement/service

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `apiManagementServiceName` | string | | | Required. The name of the api management service
| `appInsightsId` | string | | | Resource Id of AppInsights.
| `publisherEmail` | string | | | The email address of the owner of the service.
| `publisherName` | string | | | The name of the owner of the service.
| `sku` | string | Developer | `"Basic","Consumption","Developer","Standard","Premium"` | The pricing tier of this API Management service.
| `skuCount` | int | 1 | | The instance size of this API Management service.
| `subnetName` | string | | |
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.
| `virtualNetworkName` | string | | | 
| `virtualNetworkType` | string | Internal | | The virtual network type.
| `vnetResourceGroup` | string | | | 
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `diagnosticLogsRetentionInDays` | int | 365 | minValue: 0, maxvalue: 365 | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string | null |  | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string | null |  | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string | null |  | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string | null |  | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `lockForDeletion` | bool | false | | Optional. Switch to lock APIM from deletion.
| `hostnameConfigurations` | array | [] | | Custom hostname configuration of the API Management service. |
| `windowSize` | string | PT5M | `"PT1M","PT5M","PT15M","PT30M","PT1H","PT6H","PT12H","PT24H" ` | Period of time used to monitor alert activity based on the threshold. Must be between one minute and one day. ISO 8601 duration format.
| `evaluationFrequency` | string | PT1M | `"PT1M","PT5M","PT15M","PT30M","PT1H"` | How often the metric alert is evaluated represented in ISO 8601 duration format.
| `requestsThreshold` | string | 1000 |  |The threshold value (count) at which the alert for metric Requests is activated.
| `durationThreshold` | string | 10000 |  |The threshold value (in milliseconds) at which the Overall Duration of Gateway Requests alert is activated.
| `actionGroupId` | string | null |  | The ID of the action group that is triggered when the alert is activated.

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

This is a generic module for deploying a APIM.

## Additional resources

- [Azure APIM documentation](https://docs.microsoft.com/en-us/azure/api-management/api-management-key-concepts)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
