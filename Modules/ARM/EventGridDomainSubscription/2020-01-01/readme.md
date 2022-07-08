# EventGridDomain

This module is used to deploy an Event Subscription at the Event Grid Domain level.

## Resources

- Microsoft.EventGrid/domains/providers/eventSubscriptions

## Parameters
| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `eventDomainName` | string | | | Required. The name of the Event Grid Domain the subscription is being created for.
| `eventSubscriptionName` | string | | | Required. The name of the Event subscription
| `eventDestination` | object | | | Required. The Destination object used to define the subscription endpoint type. More information here: https://docs.microsoft.com/en-us/azure/templates/microsoft.eventgrid/eventsubscriptions#EventSubscriptionDestination

## Additional resources
[Azure Event Grid Domain documentation](https://docs.microsoft.com/en-us/azure/event-grid/event-domains)
[Azure Event Subscription documentation](https://docs.microsoft.com/en-us/azure/templates/microsoft.eventgrid/eventsubscriptions)