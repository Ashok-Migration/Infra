import { INavigation } from "./ISPHubSiteData";
import { ISPHubSites } from "./ISPHubSites";

export interface ISPHubSiteCollection {
    Description?: string;
    ID?: string;
    LogoUrl?: string;
    SiteId?: string;
    SiteUrl?: string;
    Targets?: string;
    TenantInstanceId?: string;
    Title?: string;
    Sites?: ISPHubSites[];
    HasPermission?: boolean;
}