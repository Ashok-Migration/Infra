# API Management CMS Notification API

This module is used to deploy a CMS Notification API with function app as a backend

## Resources

- Microsoft.ApiManagement/service/apis

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `apiDescription` | string |  | `CMS Notification API for Development` | Required. The description of the API being added.
| `apiDisplayName` | string | | `CMS Notification API` | Required. The display name of the API being added
| `apiManagementServiceName` | string |  | `apim-<sub>-shrd-<env>-we-01` | Required. The name of the api management service.
| `apiName` | string |  |`CmsNotificationApi` | Required. The name of the API being added
| `apiOperations` | array | | | Required. A list of operations on the API.
| `apiPath` | string | |`eventintegration` | Required. The path of the API being added.
| `apiPolicyFunctionAppName` | string |  | `func-<sub>-apps-intntf-<env>-we-01`| Optional.The name of the function app in the backend.
| `apiPolicyFunctionAppRG` | string | | `rg-<sub>-apps-int-<env>-we-01` | Optional.The resource group of the function app in the backend.
| `subscriptionRequired` | bool | `true`| true/false | Optional. Specifies whether an API or Product subscription is required for accessing the API.
