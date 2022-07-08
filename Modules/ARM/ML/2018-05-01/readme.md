# ML dedicated group -  Data Scientis Sample

This module is used to deploy a ML stuff deployment  resource 

## Resources

- Microsoft.PowerBIDedicated/capacities

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `name` | string | | minLength:3, maxLength:63 | Required. Name of the Powerbi Dedicated Capacity.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `sku` | string | | A1, A2, A3, A4, A5, A6 | Optional. Storage Account Sku Name.
| `admin` | array | [] | See below. | Required. An array of administration user identity
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Virtual Network Gateway resource.

### Parameter Usage: `admin`

The `admin` parameter accepts a JSON Array of string to specify the member users or service principals in the AAD tenant that will manage the capacity in Power BI.

Here's an example of specifying a single admin:

```json
[admin1@microsoft.com]
```

Here's an example of specifying multiple admins:

```json
[admin1@microsoft.com, admin2@microsoft.com]
```


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
| `powerbiName` | The name of the Powerbi Dedicated Capacity.

## Considerations

*N/A*

## Additional resources

- [ARM Template format for Microsoft.PowerBIDedicated/capacities](https://docs.microsoft.com/en-us/azure/templates/microsoft.powerbidedicated/2017-10-01/capacities)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
