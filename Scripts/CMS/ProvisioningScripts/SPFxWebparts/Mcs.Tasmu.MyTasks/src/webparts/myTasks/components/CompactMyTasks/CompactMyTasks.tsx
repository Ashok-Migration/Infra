import * as React from 'react';
import styles from '../MyTasks.module.scss';
import { DetailsList, IColumn, SelectionMode } from 'office-ui-fabric-react/lib/DetailsList';
import { Pivot, PivotItem } from 'office-ui-fabric-react/lib/Pivot';
import { Dialog, DialogType, DialogFooter } from 'office-ui-fabric-react/lib/Dialog';
import { PrimaryButton, DefaultButton } from 'office-ui-fabric-react/lib/Button';
import { ICompactMyTasksProps } from './ICompactMyTasksProps';
import { ICompactMyTasksState } from './ICompactMyTasksState';
import { IMyTask } from '../../../../models/IMyTasks';
import { initializeIcons, TextField } from 'office-ui-fabric-react';
import * as strings from 'MyTasksWebPartStrings';
import { Icon } from 'office-ui-fabric-react/lib/Icon';
initializeIcons();

export default class CompactMyTasks extends React.Component<ICompactMyTasksProps, ICompactMyTasksState> {
  constructor(props: ICompactMyTasksProps) {
    super(props);

    this.state = {
      myTasks: [],
      pagedTasks: [],
      selectedKey: '',
      selectedStatus: '',
      selectedItemId: null,
      taskComment: '',
      hideDialog: true,
      hideCommentDialog: true,
      selectedTaskComment: '',
      columns: this.columns
    };
  }

  private dialogContentProps = {
    type: DialogType.largeHeader,
    title: strings.ConfirmationHeaderLabel,
    subText: strings.ConfirmationTextLabel
  };

  public componentDidMount() {
    this.getMyTasks();
  }

  //#region Data access methods
  private getMyTasks = async () => {
    const myTasks = await this.props.sharePointService.getAllPendingRequests(this.props.list, this.props.approvalTaskContentType, this.props.translationTaskContentType);
    const pagedTasks: IMyTask[] = myTasks.slice(0, this.props.itemsPerPage);
    this.setState({ myTasks, pagedTasks });
  }

  private getMyPendingApprovals = async () => {
    const myTasks = await this.props.sharePointService.getAllPendingApprovals(this.props.list, this.props.approvalTaskContentType);
    const pagedTasks: IMyTask[] = myTasks.slice(0, this.props.itemsPerPage);
    this.setState({ myTasks, pagedTasks });
  }

  private getMyTranslationRequests = async () => {
    const myTasks = await this.props.sharePointService.getAllTranslationRequests(this.props.list, this.props.translationTaskContentType);
    const pagedTasks: IMyTask[] = myTasks.slice(0, this.props.itemsPerPage);
    this.setState({ myTasks, pagedTasks });
  }
  //#endregion

  //#region Details list methods
  private _onColumnClick = (ev: React.MouseEvent<HTMLElement>, column: IColumn): void => {
    const { columns, pagedTasks } = this.state;
    const newColumns: IColumn[] = columns.slice();
    const currColumn: IColumn = newColumns.filter(currCol => column.key === currCol.key)[0];
    newColumns.forEach((newCol: IColumn) => {
      if (newCol === currColumn) {
        currColumn.isSortedDescending = !currColumn.isSortedDescending;
        currColumn.isSorted = true;
      } else {
        newCol.isSorted = false;
        newCol.isSortedDescending = true;
      }
    });
    const newTasks = this.copyAndSort(pagedTasks, currColumn.fieldName!, currColumn.isSortedDescending);
    this.setState({
      columns: newColumns,
      pagedTasks: newTasks,
    });
  }

  private columns: IColumn[] = [
    {
      key: 'Title',
      name: strings.TaskTitleLabel,
      fieldName: 'Title',
      minWidth: 150,
      maxWidth: 350,
      isRowHeader: true,
      isResizable: true,
      isSorted: true,
      isSortedDescending: false,
      sortAscendingAriaLabel: 'Sorted A to Z',
      sortDescendingAriaLabel: 'Sorted Z to A',
      data: 'string',
      isPadded: true,
    },
    {
      key: 'Modified',
      name: strings.ModifiedLabel,
      fieldName: 'Modified',
      minWidth: 100,
      maxWidth: 350,
      isRowHeader: true,
      isResizable: true,
      isSorted: true,
      isSortedDescending: false,
      sortAscendingAriaLabel: 'Sorted A to Z',
      sortDescendingAriaLabel: 'Sorted Z to A',
      data: 'string',
      isPadded: true,
    },
    {
      key: 'Action',
      name: strings.ActionLabel,
      fieldName: 'Action',
      minWidth: 200,
      maxWidth: 550,
      isRowHeader: false,
      data: 'string',
      isPadded: true,
    }
  ];

  private copyAndSort<T>(items: T[], columnKey: string, isSortedDescending?: boolean): T[] {
    const key = columnKey as keyof T;
    return items.slice(0).sort((a: T, b: T) => ((isSortedDescending ? a[key] < b[key] : a[key] > b[key]) ? 1 : -1));
  }

  private renderItemColumn = (item: IMyTask, index: number, column: IColumn) => {
    const fieldContent = item[column.fieldName as keyof any] as string;

    switch (column.key) {
      case 'Title':
        return (
          <a href={item.ParentItemLink ? item.ParentItemLink.Url : '#'} data-interception='off' target='_blank' className={styles.taskTitleLink}>{fieldContent}</a>
        );

      case 'Modified':
        return (
          <span>{fieldContent.substring(0, fieldContent.indexOf('T'))}</span>
        );

      case 'Action':
        if (item.ContentTypeId === this.props.translationTaskContentType) {
          return (
            <div className={styles.action}>
              {item.Translation !== 'Start Translation' &&
                <div className={styles.pointer} onClick={(ev) => this.itemClicked(item.Id, 'Start Translation')}>
                  <span className='play'><Icon iconName='Play' /></span>
                  {strings.StartLabel}
                </div>
              }
              {item.Translation === 'Start Translation' &&
                <div className={styles.pointerDisabled}>
                  <span className='playDisabled'><Icon iconName='Play' /></span>
                  {strings.StartLabel}
                </div>
              }
              <div className={styles.actionItem + ' ' + styles.pointer} onClick={(ev) => this.itemClicked(item.Id, 'Finish Translation')}>
                <span className='stop'><Icon iconName='CircleStop' /></span>
                {strings.FinishLabel}
              </div>
            </div>
          );
        } else if (item.ContentTypeId === this.props.approvalTaskContentType) {
          return (
            <div className={styles.action}>
              <div className={styles.pointer} onClick={(ev) => this.itemClicked(item.Id, 'Rejected')}>
                <span className='reject'><Icon iconName='CalculatorMultiply' /></span>
                {strings.RejectLabel}
              </div>
              <div className={styles.actionItem + ' ' + styles.pointer} onClick={(ev) => this.itemClicked(item.Id, 'Approved')}>
                <span className='approve'><Icon iconName='Accept' /> </span>
                {strings.ApproveLabel}
              </div>
            </div>
          );
        }
        break;

      default:
        return <span>{fieldContent}</span>;
    }
  }
  //#endregion

  private itemClicked = (selectedItemId: number, selectedStatus: string) => {
    this.setState({
      selectedItemId,
      selectedStatus,
      hideDialog: false
    });
  }

  private dismissCommentDialog = () => {
    this.setState({
      hideCommentDialog: true,
      selectedTaskComment: ''
    });
  }

  private dismissDialog = () => {
    this.setState({
      selectedItemId: null,
      selectedStatus: '',
      taskComment: '',
      hideDialog: true
    });
  }

  private updateStatus = async () => {
    let updateResponse: string;
    if (['Approved', 'Rejected'].indexOf(this.state.selectedStatus) >= 0) {
      updateResponse = await this.props.sharePointService.updateApprovalStatus(this.props.list, this.state.selectedItemId, this.state.selectedStatus, this.state.taskComment, this.props.userName);
    } else {
      updateResponse = await this.props.sharePointService.updateTranslationStatus(this.props.list, this.state.selectedItemId, this.state.selectedStatus, this.state.taskComment, this.props.userName);
    }
    this.dismissDialog();
    this.getUpdatedData();
    if (updateResponse) {
      this.setState({ selectedTaskComment: updateResponse, hideCommentDialog: false });
    }
  }

  private handleLinkClick = (item: PivotItem) => {
    this.setState({ selectedKey: item.props.itemKey }, () => {
      this.getUpdatedData();
    });
  }

  private getUpdatedData = () => {
    switch (this.state.selectedKey) {
      case 'pendingApprovals':
        this.setState({ columns: this.columns });
        this.getMyPendingApprovals();
        break;
      case 'translationRequests':
        this.setState({ columns: this.columns });
        this.getMyTranslationRequests();
        break;
      default:
        this.setState({ columns: this.columns });
        this.getMyTasks();
        break;
    }
  }

  public render(): React.ReactElement<ICompactMyTasksProps> {
    return (
      <div className={styles.myTasks}>
        <div className={styles.container}>
          <span className={styles.title}>{this.props.webPartTitle}</span>
          {this.props.seeAllLink && this.props.seeAllLink.length > 0 &&
            <a href={this.props.seeAllLink} className={styles.seeAllLink} data-interception='off' target='_blank'>{strings.SeeAllLabel}</a>
          }
          <Pivot className='tabs'
            aria-label='Task Type'
            selectedKey={this.state.selectedKey}
            onLinkClick={this.handleLinkClick}
            headersOnly={true}
          >
            <PivotItem headerText={strings.AllRequestsPivotHeader} itemKey='allRequests' />
            <PivotItem headerText={strings.PendingApprovalsPivotHeader} itemKey='pendingApprovals' />
            <PivotItem headerText={strings.TranslationRequestsPivotHeader} itemKey='translationRequests' />
          </Pivot>
          {this.state.pagedTasks && this.state.pagedTasks.length > 0 &&
            <div>
              <DetailsList className='datalist'
                selectionMode={SelectionMode.none}
                items={this.state.pagedTasks}
                setKey='set'
                columns={this.state.columns}
                onColumnHeaderClick={this._onColumnClick}
                onRenderItemColumn={this.renderItemColumn}
                ariaLabelForSelectionColumn='Toggle selection'
                ariaLabelForSelectAllCheckbox='Toggle selection for all items'
                checkButtonAriaLabel='Row checkbox'
              />
              <Dialog minWidth='500px' className='modaldialog'
                hidden={this.state.hideDialog}
                dialogContentProps={this.dialogContentProps}
                onDismiss={this.dismissDialog}
              >
                <TextField className='description'
                  label={strings.CommentsLabel}
                  multiline={true}
                  value={this.state.taskComment}
                  onChange={(ev, val) => this.setState({ taskComment: val })}
                />
                <DialogFooter>
                  <PrimaryButton onClick={this.updateStatus} text={strings.ConfirmButtonLabel} />
                  <DefaultButton onClick={this.dismissDialog} text={strings.CancelButtonLabel} />
                </DialogFooter>
              </Dialog>
              <Dialog minWidth='500px' className='modaldialog'
                hidden={this.state.hideCommentDialog}
                onDismiss={this.dismissCommentDialog}
              >
                <div className={styles.myTasks}>
                  <div className={styles.description}>{this.state.selectedTaskComment}</div>
                </div>
              </Dialog>
            </div>
          }
          {this.state.pagedTasks.length === 0 &&
            <div className={styles.nodata}>{strings.NoDataFoundLabel}</div>
          }
        </div>
      </div>
    );
  }
}
