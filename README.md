<h1>Table of Contents </h1>

- [Introduction](#introduction)
- [Solution Structure](#ssolution-structure)
- [Conventions](#conventions)
- [ARM Modules](#arm-modules)
- [Adding New Module](#adding-new-module)
- [Adding New Resource Group](#adding-new-resource-group)
- [Adding New Resource to RG](#adding-new-resource-to-rg)

# Introduction 
Code for all infrastructure components.

# Solution structure
```
    DeploymentOrchestration/Environments
        <subscription>/<env> Resource group sepcific deploy.json and pipeline.yml for Central Platform Hub Subscriptionl
    Modules  
      .global - global files to be used across all modules
      ARM - Contains all ARM templates for different azure Components
    QC - Quality Control or Sonar Pipeline
    Scripts
        InternalRBAC - Powershell scripts implementing RBAC policies for Microsoft users
        InviteUsers - Powershell scripts to invite users to AAD
```
# Conventions
- [Resource Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [ARM Template Syntax](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax)
- [ARM Template Best Practices](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-best-practices)

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
1. AutomationAccounts      
1. AzureBastion            
1. AzureDataExplorer       
1. AzureFirewall           
1. CognitiveServices       
1. ContainerRegistry       
1. ContentDeliveryNetwork  
1. CosmosDB            
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
1. Powerbi                
1. PrivateDNSZones           
1. RecoveryServicesVaults    
1. RedisCache                
1. ResourceGroup             
1. RouteTables               
1. SQLLogicalServer          
1. ServiceBusNamespace       
1. ServiceBusNamespaceQueue  
1. ServiceBusNamespaceTopic  
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
1. Create the new CI pipeline in Azure DevOps for the module using pipeline.yml (CI-<ModuleName>-Master-Build) and place it in CI folder of pipelines

# Adding New Resource Group
1. Add resource group specific file in ResourceGroup ARM module
1. Add deploy.json and pipeline.yml for Release in the DeploymentOrchestration\Environments
1. Copy one of the existing resource group specific folder
1. Change the folder name to new resource group
1. In pipeline.yml and update templateFilePath with new resourec group name
1. In deploy.json, first resource should be deployment of resource group (DEP-<Resource Group Name>) 
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
9. Create a new pipeline in Azure DevOps using pipeline.yml (CD-<Resource Group Name>-Master-Release) and move it to Release/<env> folders
10. Releae pipelines need to be run manually after merge to master.

# Adding New Resource to RG
1. Module of the required azure resource must be existing (Refer adding new module if not present)
1. Add parameter file for the resource being added to the module
1. Add the section in resource group specific deployment orchestration with appropriate dependencies and deployment name following the convention (DEP-<resource name>)
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