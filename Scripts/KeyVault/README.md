
# Deploying Secrets to Key Vaults 
1. Add the secret to respective [variable group](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_library?itemType=VariableGroups) in Azure Devops for each environment
1. Give the variable name same as secret name
1. Mark the variable as secure
1. Add the step in Scripts/KeyVault/all-secrets.yml like below for each new secret
    ```
    - template: add-secrets.yml
        parameters:
        secretName: "AdminPortal-ADAuth-ClientSecret"
        
    ```
1. Follow the conventions of creating secret names
1. Run the pipeline [CD-KeyVaultSecrets-Master-Release](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_build?definitionId=337)
