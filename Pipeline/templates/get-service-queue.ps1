

$global:buildQueueVariable = ""
$global:buildSeparator = ";"

Function AppendQueueVariable([string]$folderName) {
	$folderNameWithSeparator = -join ($folderName, $global:buildSeparator)

	if ($global:buildQueueVariable -notmatch $folderNameWithSeparator) {
		$global:buildQueueVariable = -join ($global:buildQueueVariable, $folderNameWithSeparator)
	}
}

if ($env:BUILDQUEUEINIT) {
	Write-Host "Build Queue Init: $env:BUILDQUEUEINIT"
	Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$env:BUILDQUEUEINIT"
	exit 0
}

# Get all files that were changed
$editedFiles = git diff HEAD HEAD~ --name-only

# Check each file that was changed and add that Service to Build Queue
$editedFiles | ForEach-Object {
	Switch -Wildcard ($_ ) {
		# The path filters for policies

		"pipelines/APIM/src/Input/apis/AccountManagementApi/*" {
			Write-Host "AccountManagementApi changed"
			AppendQueueVariable "AccountManagementApi"
		}
		"pipelines/APIM/src/Input/apis/BillingEntityInfoApi/*" {
			Write-Host "BillingEntityInfoApi changed"
			AppendQueueVariable "BillingEntityInfoApi"
		}
		"pipelines/APIM/src/Input/apis/CaseApi/*" {
			Write-Host "CaseApi changed"
			AppendQueueVariable "Case"
		}
		"pipelines/APIM/src/Input/apis/CMSApi/*" {
			Write-Host "cmscontentapi changed"
			AppendQueueVariable "cmscontentapi"
		}
		"pipelines/APIM/src/Input/apis/CMSDocumentsApi/*" {
			Write-Host "cmsdocumentsapi changed"
			AppendQueueVariable "cmsdocumentsapi"
		}
		"pipelines/APIM/src/Input/apis/CMSMediaAssetsApi/*" {
			Write-Host "cmsmediaassetsapi changed"
			AppendQueueVariable "cmsmediaassetsapi"
		}
		"pipelines/APIM/src/Input/apis/ConfigApi/*" {
			Write-Host "Config changed"
			AppendQueueVariable "Config"
		}
		"pipelines/APIM/src/Input/apis/EventManagementApi/*" {
			Write-Host "EventManagementApi changed"
			AppendQueueVariable "EventManagementApi"
		}
		"pipelines/APIM/src/Input/apis/CustomerManagementApi/*" {
			Write-Host "CustomerManagementApi changed"
			AppendQueueVariable "CustomerManagementApi"
		}
		"pipelines/APIM/src/Input/apis/CustomerOnboardingApi/*" {
			Write-Host "CustomerOnboardingApi changed"
			AppendQueueVariable "CustomerOnboardingApi"
		}
		"pipelines/APIM/src/Input/apis/DemographicApi/*" {
			Write-Host "DemographicApi changed"
			AppendQueueVariable "Demographic"
		}
		"pipelines/APIM/src/Input/apis/EventIntegrationApi/*" {
			Write-Host "EventIntegrationApi changed"
			AppendQueueVariable "EventIntegrationApi"
		}
		"pipelines/APIM/src/Input/apis/FieldServiceApi/*" {
			Write-Host "FieldServiceApi changed"
			AppendQueueVariable "FieldService"
		}
		"pipelines/APIM/src/Input/apis/GeocodeApi/*" {
			Write-Host "GeocodeApi changed"
			AppendQueueVariable "GeocodeApi"
		}
		"pipelines/APIM/src/Input/apis/GeofencingApi/*" {
			Write-Host "GeofencingApi changed"
			AppendQueueVariable "GeofencingApi"
		}
		"pipelines/APIM/src/Input/apis/HeatMapServiceApi/*" {
			Write-Host "HeatMapServiceApi changed"
			AppendQueueVariable "HeatMapServiceApi"
		}
		"pipelines/APIM/src/Input/apis/HotspotServiceApi/*" {
			Write-Host "HotspotServiceApi changed"
			AppendQueueVariable "HotspotServiceApi"
		}
		"pipelines/APIM/src/Input/apis/GeometryApi/*" {
			Write-Host "GeometryApi changed"
			AppendQueueVariable "GeometryApi"
		}
		"pipelines/APIM/src/Input/apis/GeotaggingApi/*" {
			Write-Host "GeotaggingApi changed"
			AppendQueueVariable "GeotaggingApi"
		}
		"pipelines/APIM/src/Input/apis/ClosestFacilityApi/*" {
			Write-Host "ClosestFacilityApi changed"
			AppendQueueVariable "ClosestFacilityApi"
		}
		"pipelines/APIM/src/Input/apis/MapServerApi/*" {
			Write-Host "MapServerApi changed"
			AppendQueueVariable "MapServerApi"
		}
		"pipelines/APIM/src/Input/apis/SatelliteAndStreetMapApi/*" {
			Write-Host "SatelliteAndStreetMapApi changed"
			AppendQueueVariable "SatelliteAndStreetMapApi"
		}
		"pipelines/APIM/src/Input/apis/DFCFarmsWFSApi/*" {
			Write-Host "DFCFarmsWFSApi changed"
			AppendQueueVariable "DFCFarmsWFSApi"
		}
		"pipelines/APIM/src/Input/apis/DFCFarmsWMSApi/*" {
			Write-Host "DFCFarmsWMSApi changed"
			AppendQueueVariable "DFCFarmsWMSApi"
		}
		"pipelines/APIM/src/Input/apis/DFCMunicipalityWFSApi/*" {
			Write-Host "DFCMunicipalityWFSApi changed"
			AppendQueueVariable "DFCMunicipalityWFSApi"
		}
		"pipelines/APIM/src/Input/apis/DFCMunicipalityWMSApi/*" {
			Write-Host "DFCMunicipalityWMSApi changed"
			AppendQueueVariable "DFCMunicipalityWMSApi"
		}
		"pipelines/APIM/src/Input/apis/DFCZonesWFSApi/*" {
			Write-Host "DFCZonesWFSApi changed"
			AppendQueueVariable "DFCZonesWFSApi"
		}
		"pipelines/APIM/src/Input/apis/DFCZonesWMSApi/*" {
			Write-Host "DFCZonesWMSApi changed"
			AppendQueueVariable "DFCZonesWMSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISFarmsWFSApi/*" {
			Write-Host "CGISFarmsWFSApi changed"
			AppendQueueVariable "CGISFarmsWFSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISFarmsWMSApi/*" {
			Write-Host "CGISFarmsWMSApi changed"
			AppendQueueVariable "CGISFarmsWMSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISLandmarkAddLocatorAraApi/*" {
			Write-Host "CGISLandmarkAddLocatorAraApi changed"
			AppendQueueVariable "CGISLandmarkAddLocatorAraApi"
		}
		"pipelines/APIM/src/Input/apis/CGISLandmarkAddLocatorEngApi/*" {
			Write-Host "CGISLandmarkAddLocatorEngApi changed"
			AppendQueueVariable "CGISLandmarkAddLocatorEngApi"
		}
		"pipelines/APIM/src/Input/apis/CGISLandmarkRAddLocatorEngApi/*" {
			Write-Host "CGISLandmarkRAddLocatorEngApi changed"
			AppendQueueVariable "CGISLandmarkRAddLocatorEngApi"
		}
		"pipelines/APIM/src/Input/apis/CGISMunicipalityWFSApi/*" {
			Write-Host "CGISMunicipalityWFSApi changed"
			AppendQueueVariable "CGISMunicipalityWFSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISMunicipalityWMSApi/*" {
			Write-Host "CGISMunicipalityWMSApi changed"
			AppendQueueVariable "CGISMunicipalityWMSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISQatarAddLocatorApi/*" {
			Write-Host "CGISQatarAddLocatorApi changed"
			AppendQueueVariable "CGISQatarAddLocatorApi"
		}
		"pipelines/APIM/src/Input/apis/CGISQatarAddLocatorWGSApi/*" {
			Write-Host "CGISQatarAddLocatorWGSApi changed"
			AppendQueueVariable "CGISQatarAddLocatorWGSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISQatarFarmsGenSvcApi/*" {
			Write-Host "CGISQatarFarmsGenSvcApi changed"
			AppendQueueVariable "CGISQatarFarmsGenSvcApi"
		}
		"pipelines/APIM/src/Input/apis/CGISQatarMunicipalityGenSvcApi/*" {
			Write-Host "CGISQatarMunicipalityGenSvcApi changed"
			AppendQueueVariable "CGISQatarMunicipalityGenSvcApi"
		}
		"pipelines/APIM/src/Input/apis/CGISQatarZonesGenSvcApi/*" {
			Write-Host "CGISQatarZonesGenSvcApi changed"
			AppendQueueVariable "CGISQatarZonesGenSvcApi"
		}
		"pipelines/APIM/src/Input/apis/CGISRouteDistanceApi/*" {
			Write-Host "CGISRouteDistanceApi changed"
			AppendQueueVariable "CGISRouteDistanceApi"
		}
		"pipelines/APIM/src/Input/apis/CGISRouteDistanceWGSApi/*" {
			Write-Host "CGISRouteDistanceWGSApi changed"
			AppendQueueVariable "CGISRouteDistanceWGSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISRouteTimeApi/*" {
			Write-Host "CGISRouteTimeApi changed"
			AppendQueueVariable "CGISRouteTimeApi"
		}
		"pipelines/APIM/src/Input/apis/CGISRouteTimeWGSApi/*" {
			Write-Host "CGISRouteTimeWGSApi changed"
			AppendQueueVariable "CGISRouteTimeWGSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISStreetMapAraApi/*" {
			Write-Host "CGISStreetMapAraApi changed"
			AppendQueueVariable "CGISStreetMapAraApi"
		}
		"pipelines/APIM/src/Input/apis/CGISStreetMapHybridAraApi/*" {
			Write-Host "CGISStreetMapHybridAraApi changed"
			AppendQueueVariable "CGISStreetMapHybridAraApi"
		}
		"pipelines/APIM/src/Input/apis/CGISStreetMapHybridEngApi/*" {
			Write-Host "CGISStreetMapHybridEngApi changed"
			AppendQueueVariable "CGISStreetMapHybridEngApi"
		}
		"pipelines/APIM/src/Input/apis/CGISStreetMapserverApi/*" {
			Write-Host "CGISStreetMapserverApi changed"
			AppendQueueVariable "CGISStreetMapserverApi"
		}
		"pipelines/APIM/src/Input/apis/CGISTopoMapserverApi/*" {
			Write-Host "CGISTopoMapserverApi changed"
			AppendQueueVariable "CGISTopoMapserverApi"
		}
		"pipelines/APIM/src/Input/apis/CGISZonesWFSApi/*" {
			Write-Host "CGISZonesWFSApi changed"
			AppendQueueVariable "CGISZonesWFSApi"
		}
		"pipelines/APIM/src/Input/apis/CGISZonesWMSApi/*" {
			Write-Host "CGISZonesWMSApi changed"
			AppendQueueVariable "CGISZonesWMSApi"
		}
		"pipelines/APIM/src/Input/apis/KnowledgeApi/*" {
			Write-Host "Mcs.Tasmu.KnowledgebaseArticle.Api changed"
			AppendQueueVariable "KnowledgeBaseAPI"
		}
		"pipelines/APIM/src/Input/apis/MarketplaceCatalogueApi/*" {
			Write-Host "MarketplaceCatalogueApi changed"
			AppendQueueVariable "MarketplaceCatalogue"
		}
		"pipelines/APIM/src/Input/apis/NARouteApi/*" {
			Write-Host "NARouteApi changed"
			AppendQueueVariable "NARouteApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/1.0/*" {
			Write-Host "NotificationApi changed"
			AppendQueueVariable "NotificationApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationTemplateApi/*" {
			Write-Host "NotificationTemplateApi changed"
			AppendQueueVariable "NotificationTemplate"
		}
		"pipelines/APIM/src/Input/apis/OrderManagementApi/*" {
			Write-Host "OrderManagementApi changed"
			AppendQueueVariable "OrderManagementApi"
		}
		"pipelines/APIM/src/Input/apis/OrganizationProfileApi/*" {
			Write-Host "OrganisationProfile changed"
			AppendQueueVariable "OrganisationProfile"
		}
		"pipelines/APIM/src/Input/apis/OtpApi/*" {
			Write-Host "OtpApi changed"
			AppendQueueVariable "otpapi"
		}
		"pipelines/APIM/src/Input/apis/ParkingLotServiceApi/*" {
			Write-Host "ParkingLotServiceApi changed"
			AppendQueueVariable "ParkingLotServiceApi"
		}
		"pipelines/APIM/src/Input/apis/ProfileApi/*" {
			Write-Host "Profile changed"
			AppendQueueVariable "Profile"
		}
		"pipelines/APIM/src/Input/apis/SearchApis/*" {
			Write-Host "Search changed"
			AppendQueueVariable "SearchApi"
		}
		"pipelines/APIM/src/Input/apis/SmartParkingApi/*" {
			Write-Host "Smartparking changed"
			AppendQueueVariable "Smartparking"
		}		
		"pipelines/APIM/src/Input/apis/SMSProviderApi/*" {
			Write-Host "SMSProviderApi changed"
			AppendQueueVariable "SMSProviderApi"
		}
		"pipelines/APIM/src/Input/apis/SMSPublisherApi/*" {
			Write-Host "SMSPublisherApi changed"
			AppendQueueVariable "SMSPublisherApi"
		}
		"pipelines/APIM/src/Input/apis/DownloadInvoiceApi/*" {
			Write-Host "DownloadInvoiceApi changed"
			AppendQueueVariable "DownloadInvoiceApi"
		}
		"pipelines/APIM/src/Input/apis/BotDirectlineApi/*" {
			Write-Host "BotDirectlineApi changed"
			AppendQueueVariable "BotDirectlineApi"
		}
		"pipelines/APIM/src/Input/apis/PaymentApi/*" {
			Write-Host "PaymentApi changed"
			AppendQueueVariable "PaymentApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationEmailFreeApi/*" {
			Write-Host "NotificationEmailFreeApi changed"
			AppendQueueVariable "NotificationEmailFreeApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationEmailPremiumApi/*" {
			Write-Host "NotificationEmailPremiumApi changed"
			AppendQueueVariable "NotificationEmailPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationEmailStandardApi/*" {
			Write-Host "NotificationEmailStandardApi changed"
			AppendQueueVariable "NotificationEmailStandardApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationGSmsApi/*" {
			Write-Host "NotificationGSmsApi changed"
			AppendQueueVariable "NotificationGSmsApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationSmsFreeApi/*" {
			Write-Host "NotificationSmsFreeApi changed"
			AppendQueueVariable "NotificationSmsFreeApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationSmsPremiumApi/*" {
			Write-Host "NotificationSmsPremiumApi changed"
			AppendQueueVariable "NotificationSmsPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/NotificationSmsStandardApi/*" {
			Write-Host "NotificationSmsStandardApi changed"
			AppendQueueVariable "NotificationSmsStandardApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/PushNotificationFreeApi/*" {
			Write-Host "PushNotificationFreeApi changed"
			AppendQueueVariable "PushNotificationFreeApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/PushNotificationPremiumApi/*" {
			Write-Host "PushNotificationPremiumApi changed"
			AppendQueueVariable "PushNotificationPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/PushNotificationStandardApi/*" {
			Write-Host "PushNotificationStandardApi changed"
			AppendQueueVariable "PushNotificationStandardApi"
		}
		"pipelines/APIM/src/Input/apis/NotificationApi/ScheduledNotificationApi/*" {
			Write-Host "ScheduledNotificationApi changed"
			AppendQueueVariable "ScheduledNotificationApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolFreeApi/GeometryFreeApi/*" {
			Write-Host "GeometryFreeApi changed"
			AppendQueueVariable "GeometryFreeApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolStandardApi/GeometryStandardApi/*" {
			Write-Host "GeometryStandardApi changed"
			AppendQueueVariable "GeometryStandardApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolPremiumApi/GeometryPremiumApi/*" {
			Write-Host "GeometryPremiumApi changed"
			AppendQueueVariable "GeometryPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolFreeApi/GeofencingFreeApi/*" {
			Write-Host "GeofencingFreeApi changed"
			AppendQueueVariable "GeofencingFreeApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolStandardApi/GeofencingStandardApi/*" {
			Write-Host "GeofencingStandardApi changed"
			AppendQueueVariable "GeofencingStandardApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolPremiumApi/GeofencingPremiumApi/*" {
			Write-Host "GeofencingPremiumApi changed"
			AppendQueueVariable "GeofencingPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolStandardApi/GeotaggingStandardApi/*" {
			Write-Host "GeotaggingStandardApi changed"
			AppendQueueVariable "GeotaggingStandardApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolPremiumApi/GeotaggingPremiumApi/*" {
			Write-Host "GeotaggingPremiumApi changed"
			AppendQueueVariable "GeotaggingPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolPremiumApi/HeatMapPremiumServiceApi/*" {
			Write-Host "HeatMapPremiumServiceApi changed"
			AppendQueueVariable "HeatMapPremiumServiceApi"
		}
		"pipelines/APIM/src/Input/apis/GISToolApi/GISToolPremiumApi/HotspotPremiumServiceApi/*" {
			Write-Host "HotspotPremiumServiceApi changed"
			AppendQueueVariable "HotspotPremiumServiceApi"
		}
		"pipelines/APIM/src/Input/apis/SubscriptionApi/*" {
			Write-Host "SubscriptionApi changed"
			AppendQueueVariable "SubscriptionApi"
		}
		"pipelines/APIM/src/Input/apis/SubscriptionApi/SubscriptionStandardApi/*" {
			Write-Host "SubscriptionStandardApi changed"
			AppendQueueVariable "SubscriptionStandardApi"
		}
		"pipelines/APIM/src/Input/apis/SubscriptionApi/SubscriptionPremiumApi/*" {
			Write-Host "SubscriptionPremiumApi changed"
			AppendQueueVariable "SubscriptionPremiumApi"
		}
		"pipelines/APIM/src/Input/apis/SMSGatewayApi/SMSGatewayDomesticApi/*" {
			Write-Host "SMSGatewayDomesticApi changed"
			AppendQueueVariable "SMSGatewayDomesticApi"
		}
		"pipelines/APIM/src/Input/apis/SMSGatewayApi/SMSGatewayInternationalApi/*" {
			Write-Host "SMSGatewayInternationalApi changed"
			AppendQueueVariable "SMSGatewayInternationalApi"
		}
		"pipelines/APIM/src/Input/apis/NationalGeospatialServicesApi/BaseMapServicesApi/StreetMapHybridArabicApi/*" {
			Write-Host "StreetMapHybridArabicApi changed"
			AppendQueueVariable "StreetMapHybridArabicApi"
		}
		"pipelines/APIM/src/Input/apis/NationalGeospatialServicesApi/BaseMapServicesApi/StreetMapHybridEnglishApi/*" {
			Write-Host "StreetMapHybridEnglishApi changed"
			AppendQueueVariable "StreetMapHybridEnglishApi"
		}
		"pipelines/APIM/src/Input/apis/NationalGeospatialServicesApi/GeocodingandSearchServicesApi/AddressLocatorArabicApi/*" {
			Write-Host "AddressLocatorArabicApi changed"
			AppendQueueVariable "AddressLocatorArabicApi"
		}
		"pipelines/APIM/src/Input/apis/NationalGeospatialServicesApi/GeocodingandSearchServicesApi/AddressLocatorWGS84EnglishApi/*" {
			Write-Host "AddressLocatorWGS84EnglishApi changed"
			AppendQueueVariable "AddressLocatorWGS84EnglishApi"
		}
		"pipelines/APIM/src/Input/apis/NationalGeospatialServicesApi/RoutingServicesApi/RoutingDistanceWGS84Api/*" {
			Write-Host "RoutingDistanceWGS84Api changed"
			AppendQueueVariable "RoutingDistanceWGS84Api"
		}
		"pipelines/APIM/src/Input/apis/NationalGeospatialServicesApi/RoutingServicesApi/RoutingTimeWGS84Api/*" {
			Write-Host "RoutingTimeWGS84Api changed"
			AppendQueueVariable "RoutingTimeWGS84Api"
		}
		"pipelines/APIM/src/Input/apis/BackOfficeAdminPortalApi/*" {
			Write-Host "BackOfficeAdminPortalApi changed"
			AppendQueueVariable "BackOfficeAdminPortalApi"
		}
		"pipelines/APIM/src/Input/apis/UC-SmartParkingApi/*" {
            Write-Host "UC-SmartParkingApi changed"
            AppendQueueVariable "UC-SmartParkingApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCWFSApi/*" {
            Write-Host "UCTTCCWFSApi changed"
            AppendQueueVariable "UCTTCCWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCWMSApi/*" {
            Write-Host "UCTTCCWMSApi changed"
            AppendQueueVariable "UCTTCCWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCSignalPolesWFSApi/*" {
            Write-Host "UCTTCCSignalPolesWFSApi changed"
            AppendQueueVariable "UCTTCCSignalPolesWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCSignalPolesWMSApi/*" {
            Write-Host "UCTTCCSignalPolesWMSApi changed"
            AppendQueueVariable "UCTTCCSignalPolesWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCTrafficSignsWMSApi/*" {
            Write-Host "UCTTCCTrafficSignsWMSApi changed"
            AppendQueueVariable "UCTTCCTrafficSignsWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCTrafficSignsWFSApi/*" {
            Write-Host "UCTTCCTrafficSignsWFSApi changed"
            AppendQueueVariable "UCTTCCTrafficSignsWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCPOIWFSApi/*" {
            Write-Host "UCTTCCPOIWFSApi changed"
            AppendQueueVariable "UCTTCCPOIWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCPOIWMSApi/*" {
            Write-Host "UCTTCCPOIWMSApi changed"
            AppendQueueVariable "UCTTCCPOIWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCFlowlineWFSApi/*" {
            Write-Host "UCTTCCFlowlineWFSApi changed"
            AppendQueueVariable "UCTTCCFlowlineWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCFlowlineWMSApi/*" {
            Write-Host "UCTTCCFlowlineWMSApi changed"
            AppendQueueVariable "UCTTCCFlowlineWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCMetroAlignmentWFSApi/*" {
            Write-Host "UCTTCCMetroAlignmentWFSApi changed"
            AppendQueueVariable "UCTTCCMetroAlignmentWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCMetroAlignmentWMSApi/*" {
            Write-Host "UCTTCCMetroAlignmentWMSApi changed"
            AppendQueueVariable "UCTTCCMetroAlignmentWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCMetroStationsWFSApi/*" {
            Write-Host "UCTTCCMetroStationsWFSApi changed"
            AppendQueueVariable "UCTTCCMetroStationsWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCMetroStationsWMSApi/*" {
            Write-Host "UCTTCCMetroStationsWMSApi changed"
            AppendQueueVariable "UCTTCCMetroStationsWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCStationEntriesWFSApi/*" {
            Write-Host "UCTTCCStationEntriesWFSApi changed"
            AppendQueueVariable "UCTTCCStationEntriesWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCStationEntriesWMSApi/*" {
            Write-Host "UCTTCCStationEntriesWMSApi changed"
            AppendQueueVariable "UCTTCCStationEntriesWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCLRTAlignmentWMSApi/*" {
            Write-Host "UCTTCCLRTAlignmentWMSApi changed"
            AppendQueueVariable "UCTTCCLRTAlignmentWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCLRTAlignmentWFSApi/*" {
            Write-Host "UCTTCCLRTAlignmentWFSApi changed"
            AppendQueueVariable "UCTTCCLRTAlignmentWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCLRTStationsWFSApi/*" {
            Write-Host "UCTTCCLRTStationsWFSApi changed"
            AppendQueueVariable "UCTTCCLRTStationsWFSApi"
        }
		"pipelines/APIM/src/Input/apis/UCTTCCApi/UCTTCCLRTStationsWMSApi/*" {
            Write-Host "UCTTCCLRTStationsWMSApi changed"
            AppendQueueVariable "UCTTCCLRTStationsWMSApi"
        }
		"pipelines/APIM/src/Input/apis/UberApi/*" {
            Write-Host "UberApi changed"
            AppendQueueVariable "UberApi"
        }
		"pipelines/APIM/src/Input/apis/HeatMapApi/*" {
            Write-Host "HeatMapApi changed"
            AppendQueueVariable "HeatMapApi"
        }
		"pipelines/APIM/src/Input/apis/HayyaApi/*" {
            Write-Host "HayyaApi changed"
            AppendQueueVariable "HayyaApi"
        }
		# The rest of your path filters
	}
}

Write-Host "Build Queue: $global:buildQueueVariable"
Write-Host "##vso[task.setvariable variable=buildQueue;isOutput=true]$global:buildQueueVariable"