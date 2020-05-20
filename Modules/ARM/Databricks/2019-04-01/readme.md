# Databricks

This module deploys Databricks Premium.

## Resources

- Microsoft.Databricks/workspaces

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `WorkspaceName` | string | | | Required. Name of the Azure Databricks Workspace
| `pricingTier` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `vnetAddressPrefix` | string | `{}` | Complex structure, see below. | Optional. Access policies object
| `location` | string | `{}` | Complex structure, see below. | Optional. All secrets {\"secretName\":\"\",\"secretValue\":\"\"} wrapped in a secure object
| 
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

### Parameter Usage: `vNetId`

```json
"vNetId": {
    "value": "/subscriptions/00000000/resourceGroups/resourceGroup"
}
```

### Parameter Usage: `accessPolicies`

```json
"accessPolicies": {
    "value": [
        {
            "tenantId": null,
            "objectId": null,
            "permissions": {
                "certificates": [
                    "All"
                ],
                "keys": [
                    "All"
                ],
                "secrets": [
                    "All"
                ]
            }
        }
    ]
}
```

### Parameter Usage: `secretsObject`

```json
"secretsObject": {
    "value": {
        "secrets": [
            {
                "secretName": "Secret--AzureAd--Domain",
                "secretValue": "Some value"
            }
        ]
    }
}
```

## Outputs

| Output Name | Description |
| :-          | :-          |
| `keyVaultResourceId` | The Resource Id of the Key Vault.
| `keyVaultResourceGroup` | The name of the Resource Group the Key Vault was created in.
| `keyVaultName` | The Name of the Key Vault.
| `keyVaultUrl` | The Name of the Key Vault.

## Considerations

*N/A*

## Additional resources

- [What is Azure Key Vault?](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-whatis)
- [Microsoft.KeyVault vaults template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/2018-02-14/vaults)
- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)