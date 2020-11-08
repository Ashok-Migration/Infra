import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseApplicationCustomizer
} from '@microsoft/sp-application-base';
import { Dialog } from '@microsoft/sp-dialog';

import * as strings from 'GlobalCustomStyleApplicationCustomizerStrings';

const LOG_SOURCE: string = 'GlobalCustomStyleApplicationCustomizer';
export interface IGlobalCustomStyleApplicationCustomizerProperties {
  cssurl: string;
}

export default class GlobalCustomStyleApplicationCustomizer
  extends BaseApplicationCustomizer<IGlobalCustomStyleApplicationCustomizerProperties> {

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, `Initialized ${strings.Title}`);

    const cssUrl: string = this.properties.cssurl;
    if (cssUrl) {
      // inject the style sheet
      const head: any = document.getElementsByTagName("head")[0] || document.documentElement;
      let customStyle: HTMLLinkElement = document.createElement("link");
      customStyle.href = cssUrl;
      customStyle.rel = "stylesheet";
      customStyle.type = "text/css";
      head.insertAdjacentElement("beforeEnd", customStyle);
     }

    return Promise.resolve();
  }
}
