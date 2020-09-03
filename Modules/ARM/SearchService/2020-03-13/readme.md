# Search Service

This module is used to deploy an Search service, with resource lock.
The default parameter values are based on the needs of deploying a diagnostic search service.

## Resources

- Microsoft.Search/searchServices

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `searchServicesName` | string | | | Required. Name of the App service.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
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

- [Introduction to Azure Search Service](https://azure.microsoft.com/en-in/services/search/)
- [ARM Template format for •Microsoft.Search/searchServices](https://docs.microsoft.com/en-us/azure/templates/microsoft.search/searchservices)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
