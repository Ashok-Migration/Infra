# SynapseAnalytics

This module is used to deploy an Azure Synapse Analytics.

## Resources

- Microsoft.Sql/servers/databases

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `databaseName` | string | | | Required. Name of the database name.
| `skuName` | string | | | Required.
| `serverName` | string | | | Required.
| `serverLocation` | string | | | Required.
| `collation` | string | | | Required.
| `databaseTags` | object | {} | Complex structure, see below. | Optional. Tags of the resource.

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
| `DBCollation` | The DB collation. |

## Considerations

This is a generic module for deploying a Synapse Analytics.

## Additional resources

- [Azure Synapse Analytics Documentation](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
