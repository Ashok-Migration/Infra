import { BaseApplicationCustomizer } from '@microsoft/sp-application-base';
export interface IGlobalCustomStyleApplicationCustomizerProperties {
    cssurl: string;
}
export default class GlobalCustomStyleApplicationCustomizer extends BaseApplicationCustomizer<IGlobalCustomStyleApplicationCustomizerProperties> {
    onInit(): Promise<void>;
}
//# sourceMappingURL=GlobalCustomStyleApplicationCustomizer.d.ts.map