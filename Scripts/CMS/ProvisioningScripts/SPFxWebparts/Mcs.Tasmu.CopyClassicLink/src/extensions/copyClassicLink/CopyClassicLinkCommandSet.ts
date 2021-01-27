import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseListViewCommandSet,
  Command,
  IListViewCommandSetListViewUpdatedParameters,
  IListViewCommandSetExecuteEventParameters
} from '@microsoft/sp-listview-extensibility';
import { SPComponentLoader } from '@microsoft/sp-loader';
import * as strings from 'CopyClassicLinkCommandSetStrings';
import * as copy from 'copy-to-clipboard';
import swal from 'sweetalert2';

export interface ICopyClassicLinkCommandSetProperties {
  showToastr: string;
}

const LOG_SOURCE: string = 'CopyClassicLinkCommandSet';

export default class CopyClassicLinkCommandSet extends BaseListViewCommandSet<ICopyClassicLinkCommandSetProperties> {

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, 'Initialized CopyClassicLinkCommandSet');
    return Promise.resolve();
  }

  @override
  public onListViewUpdated(event: IListViewCommandSetListViewUpdatedParameters): void {
    const copyClassicLinkCommand: Command = this.tryGetCommand('COPY_CLASSIC_LINK');
    if (copyClassicLinkCommand) {
      // This command should be hidden unless exactly one row is selected.
      copyClassicLinkCommand.visible = event.selectedRows.length === 1;
    }
  }

  @override
  public onExecute(event: IListViewCommandSetExecuteEventParameters): void {
    switch (event.itemId) {
      case 'COPY_CLASSIC_LINK':
        const itemName: string = event.selectedRows[0].getValueByName('FileRef');
        const absoluteUrl: string = this.context.pageContext.web.absoluteUrl;
        const fullItemUrl: string = `${absoluteUrl.substring(0, absoluteUrl.indexOf('.com') + 4)}${itemName}`;
        copy(fullItemUrl);
        if (this.properties.showToastr.toLowerCase() === "yes") {
          this.showToastr();
        }
        else {
          this.showSwal(fullItemUrl);
        }
        break;
      default:
        throw new Error('Unknown command');
    }
  }

  private async showToastr() {
    let toastr: any = await import(
      /* webpackChunkName: 'toastr-js' */
      'toastr'
    );
    SPComponentLoader.loadCss('https://cdnjs.cloudflare.com/ajax/libs/toastr.js/latest/toastr.min.css');
    toastr.success(`${strings.LinkCopiedLabel} ${strings.UseCopiedLinkLabel}`);
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
