# ServiceBusNamespace

This module is used to deploy an Azure Service Bus Namespace.

This module is the 2021-03-18 version which enables private endpoints on the service bus resource.Refer 2017-04-01 module for deployment without private endpoint.

## Resources

- Microsoft.ServiceBus/namespaces

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `authorizationRules` | array | { "name": "RootManageSharedAccessKey", "properties": { "rights": [ "Listen", "Manage", "Send" ] } } | | Optional. Authorization Rules for the Event Hub namespace
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `serviceBusNamespaceName` | string | | | Name of the Service Bus namespace
| `serviceBusSku` | string | Standard | Basic, Standard, Premium | The messaging tier for service Bus namespace
| `diagnosticLogsRetentionInDays` | int | 365 | | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string | "" | | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string | "" | | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string | "" | | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string | "" | | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.
| `zoneRedundant` | bool | false | | Determines whether or not the resource is zone redundant
| `tags` | object | {} | Complex structure, see below. | Optional. Resource tags.
| `virtualNetworkRules` | array | [] |  | Virtual Network Rules.
| `trustedServiceAccessEnabled` | bool | false | | Determines whether or not to allow trusted Microsoft services to bypass the firewall.

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
| :- | :- |
| `NamespaceDefaultConnectionString` | The default connection string of the Service Bus Namespace. |
| `DefaultSharedAccessPolicyPrimaryKey` | The primary key of the Service Bus Namespace Resource. |

## Considerations

This is a generic module for deploying a Service Bus Namespace.

## Additional resources

- [Service Bus Namespace documentation](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
