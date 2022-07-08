# StorageAccounts

This module is used to deploy an Azure Storage Account, with resource lock and the ability to deploy 1 or more Blob Containers and 1 or more File Shares. Optional ACLs can be configured on the Storage Account and optional RBAC can be assigned on the Storage Account and on each Blob Container and File Share.

The default parameter values are based on the needs of deploying a diagnostic storage account.


## Resource types

| Resource Type | Api Version |
| :-- | :-- |
| `Microsoft.Resources/deployments` | 2020-06-01 |
| `Microsoft.Storage/storageAccounts/blobServices/containers` | 2019-06-01 |
| `Microsoft.Storage/storageAccounts/blobServices` | 2019-06-01 |
| `Microsoft.Storage/storageAccounts/fileServices/shares` | 2019-06-01 |
| `Microsoft.Storage/storageAccounts/providers/roleAssignments` | 2020-04-01-preview |
| `Microsoft.Storage/storageAccounts` | 2019-06-01 |
| `providers/locks` | 2016-09-01 |

## Parameters

| Parameter Name | Type | Description | DefaultValue | Possible values |
| :-- | :-- | :-- | :-- | :-- |
| `automaticSnapshotPolicyEnabled` | bool | Optional. Automatic Snapshot is enabled if set to true. | False |  |
| `azureFilesIdentityBasedAuthentication` | object | Optional. Provides the identity based authentication settings for Azure Files. |  |  |
| `baseTime` | string | Generated. Do not provide a value! This date value is used to generate a SAS token to access the modules. | [utcNow('u')] |  |
| `blobContainers` | array | Optional. Blob containers to create. | System.Object[] |  |
| `cuaId` | string | Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered |  |  |
| `deleteRetentionPolicy` | bool | Optional. Indicates whether DeleteRetentionPolicy is enabled for the Blob service. | True |  |
| `deleteRetentionPolicyDays` | int | Optional. Indicates the number of days that the deleted blob should be retained. The minimum specified value can be 1 and the maximum value can be 365. | 7 |  |
| `fileShares` | array | Optional. File shares to create. | System.Object[] |  |
| `location` | string | Optional. Location for all resources. | [resourceGroup().location] |  |
| `lockForDeletion` | bool | Optional. Switch to lock storage from deletion. | False |  |
| `minimumTlsVersion` | string | Optional. Set the minimum TLS version on request to storage. | TLS1_2 | System.Object[] |    
| `networkAcls` | object | Optional. Networks ACLs, this value contains IPs to whitelist and/or Subnet information. |  |  |   
| `roleAssignments` | array | Optional. Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or it's fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11' | System.Object[] |  |
| `sasTokenValidityLength` | string | Optional. SAS token validity length. Usage: 'PT8H' - valid for 8 hours; 'P5D' - valid for 5 days; 'P1Y' - valid for 1 year. When not provided, the SAS token will be valid for 8 hours. | PT8H |  |
| `storageAccountAccessTier` | string | Optional. Storage Account Access Tier. | Hot | System.Object[] |
| `storageAccountKind` | string | Optional. Type of Storage Account to create. | StorageV2 | System.Object[] |
| `storageAccountName` | string | Required. Name of the Storage Account. |  |  |
| `storageAccountSku` | string | Optional. Storage Account Sku Name. | Standard_GRS | System.Object[] |
| `tags` | object | Optional. Tags of the resource. |  |  |
| `vNetId` | string | Optional. Virtual Network Identifier used to create a service endpoint. |  |  |

### Parameter Usage: `roleAssignments`

```json
"roleAssignments": {
    "value": [
        {
            "roleDefinitionIdOrName": "Storage File Data SMB Share Contributor",
            "principalIds": [
                "12345678-1234-1234-1234-123456789012", // object 1
                "78945612-1234-1234-1234-123456789012" // object 2
            ]
        },
        {
            "roleDefinitionIdOrName": "Reader",
            "principalIds": [
                "12345678-1234-1234-1234-123456789012", // object 1
                "78945612-1234-1234-1234-123456789012" // object 2
            ]
        },
        {
            "roleDefinitionIdOrName": "/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11",
            "principalIds": [
                "12345678-1234-1234-1234-123456789012" // object 1
            ]
        }
    ]
}
```

### Parameter Usage: `networkAcls`

```json
"networkAcls": {
    "value": {
        "bypass": "AzureServices",
        "defaultAction": "Deny",
        "virtualNetworkRules": [
            {
                "subnet": "sharedsvcs"
            }
        ],
        "ipRules": []
    }
}
```

### Parameter Usage: `blobContainers`

The `blobContainer` parameter accepts a JSON Array of object with "name" and "publicAccess" properties in each to specify the name of the Blob Containers to create and level of public access (container level, blob level or none). Also RBAC can be assigned at Blob Container level

Here's an example of specifying two Blob Containes. The first named "one" with public access set at container level and RBAC Reader role assigned to two principal Ids. The second named "two" with no public access level and no RBAC role assigned.

```json
"blobContainers": {
    "value": [
        {
            "name": "one",
            "publicAccess": "Container", //Container, Blob, None
            "roleAssignments": [
                {
                    "roleDefinitionIdOrName": "Reader",
                    "principalIds": [
                        "12345678-1234-1234-1234-123456789012", // object 1
                        "78945612-1234-1234-1234-123456789012" // object 2
                    ]
                },
        {
            "name": "two",
            "publicAccess": "None", //Container, Blob, None
            "roleAssignments": []
        }
    ]
```

### Parameter Usage: `fileShares`

The `fileShares` parameter accepts a JSON Array of object with "name" and "shareQuota" properties in each to specify the name of the File Shares to create and the maximum size of the shares, in gigabytes. Also RBAC can be assigned at File Share level.

Here's an example of specifying a single File Share named "one" with 5TB (5120GB) of shareQuota and Reader role assigned to two principal Ids.

```json
"fileShares": {
    "value": [
        {
            "name": "wvdprofiles",
            "shareQuota": "5120",
            "roleAssignments": [
                {
                    "roleDefinitionIdOrName": "Reader",
                    "principalIds": [
                        "12345678-1234-1234-1234-123456789012", // object 1
                        "78945612-1234-1234-1234-123456789012" // object 2
                    ]
                }
            ]
        }
    ]
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

| Output Name | Value | Type |
| :-- | :-- | :-- |
| `blobContainers` | array | The array of the blob containers created. |
| `fileShares` | array | The array of the file shares created. |
| `storageAccountAccessKey` | securestring | The Access Key for the Storage Account. |
| `storageAccountName` | string | The Name of the Storage Account. |
| `storageAccountPrimaryBlobEndpoint` | string | The public endpoint of the Storage Account. |
| `storageAccountRegion` | string | The Region of the Storage Account. |
| `storageAccountResourceGroup` | string | The name of the Resource Group the Storage Account was created in. |
| `storageAccountResourceId` | string | The Resource Id of the Storage Account. |
| `storageAccountSasToken` | securestring | The SAS Token for the Storage Account. |

## Considerations

This is a generic module for deploying a Storage Account. Any customization for different storage needs (such as a diagnostic or other storage account) need to be done through the Archetype.

## Additional resources

- [Introduction to Azure Storage](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction)
- [ARM Template format for Microsoft.Storage/storageAccounts](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2019-06-01/storageaccounts)
- [Storage Account Sku Type options](https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.storage.fluent.storageaccountskutype?view=azure-dotnet)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
