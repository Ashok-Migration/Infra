# Bitnami CKAN

This module is used to deploy Bitnami CKAN instance.

## Resources

- Microsoft.Storage/storageAccounts
- Microsoft.DBforPostgreSQL/serverGroups
- Microsoft.DBforPostgreSQL/serversv2
- Microsoft.DBforPostgreSQL/serversv2/firewallRules
- Microsoft.Cache/Redis
- Microsoft.Network/networkInterfaces
- Microsoft.Compute/virtualMachines
- Microsoft.Compute/virtualMachines/extensions
- Microsoft.Network/publicIPAddresses
- Microsoft.Network/applicationGateways

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `appPassword` | securestring |  |  | Application password
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `stackId` | string | | | Stack ID - it is the Application Stack identifier.
| `authenticationType` | string | password | "password", "sshPublicKey" | Authentication type
| `adminUsername` | securestring | | | OS Admin Username
| `adminPassword` | securestring | | | OS Admin password
| `sshKey` | string | | | SSH rsa public key file as a string.
| `vmSize` | string | Standard_D1_v2 | | Size of the VM
| `vmZones` | array | ["1","2","3"] | | Availability zones
| `customData` | string | # blank |  | customData
| `BitnamiTags` | object |  |  | Optional. Bitnami Tags.
| `ckanCount` | int | 2 |  | CKAN nodes count
| `databaseUsername` | string | citus |  | Database username
| `databasePassword` | securestring |  |  | Database password
| `databaseWorkersVCores` | int | 4 | 4, 8, 16, 32, 64 | Number of VCores of the worker node
| `databaseWorkersStorageSizeMB` | int | 524288 | 524288, 1048576, 2097152 | Disk storage for the worker node.
| `databaseSkuName` | string | GP_Gen5_2 |  | PostgreSQL database pricing tier.
| `databaseSkuSizeGB` | int | 50 |  | PostgreSQL database size (GB).
| `redisCacheSku` | string | Premium_P_1 | Premium_P_1, Premium_P_2, Premium_P_3, Premium_P_4 | Redis Cache pricing tier.
| `solrDataDiskSize` | int | 50 |  | Data Disk Size in GB for the Apache Solr node
| `defaultSubnet` | string |  | Eg. `/subscriptions/d0694def-b27e-4bb7-900d-437fbeb802da/resourceGroups/rg-cpd-pltf-net-uat-we-01/providers/Microsoft.Network/virtualNetworks/vnet-cpd-pltf-uat-we-01/subnets/snet-cpd-apps-ckndflt-uat-we-01` | Default Subnet Id Used for All frontend VMs.
| `agwSubnet` | string |  | Eg. `/subscriptions/d0694def-b27e-4bb7-900d-437fbeb802da/resourceGroups/rg-cpd-pltf-net-uat-we-01/providers/Microsoft.Network/virtualNetworks/vnet-cpd-pltf-uat-we-01/subnets/snet-cpd-apps-cknagw-uat-we-01` | Application Gateway Subnet Id Used for Application Gateway.
| `redisSubnet` | string |  | Eg. `/subscriptions/d0694def-b27e-4bb7-900d-437fbeb802da/resourceGroups/rg-cpd-pltf-net-uat-we-01/providers/Microsoft.Network/virtualNetworks/vnet-cpd-pltf-uat-we-01/subnets/snet-cpd-apps-cknredis-uat-we-01` | Redis Subnet Id Used for Redis Instance.
| `storageAccountName` | string |  |  | Storage Account Name
| `storageAccountSKU` | string | Standard_LRS |  | Storage Account SKU
| `serverGroupName` | string | citus |  | Server Group Name
| `postgreSQLServerNames` | array |  |  | PostgreSQL Server v2 Names
| `singlePostgreSQLServerName` | string | |  | Single PostgreSQL Server Name
| `singlePostgreSQLServerUsername` | string | |  | Single PostgreSQL Server Username
| `singlePostgreSQLServerSKU` | string | GP_Gen5_4 |  | Single PostgreSQL Server SKU
| `singlePostgreSQLServerTier` | string | GeneralPurpose |  | Single PostgreSQL Server Tier
| `singlePostgreSQLServerFamily` | string | Gen5 |  | Single PostgreSQL Server Family
| `singlePostgreSQLServerCapacity` | int | 4 |  | Single PostgreSQL Server Capacity
| `singlePostgreSQLServerStorageProfile` | object | |  | Single PostgreSQL Server Profile
| `singlePostgreSQLServerVersion` | string | 11 |  | Single PostgreSQL Server Version
| `singlePostgreSQLServerSSL` | string | Enabled |  | Single PostgreSQL Server SSL Enforcement
| `singlePostgreSQLServerTLSVersion` | string | TLSEnforcementDisabled |  | Single PostgreSQL Server TLS Version
| `singlePostgreSQLServerInfrastructureEncryption` | string | Disabled |  | Single PostgreSQL Infrastructure Encryption
| `singlePostgreSQLServerPublicAccess` | string | Enabled |  | Single PostgreSQL Server Public Access
| `redisName` | string |  |  | Redis Instance Name
| `frontendVirtualMachineNames` | array |  |  | Frontend VM Names
| `solrVirtualMachineName` | string |  |  | Solr VM Name
| `cacheVirtualMachineName` | string |  |  | Cache VM Name
| `applicationGatewayName` | string |  |  | Application Gateway Name
| `azFirewallPublicIP` | string |  |  | Az Firewall Public IP
| `agwZones` | array |  |  | Availability Zones for Application Gateway
| `agwPrivateIP` | string |  |  | Application Gateway Private IP Address
| `frontendPorts` | array |  |  | 
| `backendAddressPoolName` | string |  |  | 
| `backendAddressPools` | array |  |  | 
| `backendHttpSettingName` | string |  |  | 
| `backendHttpSettingsCollection` | array |  |  | 
| `httpListeners` | array |  |  | 
| `requestRoutingRules` | array |  |  | 
| `probes` | array |  |  | 
| `sslCertificates` | array |  |  | Application Gateway SSL Certificates
| `managedIdentityId` | string |  |  | Application Gateway Managed Identity
| `diagnosticLogsRetentionInDays` | int | 365 |  | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `diagnosticStorageAccountId` | string |  |  | Optional. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | string |  |  | Optional. Resource identifier of Log Analytics.
| `eventHubAuthorizationRuleId` | string |  |  | Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.
| `eventHubName` | string |  |  | Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.

### Parameter Details: `agwPrivateIP`

Application Gateway Private IP Address should be taken from Application Gateway Subnet's (agwSubnet) IP range.

### Parameter Details: `azFirewallPublicIP`

Azure Firewall Public IP should be taken from Azure Firewall.

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

## Output

| Output Name | Description |
| :- | :- |
| `fqdn` | Fully qualified domain name of PublicIP associate to the Application Gateway |

## Considerations

This is a generic module for deploying Bitnami CKAN instance.

## Additional resources

- [Bitnami CKAN documentation](https://docs.bitnami.com/azure-templates/apps/ckan/)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
