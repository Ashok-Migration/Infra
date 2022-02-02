# SQL Single Database

This module is used to deploy an Azure Single Database.

## Resources

- Microsoft.Sql/servers/databases

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `databaseName` | string | | | Required. Name of the database name.
| `tier` | string | | | Required.
| `maxSizeBytes` | string | | | Required.
| `skuName` | string | | | Required.
| `serverName` | string | | | Required.
| `serverLocation` | string | | | Required.
| `collation` | string | | | Required.

| `sampleName` | string | "" | | Required.
| `zoneRedundant` | bool | false | | Required.
| `licenseType` | string | "" | | Required.
| `readScaleOut` | string | "Disabled" | | Required.
| `numberOfReplicas` | int | 0 | | Required.
| `minCapacity` | string | "" | | Required.
| `autoPauseDelay` | string | "" | | Required.
| `databaseTags` | object | {} | Complex structure, see below. | Optional. Tags of the resource.

### Parameter Usage: `databaseTags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

```json
"databaseTags": {
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
| `DBCollation` | The DB collation. |

## Considerations

This is a generic module for deploying a Single Database.

## Additional resources

- [SQL Single Database ARM Documentation](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
