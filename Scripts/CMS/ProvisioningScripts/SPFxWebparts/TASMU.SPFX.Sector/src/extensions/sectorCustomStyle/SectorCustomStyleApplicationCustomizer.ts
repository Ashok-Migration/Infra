import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseApplicationCustomizer
} from '@microsoft/sp-application-base';
import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';

import * as strings from 'SectorCustomStyleApplicationCustomizerStrings';

const LOG_SOURCE: string = 'SectorCustomStyleApplicationCustomizer';
export interface ISectorCustomStyleApplicationCustomizerProperties {
  cssurl: string;
}

export default class SectorCustomStyleApplicationCustomizer
  extends BaseApplicationCustomizer<ISectorCustomStyleApplicationCustomizerProperties> {

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, `Initialized ${strings.Title}`);
    let ServerRelativeUrl = this.context.pageContext.site.serverRelativeUrl;
    let site = ServerRelativeUrl.split("/");
    var siteName = site[2];
    var cssUrl: string = "/Style%20Library/" + siteName + "-customstyle.css";
    this.context.spHttpClient.get(`${cssUrl}`,
      SPHttpClient.configurations.v1)
      .then((response: SPHttpClientResponse) => {
        if (response && response.ok) {
          console.info("CSS File Found");
          const head: any = document.getElementsByTagName("head")[0] || document.documentElement;
          let customStyle: HTMLLinkElement = document.createElement("link");
          customStyle.href = cssUrl;
          customStyle.rel = "stylesheet";
          customStyle.type = "text/css";
          head.insertAdjacentElement("beforeEnd", customStyle);
        }
        else {
          console.info("CSS File Not Found, applying default styling");
          cssUrl = "/Style%20Library/customsector.css";
          const head: any = document.getElementsByTagName("head")[0] || document.documentElement;
          let customStyle: HTMLLinkElement = document.createElement("link");
          customStyle.href = cssUrl;
          customStyle.rel = "stylesheet";
          customStyle.type = "text/css";
          head.insertAdjacentElement("beforeEnd", customStyle);
        }
      }
      );

    // inject the style sheet

    return Promise.resolve();
  }
}
