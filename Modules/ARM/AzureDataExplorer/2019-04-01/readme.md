# Azure Data Explorer

This module deploys Azure Data Explorer and two public IP addresses.

## Resources

- Microsoft.Kusto/Clusters
- Microsoft.Network/publicIPAddresses 

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `clusterName` | string | | | Required. 
| `skuName` | string | "Standard_D13_v2" | | Required. 
| `skuTier` | string | "Standard" | | Required. 
| `virtualNetworkName` | string | | | Required. 
| `subnetName` | string | | | Required. 
| `enginePublicIpName` | string | "engine-pip" | | Required. 
| `dataManagementPublicIpName` | string | "dm-pip" | | Required. 
| `publicIpAllocationMethod` | string | "Static" | | Required. 
| `location` | string | `[resourceGroup().location]` | | Required. 
| `tags` | string | `{}` | Complex structure, see below. | Optional. 
| 
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


## Considerations

## Additional resources

- [Azure Data Explorer template reference?](https://docs.microsoft.com/en-us/azure/templates/microsoft.kusto/clusters)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)