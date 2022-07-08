# API Management API

This module is used to deploy a event integration API with logic app as a backend

## Resources

- Microsoft.ApiManagement/service/apis

## Parameters

| Parameter Name | Type | Default Value | Possible values | Description |
| :-             | :-   | :-            | :-              | :-          |
| `apiDescription` | string |  | `Event Integration API for Development` | Required. The description of the API being added.
| `apiDisplayName` | string | | `Event Integration API` | Required. The display name of the API being added
| `apiManagementServiceName` | string |  | `apim-<sub>-shrd-<env>-we-01` | Required. The name of the api management service.
| `apiName` | string |  |`EventIntegrationApi` | Required. The name of the API being added
| `apiOperations` | array | | | Required. A list of operations on the API.
| `apiPath` | string | |`eventintegration` | Required. The path of the API being added.
| `apiPolicyLogicAppName` | string |  | `logic-<sub>-apps-route-<env>-we-01`| Optional.The name of the logic app in the backend.
| `apiPolicyLogicAppRG` | string | | `rg-<sub>-apps-int-<env>-we-01` | Optional.The resource group of the logic app in the backend.
| `audienceId` | string |   |`bc67474e-612b-4d7f-b75a-ac54d45f143a` | Required. Client Id of `Central-Platform-Core-APIs` app registration in B2C tenant.
| `issuerUrl` | string |  | `https://tasmucpb2cnonprod.b2clogin.com/<b2ctenantId>/v2.0/` | Required. The Issuer URL, use the b2c tenant Id in the URL.
| `openIdConfigUrl` | string |  | `https://login.microsoftonline.com/<b2ctenantId>/v2.0/.well-known/openid-configuration`  | Required. Open Id Config Url from b2c tenant, use the b2c tenant Id in the URL.
| `subscriptionRequired` | bool | `true`| true/false | Optional. Specifies whether an API or Product subscription is required for accessing the API.
