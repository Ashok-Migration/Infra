# Azure Cache for Redis

This module is used to deploy a Azure Cache for Redis instance.

This module is the 2019-07-01 version which does not has availability zones. Use the 2020-06-01 module if you need availability zones. 

## Resources

- Microsoft.Cache/Redis

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `enableNonSslPort` | bool | false | true/false | Set to true to allow access to redis on port 6379, without SSL tunneling (less secure).
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `redisCacheCapacity` | int | 1 | 1,2,3,4 | The size of the new Azure Redis Cache instance. Valid family and capacity combinations are (C0..C6, P1..P4).
| `redisCacheName` | string | | | The name of the Azure Redis Cache to create.
| `redisShardCount` | int | | | Number of highly available shards to create in the cluster. Requires Premium SKU.
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

This is a generic module for deploying Azure Cache for Redis instance.

## Additional resources

- [Azure Cache for Redis documentation](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
