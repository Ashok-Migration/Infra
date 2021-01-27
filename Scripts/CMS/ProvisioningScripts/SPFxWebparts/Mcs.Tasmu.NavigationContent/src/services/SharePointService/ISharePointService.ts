import { ISPHubSiteCollection } from "../../models/ISPHubSiteCollection";
import { ISPHubSites } from "../../models/ISPHubSites";

export interface ISharePointService {
    getHubSites(showEntities: boolean): Promise<ISPHubSiteCollection[]>;

    getSitesInHubSite(): Promise<ISPHubSites[]>;
}
