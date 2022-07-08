# CognitiveServices

This module is used to deploy an Azure Cognitive Services.

## Resources

- Microsoft.CognitiveServices/accounts

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `cognitiveServiceName` | string | | | Required. Name of the Cognitive Service.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `sku` | string | `S0` | S0 | Optional. Pricing tier.


## Outputs

| Output Name | Description |
| :- | :- |
| `CognitiveServiceRegion` | The Region of the resource. |
| `CognitiveServiceResourceGroup` | The name of the Resource Group the resource was created in. |

## Considerations

This is a generic module for deploying a Cognitive Services. 

## Additional resources

- [Azure Cognitive Services documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/)
