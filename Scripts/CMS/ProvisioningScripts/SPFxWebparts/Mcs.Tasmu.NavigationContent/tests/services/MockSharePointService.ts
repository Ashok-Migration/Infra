import { ISharePointService } from "../../src/services/SharePointService/ISharePointService";
import { ISPHubSiteCollection } from "../../src/models/ISPHubSiteCollection";
import { ISPHubSites } from "../../src/models/ISPHubSites";

export class MockSharePointService implements ISharePointService {
    getHubSites(showEntities: boolean): Promise<ISPHubSiteCollection[]> {
        const response = new Promise<ISPHubSiteCollection[]>((resolve, reject) => {
            let list: ISPHubSiteCollection[] = [];
            let item = {
                ID: '1', SiteUrl: 'https://tasmusqcp.sharepoint.com/sites/cms-dev-healthsector',
                Description: 'Health site', HasPermission: true,
                LogoUrl: 'logo url', TenantInstanceId: '', Targets: '',
                Title: 'Health', SiteId: '16CF622B-02F5-47E9-B4CC-869C0C67BFB8',
                Sites: [{
                    Title: 'Eastside', SiteId: '1E7E76A4-EA85-4664-AA6A-D3CB652FD1FB',
                    ContentTypeId: 'site', GroupId: 'G1', Id: '1',
                    OriginalUrl: 'https://tasmusqcp.sharepoint.com/sites/cms-dev-healthsector-easthideorg',
                    Type: 'Site',
                    Url: 'https://tasmusqcp.sharepoint.com/sites/cms-dev-healthsector-easthideorg'
                }]
            } as ISPHubSiteCollection;
            let marketPlace = {
                ID: '1', SiteUrl: 'https://tasmusqcp.sharepoint.com/sites/cms-dev-marketplace/',
                Description: 'Marktplace', HasPermission: false,
                LogoUrl: 'logo url', TenantInstanceId: '', Targets: '',
                Title: 'Marketplace', SiteId: '61D10921-EECB-4F43-92D4-043DA1059A1E'
            } as ISPHubSiteCollection;
            list.push(item);
            list.push(marketPlace);
        });
        return response;
    }

    getSitesInHubSite(): Promise<ISPHubSites[]> {
        const response = new Promise<ISPHubSites[]>((resolve, reject) => {
            let list: ISPHubSites[] = [];
            let item = {
                Title: 'Eastside', SiteId: '1E7E76A4-EA85-4664-AA6A-D3CB652FD1FB',
                ContentTypeId: 'site', GroupId: 'G1', Id: '1',
                OriginalUrl: 'https://tasmusqcp.sharepoint.com/sites/cms-dev-healthsector-easthideorg',
                Type: 'Site',
                Url: 'https://tasmusqcp.sharepoint.com/sites/cms-dev-healthsector-easthideorg'
            } as ISPHubSites;
            list.push(item);
        });
        return response;
    }

}
