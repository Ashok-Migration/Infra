# App service

This module is used to deploy an App service, with resource lock.
The default parameter values are based on the needs of deploying a diagnostic app service.

## Resources

- Microsoft.Web/sites

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `webAppName` | string | | | Required. Name of the App service.
| `hostingPlanName` | string | | | Required. Name of the Hosting plan for the  App service.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.
| `allowedOriginEndpoint` | string |  | Url of allowed origin header to be added for CORS header access.
| `http401Threshold` | string | 80 |  |The threshold value at which the alert Http 401 is activated.
| `http403Threshold` | string | 80 |  |The threshold value at which the alert Http 403 is activated.
| `actionGroupId` | string |  |  | The ID of the action group that is triggered when the alert is activated or deactivated.

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

- [Introduction to Azure App Service](https://azure.microsoft.com/en-in/services/app-service/)
- [ARM Template format for �Microsoft.Web/sites](https://docs.microsoft.com/en-us/azure/app-service/samples-resource-manager-templates)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
