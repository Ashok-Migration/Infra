# StreamAnalytics

This template deploys a Stream Analytics Job, with optional configuration of inputs, outputs, and functions, and a default transformation.

## Resources

- Microsoft.StreamAnalytics/streamingjobs
- Microsoft.StreamAnalytics/streamingjobs/transformations
- Microsoft.StreamAnalytics/streamingjobs/inputs
- Microsoft.StreamAnalytics/streamingjobs/outputs
- Microsoft.StreamAnalytics/streamingjobs/functions


## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `name` | string | | | Required. Stream Analytics Job Name, can contain alphanumeric characters and hypen and must be 3-63 characters long.
| `streamingUnits` | int | | 1, 3, 6, 12, 18, 24, 30, 36, 42, 48 | Required. Specifies the number of streaming units that the streaming job uses.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `dataLocale` | string | `en-US` | | Optional. The data locale of the Stream Analytics Job.
| `compatibilityLevel` | string | `1.0` | | Optional. Controls certain runtime behaviors of the streaming job.
| `outputErrorPolicy` | string | `Stop` | `Stop`,`Drop` | Optional. Indicates the policy to apply to events that arrive at the output and cannot be written to the external storage due to being malformed (missing column values, column values of wrong type or size).
| `eventsOutOfOrderPolicy` | string | `Adjust` | `Adjust`,`Drop` | Optional. Indicates the policy to apply to events that arrive out of order in the input event stream.
| `eventsOutOfOrderMaxDelayInSeconds` | int | 0 | | Optional. The maximum tolerable delay in seconds where out-of-order events can be adjusted to be back in order.
| `eventsLateArrivalMaxDelayInSeconds` | int | -1 | | Optional. The maximum tolerable delay in seconds where events arriving late could be included. Supported range is -1 to 1814399 (20.23:59:59 days) and -1 is used to specify wait indefinitely.
| `inputs` | array | [] | Complex structure, see below | Optional. A list of one or more inputs to the streaming job.
| `outputs` | array | [] | Complex structure, see below | Optional. A list of one or more outputs to the streaming job.
| `functions` | array | [] | Complex structure, see below | Optional. A list of one or more functions to the streaming job.
| `query` | string | `SELECT\r\n    *\r\nINTO\r\n    [YourOutputAlias]\r\nFROM\r\n    [YourInputAlias]` | | Optional. Specifies the query that will be run in the streaming job.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Stream Analytics job resource.


## Parameter Usage: `inputs`

The parameter 'inputs' is an array of objects with the same structure per below.

```json
"inputs": [
      {
        "name": "string",
        "properties": {
          "type": "string",
          "datasource": {
            "type": "string",
            "properties": {
            }
          },
          "serialization": {
            "type": "string",
            "properties": {
            }
          }
        }
      }
    ]
```
## Parameter Usage: `outputs`

The parameter 'outputs' is an array of objects with the same structure per below.

```json
"outputs": [
      {
        "name": "string",
        "properties": {
          "datasource": {
            "type": "string",
            "properties": {
            }
          },
          "serialization": {
            "type": "string",
            "properties": {
            }
          }
        }
      }
    ]
```

## Parameter Usage: `functions`

The parameter 'functions' is an array of objects with the same structure per below.

```json
"functions": [
      {
        "name": "string",
        "properties": {
          "type": "Scalar",
          "properties": {
            "inputs": [
              {
                "dataType": "string",
                "isConfigurationParameter": boolean
              }
            ],
            "output": {
              "dataType": "string"
            },
            "binding": {
              "type": "string",
              "properties": {
              }
            }
          }
        }
      }
    ]
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
| :-          | :-          |
| `streamAnalyticsName` | The name of the Stream Analytics job deployed.


## Considerations

*N/A*

## Additional resources

- [Microsoft.StreamAnalytics/streamingjobs template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.streamanalytics/2016-03-01/streamingjobs)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)