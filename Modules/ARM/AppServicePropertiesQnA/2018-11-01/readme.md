# App service Config entries

This module is used to deploy config entries for an App service, with resource lock.
The default parameter values are based on the needs of deploying a diagnostic app service.

## Resources

- Microsoft.Web/sites/config

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `webAppName` | string | | | Required. Name of the App service.
| `searchName` | string | | | Required. Name of the search service.
| `cognitiveServiceName` | string | | | Required. Name of the Cognitive qnamaker service.
| `appInsightsName` | string | | | Required. Name of the App Insights service.
| `sharedResourceGroupName` | string | | | Required. Name of the Shared resource group.

## Considerations

This is a generic module for deploying a App service. Any customization for different config needs need to be done through the Archetype.

## Additional resources

- [Introduction to Azure App Service](https://azure.microsoft.com/en-in/services/app-service/)
- [ARM Template format for •Microsoft.Web/sites](https://docs.microsoft.com/en-us/azure/app-service/samples-resource-manager-templates)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
