# Web Application Firewall Policy

This module is used to deploy Web Application Firewall Policy.

## Resources

- Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `wafName` | string | | | Required. Name of Web Application Firewall Policy.
| `location` | string | westeurope | | Required. Location of the resource.
| `applicationGateways` | array | [] | | Required. ID of application gateway the WAF Policy will be associated to.
| `requestBodyCheck` | bool | true | true, false | Request's body check.
| `maxRequestBodySizeInKb` | int | 128 | | Max Request Body Size (in Kb).
| `fileUploadLimitInMb` | int | 100 | | File Upload Limit (in Mb).
| `state` | string | Enabled | Enabled, Disabled | State of WAF Policy.
| `mode` | string | Prevention | | Mode of WAF Policy.
| `managedRuleSets` | array | | | Managed rule sets.
| `exclusions` | array | | | Exclusions for WAF Policy.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the Web App Bot resource.

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

``` json
"tags": {
    "value": {
        "Environment": "Non-Prod"
    }
}
```

## Considerations

This is a generic module for deploying Web Application Firewall Policy.

## Additional resources

- [More about Web Application Firewall Policy](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/ApplicationGatewayWebApplicationFirewallPolicies?tabs=json)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
