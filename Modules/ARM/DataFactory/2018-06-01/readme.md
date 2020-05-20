# Data Factory

This module deploys an empty Data Factory. 

## Resources

The following Resources are deployed.

- Microsoft.DataFactory/factories


## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `name` | string | | | Required. The name of the data factory.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `identity` | string | | | Optional. Identity for the data factory.
| `gitEnabled` | bool | `false` | | Set to true to integrate the data factory with GIT.
| `gitAccountName` | string | "" | | Required if gitEnabled is set to true. Account name of the git repository.
| `gitRepositoryName` | string | "" | | Required if gitEnabled is set to true. Name of the git repository.
| `gitBranchName` | string | `master` | | Required if gitEnabled is set to true. Collaboration branch name.
| `gitRootFolder` | string | `/` | | Required if gitEnabled is set to true. Root folder.
| `gitProjectName` | string | "" | | Required if gitEnabled is set to true. Project name of the git repository.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Data Factory resource.

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
| :-          | :-          |
| `dataFactoryname` |  The name of the data factory.


## Scripts

- There is no Scripts for this Module

## Considerations

- There is no deployment considerations for this Module

## Additional resources

- [Microsoft Data Factory template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/2018-06-01/factories)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)