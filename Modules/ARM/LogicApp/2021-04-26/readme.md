# LogicApp

This module is used to deploy an Azure Logic App.

This module is the 2021-10-01 version which does not have accessControl by IP parameters. Use the 2019-05-01 module if you need this feature, i.e. when using a HTTP Trigger. 
This module is used to deploy Logic Apps inside Integration Service Environment.

## Resources

- Microsoft.Logic/workflows

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `workflowName` | string | | | Required. Name of the workflow.
| `workflowLocation` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `workflowSchema` | string | | | Required.
| `logicAppState` | string | `Enabled` | | Optional.
| `definition` | string | | | Optional.
| `integrationServiceEnvironment` | string |  | Required. Integration Service Environment ID
| `parameters` | object | {} | Complex structure, see below. | Optional.
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
| `LogicAppRegion` | The Region of the LogicApp. |
| `LogicAppResourceGroup` | The name of the Resource Group the LogicApp was created in. |

## Considerations

This is a generic module for deploying a Logic App.

## Additional resources

- [Azure Logic Apps documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
