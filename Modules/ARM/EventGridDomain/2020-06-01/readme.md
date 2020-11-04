# EventGridDomain

This module is used to deploy an Azure Event Grid Domain.

## Resources

- Microsoft.EventGrid/domains

## Parameters
| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `eventGridDomainName` | string | | | Required. Name of the Event Grid Domain.
| `eventGridDomainTopics` | array | | | List of Topics to be added to the Domain

## Additional resources
[Azure Event Grid Domain documentation](https://docs.microsoft.com/en-us/azure/event-grid/event-domains)