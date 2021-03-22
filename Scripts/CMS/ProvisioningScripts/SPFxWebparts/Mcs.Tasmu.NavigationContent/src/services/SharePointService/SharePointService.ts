import { ServiceKey, ServiceScope, Guid } from '@microsoft/sp-core-library';
import { ISPHttpClientOptions, SPHttpClient, SPHttpClientResponse, IHttpClientOptions, HttpClientResponse } from '@microsoft/sp-http';
import { PageContext } from '@microsoft/sp-page-context';
import { ISharePointService } from "./ISharePointService";
import { ISPHubSiteCollection } from '../../models/ISPHubSiteCollection';
import { ISPHubSites, Token } from '../../models/ISPHubSites';

export class SharePointService implements ISharePointService {

  public static readonly serviceKey: ServiceKey<ISharePointService> =
    ServiceKey.create<ISharePointService>('mcs-tasmu-spfx', SharePointService);

  private _spHttpClient: SPHttpClient;
  private _pageContext: PageContext;
  private _currentWebUrl: string;

  constructor(serviceScope: ServiceScope) {
    serviceScope.whenFinished(() => {
      this._spHttpClient = serviceScope.consume(SPHttpClient.serviceKey);
      this._pageContext = serviceScope.consume(PageContext.serviceKey);
      this._currentWebUrl = this._pageContext.web.absoluteUrl;
    });
  }

  public async getHubSites(showEntities: boolean): Promise<ISPHubSiteCollection[]> {
    const requestUri = `${this._currentWebUrl}/_api/HubSites?$select=SiteUrl,SiteId,Title`;
    const httpClientOptions: ISPHttpClientOptions = {};
    const response: SPHttpClientResponse = await this._spHttpClient.fetch(requestUri, SPHttpClient.configurations.v1, httpClientOptions);
    const responseJson: any = await response.json();
    let spHubSiteCollection: ISPHubSiteCollection[] = responseJson.value;
    //Get hub sites with unique SiteUrl
    spHubSiteCollection = spHubSiteCollection.filter((x, i, arr) => {
      return arr.indexOf(arr.find(t => t.SiteUrl === x.SiteUrl)) === i;
    });

    const promises = spHubSiteCollection.map(async item => {
      let getSitesInHubSite: Promise<ISPHubSites[]>;
      if (showEntities) {
        getSitesInHubSite = this.getSitesInHubSite(item.SiteId);
      }
      const getSitePermission = this.getSitePermission(item.SiteUrl);
      const sitePromises = await Promise.all([getSitesInHubSite, getSitePermission]);
      console.log('URL: ', item.SiteUrl, 'PERM: ', sitePromises[1]);
      item.HasPermission = sitePromises[1];

      // Override Title of the site
      var requestTitleUri = `${item.SiteUrl}/_api/web/title`;
      var responseTitle: SPHttpClientResponse = await this._spHttpClient.fetch(requestTitleUri, SPHttpClient.configurations.v1, httpClientOptions);
      var responseTitleJson: any = await responseTitle.json();
      var localeTitle = responseTitleJson.value;
      item.Title = localeTitle;

      item.Sites = sitePromises[0] ? sitePromises[0] : [];

      // Override title of Entity Tites
      if (item.Sites.length > 0) {
        for (let i = 0; i < item.Sites.length; i++) {
          var requestEntityTitleUri = `${item.Sites[i].Url}/_api/web/title`;
          var responseEntityTitle = await this._spHttpClient.fetch(requestEntityTitleUri, SPHttpClient.configurations.v1, httpClientOptions);
          var responseEntityTitleJson = await responseEntityTitle.json();
          var localeEntityTitle = responseEntityTitleJson.value;
          item.Sites[i].Title = localeEntityTitle;
        }
      }
      // If associated hubsites is 0, then dont show Hub Site
      return item;
    });
    spHubSiteCollection = await Promise.all(promises.map((p: any) => p.catch((error: any) => null)));
    return spHubSiteCollection;
  }

  public async getSitesInHubSite(hubSiteId?: string): Promise<ISPHubSites[]> {
    const token = await this.getToken();
    const requestUri = `${token.resource}/api/v1/sites/hub/feed?departmentId=${hubSiteId}`;
    const httpClientOptions: IHttpClientOptions = {
      headers: {
        'authorization': `Bearer ${token.access_token}`,
        'sphome-apicontext': `{"PortalUrl":"https://${window.location.host}"}`
      }
    };
    const response: HttpClientResponse = await this._spHttpClient.fetch(requestUri, SPHttpClient.configurations.v1, httpClientOptions);
    const responseJson: any = await response.json();
    const sitesInHubSite: ISPHubSites[] = responseJson.Items.map((item: any) => {
      const site: ISPHubSites = {
        ContentTypeId: item.ContentTypeId,
        WebTemplate: item.WebTemplate,
        Url: item.Url,
        OriginalUrl: item.OriginalUrl,
        Title: item.Title,
        Type: item.Type,
        GroupId: item.ItemReference.GroupId,
        WebId: item.ItemReference.WebId,
        SiteId: item.ItemReference.SiteId
      };
      return site;
    });

    return sitesInHubSite.filter(site => {
      return !Guid.parse(site.SiteId).equals(Guid.parse(hubSiteId));
    });
  }

  private async getToken(): Promise<Token> {
    const requestUri = `${this._currentWebUrl}/_api/sphomeservice/context?$expand=Token`;
    const httpClientOptions: ISPHttpClientOptions = {};
    const response: SPHttpClientResponse = await this._spHttpClient.fetch(requestUri, SPHttpClient.configurations.v1, httpClientOptions);
    const responseJson: any = await response.json();
    return responseJson.Token;
  }

  private async getSitePermission(siteUrl?: string): Promise<boolean> {
    const requestUri = `${siteUrl}/_api/Web/effectiveBasePermissions`;
    const httpClientOptions: ISPHttpClientOptions = {};
    const response: HttpClientResponse = await this._spHttpClient.fetch(requestUri, SPHttpClient.configurations.v1, httpClientOptions);
    const responseJson: any = await response.json();
    if (responseJson.High !== undefined) { return true; }
    else { return false; }
  }
}
