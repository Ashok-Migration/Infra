# App Configuration Store Update
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

- Run the pipeline after merge to master and selecting appropriate stages [CD-AppConfigurations-Master-Release](https://dev.azure.com/TASMUCP/TASMU%20Central%20Platform/_build?definitionId=406)

