# Event Hub Namespace

This module is used to deploy an Event Hub Namespace, with optional Event Hubs and Consumer Groups.

## Resources

- Microsoft.EventHub/namespaces
- Microsoft.EventHub/namespaces/eventhubs
- Microsoft.EventHub/namespaces/eventhubs/consumergroups

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `projectName` | string | | | Required. Specifies a project name to be used as Event Hub Namespace name.
| `eventHubName` | array | | Complex structure, see below. | Optional. List of specific Event Hubs to create.
| `consumerGroupName` | array | |  Complex structure, see below. | Optional. List of specific Consumer Groups to create in each Event Hub.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `eventHubSku` | string | `Standard` | Basic, Standard | Specifies the messaging tier for service Bus namespace.

### Parameter Usage: `eventHubName`

The `eventHubName` parameter accepts a JSON Array of object with "name" property in each to specify the name of the Event Hub to create.

Here's an example of specifying a single Event Hub named "hubone":

```json
[{"name": "hubone"}]
```

Here's an example of specifying multiple Event Hubs to create:

```json
[{"name": "hubone"}, {"name": "hubtwo"}]
```
### Parameter Usage: `consumerGroupName`

The `consumerGroupName` parameter accepts a JSON Array of object with two properties in each:

- "consumerGroup" property to specify the name of the Consumer Group to create;
- "eventHub" property to specify the name of the Event Hub in which each Consumer Group is to be created.

Here's an example of specifying a single Consumer Group named "one" in the Event Hub named "hubone":

```json
[{"eventHub": "hubone", "consumerGroup": "one"}]
```

Here's an example of specifying multiple Consumer Group to create:

```json
[{"eventHub": "hubone", "consumerGroup": "one"}, 
{"eventHub": "hubtwo", "consumerGroup": "two"},
{"eventHub": "hubtwo", "consumerGroup": "three"}]
```


## Outputs

N/A

## Considerations

This is a generic module for deploying a Event Hub Namespace. 

## Additional resources

- [ARM template format for Event Hub](https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/allversions)
