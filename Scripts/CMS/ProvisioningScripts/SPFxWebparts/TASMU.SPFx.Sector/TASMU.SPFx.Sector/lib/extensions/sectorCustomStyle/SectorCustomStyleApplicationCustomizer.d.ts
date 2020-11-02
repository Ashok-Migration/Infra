import { BaseApplicationCustomizer } from '@microsoft/sp-application-base';
export interface ISectorCustomStyleApplicationCustomizerProperties {
    cssurl: string;
}
export default class SectorCustomStyleApplicationCustomizer extends BaseApplicationCustomizer<ISectorCustomStyleApplicationCustomizerProperties> {
    onInit(): Promise<void>;
}
//# sourceMappingURL=SectorCustomStyleApplicationCustomizer.d.ts.map