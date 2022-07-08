# API Management CMS Notification API

This module is used to deploy a Function App Backend for API Management.

## Resources

- Microsoft.ApiManagement/service/backends

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `backendServiceName` | string |  | `func-<sub>-apps-intntf-<env>-we-01` | Required. The backend service name.
| `backendServiceRG` | string | | `rg-<sub>-apps-int-<env>-we-01` | Required. The resource group of the backend service being linked to.
| `apiManagementServiceName` | string |  | `apim-<sub>-shrd-<env>-we-01` | Required. The name of the api management service.