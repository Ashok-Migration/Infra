# Analysis Services

This module is used to deploy an Analysis Services Server

## Resources

- Microsoft.AnalysisServices/servers

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `serverName` | string | | | The name of the Azure Analysis Services server to create. Server name must begin with a letter, be lowercase alphanumeric, and between 3 and 63 characters in length. Server name must be unique per region.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `skuName` | string | `S0` | D1,B1,B2,S0,S1,S2,S4,S8,S9,S8v2,S9v2 | The sku name of the Azure Analysis Services server to create. Some skus are region specific. See https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region
| `firewallSettings` | object | Complex structure, see below. | Complex structure, see below. | The inbound firewall rules to define on the server. If not specified, firewall is disabled.
| `backupBlobContainerUri` | string | "" | | The SAS URI to a private Azure Blob Storage container with read, write and list permissions. Required only if you intend to use the backup/restore functionality. See https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-backup
| `admin` | array | [] | | An array of administrator user identities.
| `tags` | object | {} | Complex structure, see below. | Optional. Resource tags.


### Parameter Usage: `firewallSettings`

The parameter firewallSettings accepts an object with an arrat of firewall rules and the indicator of enabling PBI service

The default value, which also demonstrate the complex structure, is as following:

```json
"firewallSettings": {
  "firewallRules": [
    {
      "firewallRuleName": "AllowFromAll",
      "rangeStart": "0.0.0.0",
      "rangeEnd": "255.255.255.255"
    }
  ],
  "enablePowerBIService": true
}
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

N/A

## Considerations

This is a generic module for deploying a Analysis Services Server

## Additional resources

- [ARM template format for Analysis Service Server](https://docs.microsoft.com/en-us/azure/templates/microsoft.analysisservices/servers)
