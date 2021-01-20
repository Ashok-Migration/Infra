## Solution overview and deployed resources

Executing an AKS deployment using this ARM template will create an AKS instance. 

## Prerequisites

Prior to deploying AKS using this ARM template, the following resources need to exist:
- Azure Vnet, including a subnet of sufficient size
- App Config Store (acst-cpp-apps-str-<env>-we-01) to store app configurations for cluster apis
- Azure Container Registry (acrcppglobprdwe01) to pull images 
- Log Analytics Workspace (log-cpp-apps-mon-<env>-we-01) 

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `acrName` | string | | acrcppglobprdwe01 | Name of the Azure Container Registry
| `acrResourceGroup` | string | | rg-cpp-glob-prd-we-01| Required. Resource Group of Azure Container Registry.
| `clusterName` | string | |aks-cpp-apps-prd-we-01 | Required. Name of the AKS Cluster.
| `dnsPrefix` | string | | aks-cpd-apps-pre-we-01-dns | Required. DNS Prefix.
| `dnsServiceIP` | string | |10.0.0.10  | Required. DNS Service IP.
| `dockerBridgeCidr` | string | | 172.17.0.1/16| Required. Docker Bridge CIDR .
| `enableHttpApplicationRouting` | boolean | | false| Required. Enable HTTP Application Routing.
| `enablePrivateCluster` | boolean | | true| Required. Enable Private Cluster.
| `enableRBAC` | boolean | | true | Required. Enable Role Based Access Control .
| `kubernetesVersion` | string | | | Required. Kubernetes Version .
| `networkPlugin` | string | |azure | Required. Network Plugin .
| `networkPolicy` | string | |azure | Required. Network Policy.
| `serviceCidr` | string | | | Required. Service CIDR.
| `subnetName` | string | | snet-cpd-pltf-aks-pre-we-01| Required. Subnet Name.
| `tags` | object | | | Required. .
| `virtualNetworkName` | string | |vnet-cpp-pltf-prd-we-01 | Required. Virtual Network Name.
| `vmssNodePool` | boolean | | true | Required. Enable VMSS Node Pool.
| `vnetResourceGroup` | string | | | Required. Virtual Network Resource Group Name. 
| `acrRoleGuidValue` | string | | | Required. Unique Guid for Role Assignment to Azure Container Registry.
| `omsRoleGuidValue` | string | | | Required. Unique Guid for Role Assignment to Log Analytics Workspace.
| `subnetRoleGuidValue` | string | | | Required. Unique Guid for Role Assignment to Subnet.
| `micGuidValue` | string | | | Required. Unique Guid for Role Assignment for Agent Pool Managed Identity.
| `vmcGuidValue` | string | | | Required. Unique Guid for Role Assignment of Agent Pool to Node Resource Group.
| `configStoreResourceId` | string | | | Required. App Configuration Store Resource Id.
| `nodeResourceGroup` | string | | | Required. Name of the node resource group.
| `zones` | string | | | Optional. . Availability Zones.
| `agentVMSize` | string | | | Optional. .Size of the agent VM.
| `agentPoolMaxCount` | int | | | Optional. Agent Pool Maximum Count.
| `agentPoolMinCount` | int | | | Optional. Agent Pool Minimum Count .
| `diagnosticLogsRetentionInDays` | int | | | Required. Diagnostic Logs Retention In Days .
| `diagnosticStorageAccountId` | string | | | Required. Diagnostics Storage Account Resource Id .
| `workspaceId` | string | | | Required. Log Analytics Workspace Resource Id.
| `eventHubAuthorizationRuleId` | string | | | Required. Event Hub Rule Authorization Rule Id with Listen, Manage and Send access.
| `eventHubName` | string | | | Required. Event Hub Name.
| `tags` | object | {} | Complex structure, see below. | Optional. Tags of the AKS resource.
    

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

``` json
"tags": {
    "value": {
        "Environment": "Non-Prod"
    }
}
```