# IntegrationServiceEnvironment

This module is used to deploy an Azure Integration Service Environment.

## Resources

* Microsoft. Logic/integrationServiceEnvironment

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `integrationServiceEnvironmentName` | string | | | Required. Name of the Integration Service EnvironmentName.
| `integrationServiceEnvironmentLocation` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `skuName` | string | | | Required.
| `skuCapacity` | int | 0 | | Required.
| `subnetResourceIds` | array | | | Required.
| `accessEndpoint` | object | {} | Complex structure, see below. | Optional.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

``` json
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

### Parameter Usage: `accessEndpoint`

``` json
"accessEndpoint": {
      "value": {
        "type": "Internal"
      }
    }
```

## Outputs

| Output Name | Description |
| :- | :- |

## Considerations

This is a generic module for deploying a Integration Service Environment.

## Additional resources

* [Azure Integration Service Environment documentation](https://docs.microsoft.com/en-us/azure/logic-apps/connect-virtual-network-vnet-isolated-environment-overview)
* [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
