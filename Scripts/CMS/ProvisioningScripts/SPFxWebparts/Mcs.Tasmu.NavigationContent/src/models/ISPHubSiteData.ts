export interface ISPHubSiteData {
    themeKey?: string;
    name?: string;
    url?: string;
    logoUrl?: string;
    usesMetadataNavigation?: boolean;
    navigation?: INavigation[];
}

export interface INavigation {
    Id?: string;
    Title?: string;
    Url?: string;
    IsDocLib?: boolean;
    IsExternal?: boolean;
    ParentId?: number;
    ListTemplateType?: number;
    Children?: INavigation[];
}