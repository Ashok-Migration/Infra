import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseListViewCommandSet,
  Command,
  IListViewCommandSetListViewUpdatedParameters,
  IListViewCommandSetExecuteEventParameters
} from '@microsoft/sp-listview-extensibility';
import { SPComponentLoader } from '@microsoft/sp-loader';
import * as strings from 'CopyCdnUrlCommandSetStrings';
import * as copy from 'copy-to-clipboard';
import swal from 'sweetalert2';

/**
 * If your command set uses the ClientSideComponentProperties JSON input,
 * it will be deserialized into the BaseExtension.properties object.
 * You can define an interface to describe it.
 */
export interface ICopyCdnUrlCommandSetProperties {
  showToastr: string;
}

const LOG_SOURCE: string = 'CopyCdnUrlCommandSet';

export default class CopyCdnUrlCommandSet extends BaseListViewCommandSet<ICopyCdnUrlCommandSetProperties> {

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, 'Initialized CopyCdnUrlCommandSet');
    return Promise.resolve();
  }

  @override
  public onListViewUpdated(event: IListViewCommandSetListViewUpdatedParameters): void {
    const copyCDNUrlcommand: Command = this.tryGetCommand('COPY_CDN_URL');
    if (copyCDNUrlcommand) {
      const locale: string = this.context.pageContext.cultureInfo.currentUICultureName;
      if (locale.indexOf('ar') > -1) {
        copyCDNUrlcommand.title = "نسخ رابط شبكة توصيل المحتوى";
      }
      // This command should be hidden unless exactly one row is selected.
      copyCDNUrlcommand.visible = event.selectedRows.length === 1;
    }
  }

  @override
  public onExecute(event: IListViewCommandSetExecuteEventParameters): void {
    switch (event.itemId) {
      case 'COPY_CDN_URL':
        const cdnUrl: string = event.selectedRows[0].getValueByName('cdnurl');
        copy(cdnUrl);
        this.showSwal(cdnUrl);
        break;
      default:
        throw new Error('Unknown command');
    }
  }
  private async showSwal(fullItemUrl: string) {
    let imageExtensions: Array<string> = ["jpg", "jpeg", "png"];
    let re = /(?:\.([^.]+))?$/;
    let ext = re.exec(fullItemUrl);

    if (imageExtensions.indexOf(ext[1]) > -1) {
      swal({
        title: strings.LinkCopiedLabel,
        text: strings.UseCopiedLinkLabel,
        type: 'success',
        imageUrl: fullItemUrl,
        imageHeight: 50,
        imageAlt: 'Image'
      });
    }
    else {
      swal(
        strings.LinkCopiedLabel,
        strings.UseCopiedLinkLabel,
        'success'
      );
    }
  }
}
