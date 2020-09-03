# Webapp Bot service

This module is used to deploy webapp Bot service, with resource lock.
The default parameter values are based on the needs of deploying a webapp bot service.

## Resources

- Microsoft.BotService/botServices

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `webAppName` | string | | | Required. Name of the App service.
| `botId` | string | | | Required. Name of the bot service.
| `sku` | string | | | Required. Name of the SKU plan.
| `appInsightsName` | string | | | Required. Name of the App Insights service.
| `appId` | string | | | Required. Name of the App Id.
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

This is a generic module for deploying a App service. Any customization for different config needs need to be done through the Archetype.

## Additional resources

- [Introduction to Azure Bot Service](https://azure.microsoft.com/en-in/services/bot-service/)
- [ARM Template format for •Microsoft.BotService/botServices](https://docs.microsoft.com/en-us/azure/bot-service/bot-builder-deploy-az-cli?view=azure-bot-service-4.0&tabs=csharp)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
