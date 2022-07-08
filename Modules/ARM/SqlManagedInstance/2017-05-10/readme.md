# SQL Managed Instance

This module is used to deploy a Sql Managed Instance inside an existing but empty virtual network and subnet. 
For development environment, NSG and UDR will also be created.

## Resources

- Microsoft.Sql/managedInstances
- Microsoft.Network/networkSecurityGroups
- Microsoft.Network/routeTables


## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `managedInstanceName` | string | | | Required. Name of the SQL Managed Instance.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `administratorLogin` | string | | | Required. Administrator account login.
| `administratorLoginPassword` | securestring | | | Required. Administrator account login password.
| `skuName` | string | `GP_Gen4` | | Required. The name of the SKU.
| `skuEdition` | string | `GeneralPurpose` | | Optional. The tier or editional of the particular SKU.
| `storageSizeInGB` | int | 32 | minValue: 32, maxValue: 8192, increments of 32 GB allowed only. | Optional. Storage size in GB. 
| `vCores` | int | 16 | 8, 16, 24, 32, 40, 64, 80 | Optional. The number of vCores.
| `licenseType` | string | `LicenseIncluded` | LicenseIncluded, BasePrice | Optional. The license type.
| `hardwareFamily` | string | `Gen4` | | Optional. If the service has different generations of hardware, for the same SKU, then that can be captured here.
| `collation` | string | `SQL_Latin1_General_CP1_CI_AS` | | Optional. Collation of the managed instance.
| `proxyOverride` | string | `Proxy` | Proxy, Redirect | Optional. Connection type used for connecting to the instance.
| `publicDataEndpointEnabled` | bool | false | | Optional. Whether or not the public data endpoint is enabled.
| `timezoneId` | string | `UTC`| Timezones supported by Windows. | Id of the timezone.
| `virtualNetworkResourceGroupName` | string | | | Optional. The resource group where the virtual network is placed.
| `virtualNetworkName` | string | | | Required. Virtual network in which the managed instance will be created.
| `subnetName` | string | | | Required. Subnet in which the managed instance will be created.
| `identity` | string | `SystemAssigned` | | Optional. The Azure Active Directory identity of the managed instance.
| `createNSG` | bool | false | | Optional. Set to false if the NSG already exists. Set to true if it is needed to create the NSG.
| `removedNSG` | bool | false | | Optional. Condition for NSG Allow All.
| `createRT` | bool | false | | Optional. Set to false if the RT already exists. Set to true if it is needed to create the RT.
| `nsgForPublicEndpoint` | string | "" | | Optional. NSG for public endpoint.
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

## Outputs

| Output Name | Description |
| :- | :- |
| `sqlManagedInstanceName` | The name of the managed instance created.
| `subnetId` | The subnet where the managed instance created. |


## Considerations

N/A

## Additional resources

- [ARM Template format for Microsoft.Sql/managedInstances](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2018-06-01-preview/managedinstances)
- [Network requirements for Sql Managed Instance](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture#network-requirements)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
