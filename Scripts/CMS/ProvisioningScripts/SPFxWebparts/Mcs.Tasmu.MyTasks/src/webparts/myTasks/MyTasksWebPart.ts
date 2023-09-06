import * as React from 'react';
import * as ReactDom from 'react-dom';
import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField,
  PropertyPaneChoiceGroup,
  PropertyPaneSlider,
  PropertyPaneDropdown,
  IPropertyPaneDropdownOption
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { sp } from "@pnp/sp/presets/all";
import { PropertyFieldListPicker } from '@pnp/spfx-property-controls/lib/PropertyFieldListPicker';
import * as strings from 'MyTasksWebPartStrings';
import MyTasks from './components/MyTasks';
import { IMyTasksProps } from './components/IMyTasksProps';
import CompactMyTasks from './components/CompactMyTasks/CompactMyTasks';
import { ICompactMyTasksProps } from './components/CompactMyTasks/ICompactMyTasksProps';
import { SharePointService } from '../../services/SharePointService';
require('./override.css');

export interface IMyTasksWebPartProps {
  webPartTitle: string;
  arWebPartTitle: string;
  viewMode: string;
  list: string;
  approvalTaskContentType: string;
  translationTaskContentType: string;
  itemsPerPage: number;
  seeAllLink: string;
}

export default class MyTasksWebPart extends BaseClientSideWebPart<IMyTasksWebPartProps> {
  private allContentTypesList: IPropertyPaneDropdownOption[];
  private sharePointServiceInstance: SharePointService;

  public render(): void {
    let element: React.ReactElement<IMyTasksProps | ICompactMyTasksProps>;
    if (this.properties.viewMode === 'Compact') {
      element = React.createElement(
        CompactMyTasks,
        {
          webPartTitle: this.getWebPartTitle(),
          list: this.properties.list,
          approvalTaskContentType: this.properties.approvalTaskContentType,
          translationTaskContentType: this.properties.translationTaskContentType,
          sharePointService: this.sharePointServiceInstance,
          itemsPerPage: this.properties.itemsPerPage,
          userName: this.context.pageContext.user.displayName,
          seeAllLink: this.properties.seeAllLink
        }
      );
    } else {
      element = React.createElement(
        MyTasks,
        {
          webPartTitle: this.getWebPartTitle(),
          list: this.properties.list,
          approvalTaskContentType: this.properties.approvalTaskContentType,
          translationTaskContentType: this.properties.translationTaskContentType,
          sharePointService: this.sharePointServiceInstance,
          itemsPerPage: this.properties.itemsPerPage,
          userName: this.context.pageContext.user.displayName
        }
      );
    }
    ReactDom.render(element, this.domElement);
  }

  protected async onInit() {
    await super.onInit();
    sp.setup({
      spfxContext: this.context
    });
    this.sharePointServiceInstance = new SharePointService();
    await this.sharePointServiceInstance.setUserId();
  }

  protected onDispose(): void {
    ReactDom.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected onPropertyPaneConfigurationStart() {
    if (this.properties.list) {
      this.sharePointServiceInstance.getContentTypes(this.properties.list).then((allContentTypesItems) => {
        const allContentTypesList: IPropertyPaneDropdownOption[] = [];
        allContentTypesItems.map((contentType) => {
          allContentTypesList.push({
            key: contentType.StringId,
            text: contentType.Name
          });
        });
        this.allContentTypesList = allContentTypesList;
        this.context.propertyPane.refresh();
      });
    }
  }

  protected onPropertyPaneFieldChanged(propertyPath: string, oldValue: string, newValue: string) {
    /* Get updated list of all content types corresponding to the selected list*/
    if (propertyPath === 'list') {
      super.onPropertyPaneFieldChanged(propertyPath, oldValue, newValue);
      this.context.propertyPane.refresh();

      if (this.properties.list) {
        this.sharePointServiceInstance.getContentTypes(this.properties.list).then((allContentTypesItems) => {
          const allContentTypesList: IPropertyPaneDropdownOption[] = [];
          allContentTypesItems.map((contentType) => {
            allContentTypesList.push({
              key: contentType.StringId,
              text: contentType.Name
            });
          });
          this.allContentTypesList = allContentTypesList;
          this.context.propertyPane.refresh();
        });
      }
    } else {
      super.onPropertyPaneFieldChanged(propertyPath, oldValue, newValue);
    }
  }

  private getWebPartTitle(): string {
    const locale: string = this.context.pageContext.cultureInfo.currentUICultureName;
    if (locale.indexOf('ar') > -1) {
      return this.properties.arWebPartTitle;
    }
    return this.properties.webPartTitle;
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
                PropertyPaneTextField('webPartTitle', {
                  label: strings.WebPartTitleFieldLabel
                }),
                PropertyPaneTextField('arWebPartTitle', {
                  label: strings.WebPartTitleArFieldLabel
                }),
                PropertyPaneChoiceGroup('viewMode', {
                  label: strings.ViewModeFieldLabel,
                  options: [
                    {
                      key: 'Compact',
                      text: strings.CompactViewLabel
                    },
                    {
                      key: 'Detailed',
                      text: strings.DetailedViewLabel
                    }
                  ]
                }),
                PropertyFieldListPicker('list', {
                  label: strings.ListPickerFieldLabel,
                  selectedList: this.properties.list,
                  includeHidden: false,
                  disabled: false,
                  onPropertyChange: this.onPropertyPaneFieldChanged.bind(this),
                  properties: this.properties,
                  context: this.context,
                  onGetErrorMessage: null,
                  deferredValidationTime: 0,
                  key: 'listPickerFieldId'
                }),
                PropertyPaneDropdown('translationTaskContentType', {
                  label: strings.TranslationTaskContentTypeFieldLabel,
                  options: this.allContentTypesList
                }),
                PropertyPaneDropdown('approvalTaskContentType', {
                  label: strings.ApprovalTaskContentTypeFieldLabel,
                  options: this.allContentTypesList
                }),
                PropertyPaneSlider('itemsPerPage', {
                  label: strings.ItemsPerPageFieldLabel,
                  min: 1,
                  max: 100,
                  value: 5,
                  showValue: true,
                  step: 1
                }),
                PropertyPaneTextField('seeAllLink', {
                  label: strings.SeeAllLinkLabelField,
                  disabled: this.properties.viewMode === 'Detailed'
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
