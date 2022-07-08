# LogicApp

This module is used to deploy an Azure Logic App.

This 2019-05-01 version of the Module allows for Access Control - i.e. restricting access to the content, trigger and actions of the Logic App with IP address ranges. 

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
| `parameters` | object | {} | Complex structure, see below. | Optional.
| `accessControl` | object | {} | Complex structure, see below. | Optional. The access control to the Logic App based on IP Ranges
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

### Parameter Usage: `accessControl`

```json
"accessControl": {
    "value": {
        "triggers": {
            "allowedCallerIpAddresses": [
                {
                "addressRange": "XXX.XXX.XXX.XXX-XXX.XXX.XXX.XXX" OR "XXX.XXX.XXX.XXX/XX"
                }
            ],
            "openAuthenticationPolicies": {
                "policies": {}
            }
        },
        "contents": {
            "allowedCallerIpAddresses": [
                {
                "addressRange": "XXX.XXX.XXX.XXX-XXX.XXX.XXX.XXX" OR "XXX.XXX.XXX.XXX/XX"
                }
            ],
            "openAuthenticationPolicies": {
                "policies": {}
            }
        },
        "actions": {
            "allowedCallerIpAddresses": [
                {
                "addressRange": "XXX.XXX.XXX.XXX-XXX.XXX.XXX.XXX" OR "XXX.XXX.XXX.XXX/XX"
                }
            ],
            "openAuthenticationPolicies": {
                "policies": {}
            }
        },
        "workflowManagement": {
            "allowedCallerIpAddresses": [
                {
                "addressRange": "XXX.XXX.XXX.XXX-XXX.XXX.XXX.XXX" OR "XXX.XXX.XXX.XXX/XX"
                }
            ],
            "openAuthenticationPolicies": {
                "policies": {}
            }
        }
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
