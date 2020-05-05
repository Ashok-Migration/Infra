# vNet

This template deploys a virtual network links inside of the existing privte DNS zone.

## Resources

- Microsoft.Network/dnsZones

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `zoneName` | string | | | Required. The name of the private DNS zone within which virtual network lins are to be deployed.
| `vNets` | array | [] | | Required. List of vNets to link to the private DNS zone, every vNet is identified by the following parameters:<br>- subscriptionId - ID of the subscription, the vNet is located in<br>- resourceGroupName - name of the Resource Group, the vNet is located in<br>-vnetName - name of the vNet

### Parameter Usage: `zoneName`

The `zoneName` parameter accepts a JSON string value, containing the name of the private DNS zone to be created.

Example of specifying the private DNS zone name:

```json
"zoneName": {
            "value": "contoso.corp.com"
        }
```

### Parameter Usage: `vNets`

The `vNets` parameter accepts a JSON Array of objects, identifying virtual networks for virtual network links to be created in the private DNS zone, identified by the `zoneName` parameter.

Example of specifying virtual networks to create virtual network links for:

```json
"vNets": {
    "value" : [
        {
            "subscriptionId": "3af5b08c-8174-4667-ba30-c10132718e01",
            "resourceGroupName": "rg-net-shared-1",
            "vnetName": "vnet-shared-private-1"
        },
        {
            "subscriptionId": "d77b8d79-73be-40c1-836e-df6bc8172aea",
            "resourceGroupName": "rg-net-shared-2",
            "vnetName": "vnet-shared-private-1"
        }
    ]
}        
```

## Additional resources

- [Microsoft.Network virtualNetworks template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-09-01/privatednszones)
- [What is Azure Virtual Network?](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
