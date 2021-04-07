# FunctionApp

This module is used to deploy an Azure Function App.

## Resources

- Microsoft.Web/sites

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `functionAppName` | string | | | Required. Name of the function app name.
| `location` | string | `[resourceGroup().location]` | | Optional. Location for all resources.
| `appInsightsName` | string | `appi-cpd-apps-mon-uat-we-01` | | Name of the app insights instance name.
| `appInsightsRG` | string | `rg-cpd-apps-mon-uat-we-01` | | resource group name of the app insights instance.
| `hostingPlanName` | string | `plan-cpd-apps-ckan-uat-we-01` | | hosting plan name.
| `hostingPlanRG` | string | `rg-cpd-apps-ckan-uat-we-01` | | hosting plan resource group.
| `diagnosticLogsRetentionInDays` | integer | 365 | | Diagnostic Logs Retention In Days.
| `diagnosticStorageAccountId` | string | | | Diagnostic Storage Account Id.
| `workspaceId` | string | | | Workspace Id.
| `alwaysOn` | bool | `true` | | always On.
| `eventHubAuthorizationRuleId` | string | | | Event Hub Authorization Rule Id.
| `eventHubName` | string | | | Event Hub Name.
| `appConfigEndpoint` | | string | | | App Config Endpoint.
| `blobAccountConnectionString` | string | | | Blob Account Connection String.
| `tags` | string | | | tags.