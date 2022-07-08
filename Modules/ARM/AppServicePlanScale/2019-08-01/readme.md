
# App Service Plan Scale - Create a scale-out rule

This template deploys an Scaling for app service plan.
The default parameter values are based on the needs of deploying a scale app plan.

## Resources

- Microsoft.Web/sites

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `hostPlanName` | string | | | Required. Name of the App service plan.
| `minimumCapacity` | int | | | Required. Minimum capcity of the App service plan.
| `maximumCapacity` | int | Required. Maximum capcity of the App service plan.
| `defaultCapacity` | Required. Default capcity of the App service plan.
| `metricName` | string | | | Required. Name of the Metrics.
| `metricThresholdToScaleOut` | int | | | Required. Metric threshold to scale out for the App service plan.
| `metricThresholdToScaleIn` | int | | | Required. Metric threshold to scale in for the App service plan.
| `changePercentScaleOut` | int | | | Required. Change percent scale out of the App service plan.
| `changePercentScaleIn` | int | | | Required. change percent scale in of the App service plan.
| `autoscaleEnabled` | bool | | | Required. whether auto scale is enabled.

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

## Considerations

This is a generic module for deploying a App service Scale Plan. Any customization for different config needs need to be done through the Archetype.

## Additional resources

- [Create an Autoscale Setting for Azure resources based on performance data or a schedule](https://docs.microsoft.com/en-us/azure/azure-monitor/learn/tutorial-autoscale-performance-schedule)
- [ARM Template format for �Microsoft.Web/sites](https://docs.microsoft.com/en-us/azure/app-service/samples-resource-manager-templates)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)


Set the Metric source to be 'other resource'. Set the Resource type as 'App Services' and the Resource as the Web App created earlier in this tutorial.

Set the Time aggregation as 'Total', the Metric name as 'Requests', and the Time grain statistic as 'Sum'.

Set the Operator as 'Greater than', the Threshold as '10' and the Duration as '5' minutes.

Select the Operation as 'Increase count by', the Instance count as '1', and the Cool down as '5' minutes.