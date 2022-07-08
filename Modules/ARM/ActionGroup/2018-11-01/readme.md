# Action Group

This module is used to deploy an Action group used to perform actions or send notifications based on specific alerts.

## Resources

- Microsoft.Insights/actionGroups

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `actionGroupName` | string | | | Required. Name of the Action group.
| `actionGroupShortName` | string | | | Required. The short name of the action group. This will be used in SMS messages.
| `emailReceiverName` | string | | | Required. The name of the email receiver. Names must be unique across all receivers within an action group.
| `emailAddress` | string | | | Required. The email address of this receiver.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Environment.

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

## Additional resources

- [Introduction to Action Group](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups)
- [ARM Template format for Microsoft.Insights/actionGroups](https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/2018-03-01/actiongroups)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
