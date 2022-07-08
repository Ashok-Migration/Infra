# SQLLogicalServer

This module is used to deploy an Azure SQL Logical Server.

## Resources

- Microsoft.Sql/servers
- Microsoft.Storage/storageAccounts

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `serverName` | string | | | Required. The name of the SQL logical server.
| `administratorLogin` | string | | | Required. The administrator username of the SQL logical server.
| `administratorLoginPassword` | string | | | Required. The administrator password of the SQL logical server.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `enableADS` | bool | `true` | | Optional. Enable Advanced Data Security, the user deploying the template must have an administrator or owner permissions.
| `allowAzureIPs` | bool | `true` | | Optional. Allow Azure services to access server.
| `connectionType` | string | `Default` | Default, Redirect, Proxy | "Optional. SQL logical server connection type.
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
| `ServerRegion` | The Region of the server. |
| `ServerResourceGroup` | The name of the Resource Group the server was created in. |

## Considerations

This is a generic module for deploying Azure SQL Logical Server.

## Additional resources

- [Azure SQL Database documentation](https://docs.microsoft.com/en-us/azure/sql-database/)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
