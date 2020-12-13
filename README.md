<h1>Table of Contents </h1>

- [Introduction](#introduction)
- [PR Checklist](#pr-checklist)
- [Solution Structure](#ssolution-structure)
- [Conventions](#conventions)
- [Recommended Developer Tools](#recommended-developer-tools)
- [ARM Modules](#arm-modules)
- [Adding New Module](#adding-new-module)
- [Adding New Resource Group](#adding-new-resource-group)
- [Adding New Resource to RG](#adding-new-resource-to-rg)
- [Adding Secrets and Certificates to Key Vault](#adding-secrets-and-certificates-to-key-vault)
- [Adding Configurations to App Config Store](#adding-configurations-to-app-config-store)
- [Security Scan](#security-scan)
# Introduction 
Code for all infrastructure components.

# PR Checklist
- [ ] Resource naming conventions being followed as per wiki
- [ ] Parameters added for all environments (sbx, dev, tst, tra, uat, etc)
- [ ] Resource added to deployment files (DeploymentOrchestration\Environments) for all environments (sbx, dev, tst, tra)
- [ ] Deployment tested on lower environment (sbx)
- [ ] Related documentations added/updated
- [ ] Security scans executed and violations fixed
- [ ] Add successful runs for lower environments to the description

# Solution structure
```
    DeploymentOrchestration/Environments
        <subscription>/<env> Resource group sepcific deploy.json and pipeline.yml for Central Platform Hub Subscriptions
    Modules  
      .global - global files to be used across all modules
      ARM - Contains all ARM templates for different azure Components
    QC - Quality Control or Sonar Pipeline
    Scripts
        App Configurations - scripts, app settings and pipeline to update app config store
        CMS - Sharepoint provisioning scripts and pipeline
        InternalRBAC - Powershell scripts implementing RBAC policies for Microsoft users
        InviteUsers - Powershell scripts to invite users to AAD
        KeyVault - scripts and pipeline to add secrets and certificates to key vaults
```
# Conventions
- [Resource Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [ARM Template Syntax](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax)
- [ARM Template Best Practices](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-best-practices)

#Recommended Developer Tools
1. Visual Studio Code
>>Recommended Extensions
>>- Azure Pipelines (Microsoft)
>>- Power Shell (Microsoft)
>>- YAML (Red Hat)
>>- Sort JSON Objects (richie5um2)
>>- Markdown-formatter (mervin)
>>- Bracket Pair Colorizer (CoenraadS)
>>- ARM Tools (Microsoft)

2. Azure CLI [(Latest Stable Version)](https://aka.ms/installazurecliwindows)

# Resources list and conventions specific to TASMU
[BOM Sheet](https://microsofteur.sharepoint.com/:x:/r/teams/TASMUNationalPlatform-DeliveryStream-MicrosoftOnly/_layouts/15/guestaccess.aspx?e=VvPNKy&share=EZkiApVrr7BOvrmV_DpgOtQBHWe5l9yqv7a4eaiLu2s6Uw)  
All resources must be added to this sheet.

# ARM Modules
1. AnalysisServices       
1. ApiConnection          
1. ApiManagement          
1. AppConfigurationStore  
1. AppServicePlan         
1. ApplicationGateway     
1. ApplicationInsights   
1. AppServiceManagement 
1. AppServicePlan
1. AppServicePropertiesQnA
1. AutomationAccounts      
1. AzureBastion            
1. AzureDataExplorer       
1. AzureFirewall           
1. CognitiveServices  
1. CognitiveServicesQna     
1. ContainerRegistry       
1. ContentDeliveryNetwork       
1. ContentDeliveryNetworkEndpoint  
1. CosmosDB - Account + SQL DB + Container
1. CosmosDBAccount
1. CosmosDBSQL
1. CosmosDBSQLContainer         
1. DataFactory         
1. DataShare           
1. Databricks          
1. Datalakes           
1. EventHubNamespaces  
1. EventHubs           
1. FunctionApp            
1. FunctionAppBPA - Custom module with settings for bpa app        
1. HDInsight              
1. IoTHub                 
1. KeyVault               
1. LoadBalancersInternal  
1. LocalNetworkGateway    
1. LogAnalytics           
1. LogicApp               
1. ManagedClusters        
1. ManagedClustersCNI     
1. ManagedIdentity        
1. NetworkSecurityGroups 
1. NotificationHubNamespaces 
1. Powerbi                
1. PrivateDNSZones 
1. PrivateEndpoint          
1. RecoveryServicesVaults    
1. RedisCache                
1. ResourceGroup             
1. RouteTables       
1. SearchService        
1. SQLLogicalServer          
1. ServiceBusNamespace       
1. ServiceBusNamespaceQueue  
1. ServiceBusNamespaceTopic 
1. ServiceBusNamespaceTopicSubscription
1. SqlManagedInstance        
1. StorageAccounts           
1. StreamAnalytics           
1. SynapseAnalytics
1. VirtualMachines
1. VirtualNetwork
1. VirtualNetworkGateway
1. VirtualNetworkGatewayConnection
1. VirtualNetworkLinks
1. VirtualNetworkPeering
1. WebappBot

# Adding New Module
1. Copy the entire folder of one of the existing module
1. Change the folder name to module name
1. In pipeline.variables.yml update the module name value
1. In pipeline.yml, update the paths in trigger according to the new module name
1. Update the deploy.json according to new resource
1. Remove all the parameter files in parameters folder
1. Add generic parameters.json specific to this module in parameters folder
1. Add resource group specific parameter file following the naming convention to parameters folder
1. Use the latest schemas and api versions of resources
1. Create the new CI pipeline in Azure DevOps for the module using pipeline.yml (**CI-<ModuleName>-Master-Build**) and place it in CI folder of pipelines
1. Pipeline must have three stages - Scan, Validate and Publish
1. Run the pipeline from branch first to scan the templates and fix the violations if any.

# Adding New Resource Group
1. Add resource group specific file in ResourceGroup ARM module
1. Add deploy.json and pipeline.yml for Release in the DeploymentOrchestration\Environments
1. Copy one of the existing resource group specific folder
1. Change the folder name to new resource group
1. In pipeline.yml and update templateFilePath with new resource group name
1. In deploy.json, first resource should be deployment of resource group (**DEP-<Resource Group Name>**) 
1. Check the template link and parameters link (should be pointing to new resource group being deployed)
```
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-10-01",
            "name": "DEP-rg-cpd-apps-dev-we-01",
            "location": "[variables('location')]",
            "dependsOn": [],
            "properties": {
                "mode": "Incremental",
                "debugSetting": {
                    "detailLevel": "requestContent,responseContent"
                },
                "templateLink": {
                    "uri": "[concat(variables('modulesPath'), 'ResourceGroup/2019-11-28/deploy.json', '?', listAccountSas(variables('componentStorageAccountId'), '2019-04-01', variables('accountSasProperties')).accountSasToken)]"
                },
                "parametersLink": {
                    "uri": "[concat(variables('modulesPath'), 'ResourceGroup/2019-11-28/Parameters/rg-cpd-apps-dev-we-01-parameters.json', '?', listAccountSas(variables('componentStorageAccountId'), '2019-04-01', variables('accountSasProperties')).accountSasToken)]"
                }
            }
        }
```
8.  Customer Usage Attribution (CUA) must be deployed in every resource group, resources deployed separately/manually are not accounted for consumption tracking
```
        {
            "apiVersion": "2019-10-01",
            "name": "[variables('CUA')]",
            "type": "Microsoft.Resources/deployments",
            "resourceGroup": "rg-cpd-apps-dev-we-01",
            "dependsOn": [
                "DEP-rg-cpd-apps-dev-we-01"
            ],
            "properties": {
                "mode": "Incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "resources": []
                }
            }
        }
```
9. Create a new pipeline in Azure DevOps using pipeline.yml (**CD-<Resource Group Name>-Master-Release**) and move it to Release/<env> folders
10. Release pipelines need to be run manually after merge to master.
11. Pipeline must contain three stages - Validate, DeployTemplate and SecurityVerification
12. Violations reported as part of SecurityVerification must be reviewed and fixed asap

# Adding New Resource to RG
1. Module of the required azure resource must be existing (Refer adding new module if not present)
1. Add parameter file for the resource being added to the module
1. Add the section in resource group specific deployment orchestration with appropriate dependencies and deployment name following the convention (**DEP-<resource name>**)
Below example deploys API Management instance apim-cpd-apps-dev-we-01 to Resource Group rg-cpd-apps-dev-we-01
```
        {
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2019-10-01",
            "name": "DEP-apim-cpd-apps-dev-we-01",
            "resourceGroup": "rg-cpd-apps-dev-we-01",
            "dependsOn": [
                "DEP-rg-cpd-apps-dev-we-01",
                "DEP-appi-cpd-apps-dev-we-01"
            ],
            "properties": {
                "mode": "Incremental",
                "debugSetting": {
                    "detailLevel": "requestContent,responseContent"
                },
                "templateLink": {
                    "uri": "[concat(variables('modulesPath'), 'ApiManagement/2019-12-01/deploy.json', '?', listAccountSas(variables('componentStorageAccountId'), '2019-04-01', variables('accountSasProperties')).accountSasToken)]"
                },
                "parametersLink": {
                    "uri": "[concat(variables('modulesPath'), 'ApiManagement/2019-12-01/Parameters/apim-cpd-apps-dev-we-01-parameters.json', '?', listAccountSas(variables('componentStorageAccountId'), '2019-04-01', variables('accountSasProperties')).accountSasToken)]"
                }
            }
        }
```
# Adding Secrets and Certificates to Key Vault
- Deploying Secrets to Key Vaults 
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
    1. Run the pipeline after merge to master and selecting appropriate stages [CD-KeyVaultSecrets-Master-Release](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_build?definitionId=337)


- Importing Certificates to Key Vaults
    1. Upload Certificate to [Secure Files Library](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_library?itemType=SecureFiles) in Azure DevOps
    1. Add the certificate password to [variable group](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_library?itemType=VariableGroups) in Azure Devops for each environment
    1. Mark the variable as secure
    1. Add the step in Scripts/KeyVault/all-secrets.yml like below for each new certificate
    ```
    - template: add-certificate.yml
        parameters:
        certificateName: "Cms-Api-ClientCertificate"
        certificatePassword: "CMS-Certificate-Password"
        downloadFileName: "cmsapiclientcertificate"
        secureFile: "TASMUDev.pfx"
    ```
    1. Follow the conventions of creating certificate names
    1. Run the pipeline after merge to master and selecting appropriate stages [CD-KeyVaultSecrets-Master-Release](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_build?definitionId=337)

# Adding Configurations to App Config Store
- Key Vault References should be added to the environment specific appsettings.json files at below path
    Scripts/AppConfigurations/keyvaultref
- Other Settings and Feature Flags must be added to environment specific appsettings.json files at below path
    Scripts/AppConfigurations/settings

    Feature Flags should be updated under Feature Management section only like below
    ```
    "FeatureManagement": {
    "Mobile.Documents": false,
    "Mobile.GetSupport": true,
    "Mobile.ServiceCatalogue": true,
    "Mobile.Settings": false
  }
  ````
- Settings common to APIs like Instrumentation Key, Use Redis, must be reused and added to AppSettings section like below
```
 "AppSettings": {
    "InstrumentationKey": "5ad30db6-ba76-415c-b114-b4027de0b7cb",
    "UseRedis": true
  }

```
- Environment References

    1. sbx - Sandbox
    2. dev - Development
    3. tst - Test
    4. tra - Training

- Pipeline auto triggered by changes to appsettings.json files [CD-AppConfigurations-Master-Release](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_build?definitionId=406)

# Security Scan

The CICD Extension from the Secure DevOps Kit for Azure (AzSK) contains two tasks:

1. ARM Template Checker 
    - a task that can check security settings in ARM templates
    - added to each ARM module and executed as part of CI pipelines
1. Security Verification Tests (SVTs) 
    - a task that can check deployed resources for secure configuration
    - added to resource groups and executed after resource group deployment
