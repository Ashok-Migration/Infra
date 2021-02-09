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

    // check for entity
    var entityCheck = siteName.split("-");
    if (entityCheck.length == 4) {
      var sectorSiteName = entityCheck[0] + "-" + entityCheck[1] + "-" + entityCheck[2];
      cssUrl = "/Style%20Library/" + sectorSiteName + "-customstyle.css";
    }

    // inject the css
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
        } else {
          console.info("CSS File Not Found, applying default styling");
          cssUrl = "/Style%20Library/customsector.css";
          const head: any = document.getElementsByTagName("head")[0] || document.documentElement;
          let customStyle: HTMLLinkElement = document.createElement("link");
          customStyle.href = cssUrl;
          customStyle.rel = "stylesheet";
          customStyle.type = "text/css";
          head.insertAdjacentElement("beforeEnd", customStyle);
        }
      });

    const headers = (document.querySelectorAll(`span[data-automationid='HorizontalNav-link']`));
    headers.forEach((header: any) => {
      header.onmouseover = () => {
        //Set opening of links in new tabs for Sectors and CMS Home headings in English and Arabic
        if (
          header.innerText.indexOf('Sectors') > -1 ||
          header.innerText.indexOf('CMS Home') > -1 ||
          header.innerText.indexOf('القطاعات') > -1 ||
          header.innerText.indexOf('CMS الرئيسية') > -1
        ) {
          this.updateNavLinks('SiteHeader');
          this.updateNavLinks('HubNav');
        } else {
          this.resetNavLinks('SiteHeader');
          this.resetNavLinks('HubNav');
        }
      };
    });

    //Check for Tenant Logo link's target and set it to open in new tab
    const logoTimer = setInterval(() => {
      const logoLink = document.querySelector("#O365_MainLink_TenantLogo");
      if (logoLink.getAttribute("target")) {
        clearInterval(logoTimer);
      }
      logoLink.setAttribute('target', '_blank');
      logoLink.setAttribute('data-interception', 'off');
    }, 1000);

    return Promise.resolve();
  }

  /**
   * Opens all header links in new tabs
   * @param dataNavComponent Id of the data-navigationcomponent
   */
  private updateNavLinks(dataNavComponent: string) {
    const headers = (document.querySelectorAll(`a[data-navigationcomponent='${dataNavComponent}']`));
    headers.forEach((header: any) => {
      header.setAttribute('target', '_blank');
      header.setAttribute('data-interception', 'off');
    });
  }

  /**
   * Opens SharePoint links in same tab and external links in new tabs
   * @param dataNavComponent Id of the data-navigationcomponent
   */
  private resetNavLinks(dataNavComponent: string) {
    const headers = (document.querySelectorAll(`a[data-navigationcomponent='${dataNavComponent}']`));
    headers.forEach((header) => {
      if (header.getAttribute('href').indexOf('/sites/') > -1) {
        header.setAttribute('target', '_self');
        header.setAttribute('data-interception', 'propagate');
      } else {
        header.setAttribute('target', 'blank');
        header.setAttribute('data-interception', 'off');
      }
    });
  }
}
