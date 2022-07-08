export interface ISPHubSites {
    ContentTypeId?: string;
    WebTemplate?: string;
    Id?: string;
    Url?: string;
    OriginalUrl?: string;
    Title?: string;
    Type?: string;
    GroupId?: string;
    WebId?: string;
    SiteId?: string;
}

export interface Token {
    access_token: string;
    resource: string;
}