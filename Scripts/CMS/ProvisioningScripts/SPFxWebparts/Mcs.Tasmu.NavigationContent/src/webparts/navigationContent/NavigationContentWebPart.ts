import * as React from 'react';
import * as ReactDom from 'react-dom';
import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField,
  PropertyPaneToggle
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

import * as strings from 'NavigationContentWebPartStrings';
import NavigationContent from './components/NavigationContent';
import { INavigationContentProps } from './components/INavigationContentProps';

export interface INavigationContentWebPartProps {
  marketplaceUrl: string;
  showEntities: boolean;
}

export default class NavigationContentWebPart extends BaseClientSideWebPart<INavigationContentWebPartProps> {

  public render(): void {
    const element: React.ReactElement<INavigationContentProps> = React.createElement(
      NavigationContent,
      {
        context: this.context,
        marketplaceUrl: this.properties.marketplaceUrl,
        showEntities: this.properties.showEntities
      }
    );

    ReactDom.render(element, this.domElement);
  }

  protected onDispose(): void {
    ReactDom.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [
        {
          header: {
            description: strings.PropertyPaneDescription
          },
          groups: [
            {
              groupName: strings.BasicGroupName,
              groupFields: [
                PropertyPaneTextField('marketplaceUrl', {
                  label: strings.MarketplaceUrlLabel
                }),
                PropertyPaneToggle('showEntities', {
                  label: strings.ShowEntitiesLabel,
                  onText: strings.ShowEntitiesYesLabel,
                  offText: strings.ShowEntitiesNoLabel,
                  checked: false
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
