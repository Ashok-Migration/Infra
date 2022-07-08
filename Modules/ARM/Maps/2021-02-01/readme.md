# Azure Maps

This module is used to deploy a Azure Maps instance.

## Resources

- Microsoft.Maps/accounts

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `name` | string | | | Required. Resource name.
| `location` | string | `[resourceGroup().location]` | | Required. Location for all resources.
| `sku` | string |  | S0, S1, G2 | Required. Resource SKU.
| `kind` | string |  | Gen1, Gen2 | Required. Resource Kind.
| `disableLocalAuth` | bool | true | | Required. Allows toggle functionality on Azure Policy to disable Azure Maps local authentication support. This will disable Shared Keys authentication from any usage.
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

This is a generic module for deploying Azure Maps instance.

## Additional resources

- [Azure Maps](https://docs.microsoft.com/en-us/azure/templates/microsoft.maps/accounts?tabs=json)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
