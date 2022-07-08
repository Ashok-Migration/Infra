import * as React from 'react';
import styles from './MyTasks.module.scss';
import { DetailsList, IColumn, SelectionMode, DetailsRow, IDetailsRowStyles, IDetailsListProps } from 'office-ui-fabric-react/lib/DetailsList';
import { Pivot, PivotItem } from 'office-ui-fabric-react/lib/Pivot';
import { Dialog, DialogType, DialogFooter } from 'office-ui-fabric-react/lib/Dialog';
import { PrimaryButton, DefaultButton, IconButton } from 'office-ui-fabric-react/lib/Button';
import { IMyTasksProps } from './IMyTasksProps';
import { IMyTasksState } from './IMyTasksState';
import { IMyTask } from '../../../models/IMyTasks';
import { Dropdown, IDropdownOption, initializeIcons, TextField } from 'office-ui-fabric-react';
import * as strings from 'MyTasksWebPartStrings';
import { Icon } from 'office-ui-fabric-react/lib/Icon';
initializeIcons();
import { getTheme } from 'office-ui-fabric-react/lib/Styling';
const theme = getTheme();

export default class MyTasks extends React.Component<IMyTasksProps, IMyTasksState> {
  private options: IDropdownOption[];
  private hasFocusItem: boolean;
  private focusId: number;

  constructor(props: IMyTasksProps) {
    super(props);

    this.state = {
      myTasks: [],
      selectedDropdown: null,
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
    this.hasFocusItem = false;
  }

  private dialogContentProps = {
    type: DialogType.largeHeader,
    title: strings.ConfirmationHeaderLabel,
    subText: strings.ConfirmationTextLabel
  };

  public componentDidMount() {
    const urlParams = new URLSearchParams(window.location.search);
    this.focusId = parseInt(urlParams.get('TaskId'));
    this.getMyTasks();
  }

  //#region Data access methods
  private getMyTasks = async () => {
    const myTasks = await this.props.sharePointService.getAllPendingRequests(this.props.list, this.props.approvalTaskContentType, this.props.translationTaskContentType);
    if (this.focusId && myTasks.filter(val => val.Id === this.focusId).length > 0) {
      const tempTask = myTasks.filter(val => val.Id === this.focusId)[0];
      myTasks[myTasks.indexOf(tempTask)] = myTasks[0];
      myTasks[0] = tempTask;
      this.hasFocusItem = true;
    }
    const pagedTasks: IMyTask[] = myTasks.slice(0, this.props.itemsPerPage);
    this.setState({ myTasks, pagedTasks });
  }

  private getMyPendingApprovals = async () => {
    const myTasks = await this.props.sharePointService.getAllPendingApprovals(this.props.list, this.props.approvalTaskContentType);
    if (this.focusId && myTasks.filter(val => val.Id === this.focusId).length > 0) {
      const tempTask = myTasks.filter(val => val.Id === this.focusId)[0];
      myTasks[myTasks.indexOf(tempTask)] = myTasks[0];
      myTasks[0] = tempTask;
      this.hasFocusItem = true;
    }
    const pagedTasks: IMyTask[] = myTasks.slice(0, this.props.itemsPerPage);
    this.setState({ myTasks, pagedTasks });
  }

  private getMyTranslationRequests = async () => {
    const myTasks = await this.props.sharePointService.getAllTranslationRequests(this.props.list, this.props.translationTaskContentType);
    if (this.focusId && myTasks.filter(val => val.Id === this.focusId).length > 0) {
      const tempTask = myTasks.filter(val => val.Id === this.focusId)[0];
      myTasks[myTasks.indexOf(tempTask)] = myTasks[0];
      myTasks[0] = tempTask;
      this.hasFocusItem = true;
    }
    const pagedTasks: IMyTask[] = myTasks.slice(0, this.props.itemsPerPage);
    this.setState({ myTasks, pagedTasks });
  }

  private getPreviousRequests = async () => {
    const myTasks: IMyTask[] = await this.props.sharePointService.getPreviousRequests(this.props.list);
    if (this.focusId && myTasks.filter(val => val.Id === this.focusId).length > 0) {
      const tempTask = myTasks.filter(val => val.Id === this.focusId)[0];
      myTasks[myTasks.indexOf(tempTask)] = myTasks[0];
      myTasks[0] = tempTask;
      this.hasFocusItem = true;
    }
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
      key: 'PreviewUrl',
      name: strings.PreviewUrlLabel,
      fieldName: 'PreviewUrl',
      minWidth: 150,
      maxWidth: 350,
      isRowHeader: true,
      isResizable: true,
      isSorted: true,
      isSortedDescending: false,
      sortAscendingAriaLabel: 'Sorted A to Z',
      sortDescendingAriaLabel: 'Sorted Z to A',
      isPadded: true,
    },
    {
      key: 'arPreviewUrl',
      name: strings.PreviewUrlArLabel,
      fieldName: 'arPreviewUrl',
      minWidth: 150,
      maxWidth: 350,
      isRowHeader: true,
      isResizable: true,
      isSorted: true,
      isSortedDescending: false,
      sortAscendingAriaLabel: 'Sorted A to Z',
      sortDescendingAriaLabel: 'Sorted Z to A',
      isPadded: true,
    },
    {
      key: 'ListName',
      name: strings.ListNameLabel,
      fieldName: 'ListName',
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
      minWidth: 150,
      maxWidth: 550,
      isRowHeader: false,
      data: 'string',
      isPadded: true,
    }
  ];

  private historyColumns: IColumn[] = [
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
      key: 'TaskComments',
      name: strings.TaskCommentsLabel,
      fieldName: 'TaskComments',
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
      key: 'ListName',
      name: strings.ListNameLabel,
      fieldName: 'ListName',
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
      key: 'Modified',
      name: strings.ModifiedLabel,
      fieldName: 'Modified',
      minWidth: 100,
      maxWidth: 350,
      isRowHeader: true,
      isResizable: true,
      isSorted: true,
      isSortedDescending: true,
      sortAscendingAriaLabel: 'Sorted A to Z',
      sortDescendingAriaLabel: 'Sorted Z to A',
      data: 'string',
      isPadded: true,
    },
    {
      key: 'Action By',
      name: strings.ActionByLabel,
      fieldName: 'cmsactionby',
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
    }
  ];

  private copyAndSort<T>(items: T[], columnKey: string, isSortedDescending?: boolean): T[] {
    const key = columnKey as keyof T;
    return items.slice(0).sort((a: T, b: T) => ((isSortedDescending ? a[key] < b[key] : a[key] > b[key]) ? 1 : -1));
  }

  private renderItemColumn = (item: IMyTask, index: number, column: IColumn) => {
    const fieldContent = item[column.fieldName as keyof any];

    switch (column.key) {
      case 'Title':
        return (
          <a href={item.ParentItemLink ? item.ParentItemLink.Url : '#'} data-interception='off' target='_blank' className={styles.taskTitleLink}>{fieldContent}</a>
        );

      case 'arPreviewUrl':
      case 'PreviewUrl':
        if (fieldContent) {
          return (
            <a href={fieldContent.Url} data-interception='off' target='_blank' className={styles.taskTitleLink}>{fieldContent.Url}</a>
          );
        }
        break;

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
                <span className='approve'><Icon iconName='Accept' /></span>
                {strings.ApproveLabel}
              </div>
            </div>
          );
        }
        break;

      case 'TaskComments':
        return (
          <div>
            {fieldContent && fieldContent.length >= 20 ?
              <a href='#' className={styles.taskTitleLink} onClick={() => this.setState({ hideCommentDialog: false, selectedTaskComment: item.TaskComments })} >
                {fieldContent.substr(0, 20)}...
              </a>
              :
              fieldContent
            }
          </div>
        );

      default:
        return <span>{fieldContent}</span>;
    }
  }

  private _onRenderRow: IDetailsListProps['onRenderRow'] = props => {
    const customStyles: Partial<IDetailsRowStyles> = {};
    if (props) {
      if (props.itemIndex === 0 && this.hasFocusItem) {
        customStyles.root = { backgroundColor: theme.palette.themeLighterAlt };
      }

      return <DetailsRow {...props} styles={customStyles} />;
    }
    return null;
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
    this.setState({ selectedKey: item.props.itemKey, selectedDropdown: this.options.length ? this.options[0] : null }, () => {
      this.getUpdatedData();
    });
  }

  private getUpdatedData = () => {
    this.hasFocusItem = false;
    switch (this.state.selectedKey) {
      case 'pendingApprovals':
        this.setState({ columns: this.columns });
        this.getMyPendingApprovals();
        break;
      case 'translationRequests':
        this.setState({ columns: this.columns });
        this.getMyTranslationRequests();
        break;
      case 'history':
        this.setState({ columns: this.historyColumns });
        this.getPreviousRequests();
        break;
      default:
        this.setState({ columns: this.columns });
        this.getMyTasks();
        break;
    }
  }

  private dropdownOnChange = (event: React.FormEvent<HTMLDivElement>, item: IDropdownOption) => {
    this.setState({ selectedDropdown: item }, () => {
      this._pagedButtonClick();
    });
  }

  //#region Pagination methods
  private _pagedButtonClick = () => {
    const pageNumber: number = parseInt(this.state.selectedDropdown.key.toString());
    const startIndex: number = (pageNumber - 1) * this.props.itemsPerPage;
    const endIndex: number = startIndex + this.props.itemsPerPage;
    const pagedTasks: IMyTask[] = this.state.myTasks.slice(startIndex, endIndex);
    this.setState({ pagedTasks });
  }

  private prevPageClick = () => {
    const currentPage = parseInt(this.state.selectedDropdown.key.toString());
    if (currentPage !== 1) {
      this.setState({ selectedDropdown: this.options.filter(val => val.key === (currentPage - 1).toString())[0] }, () => {
        this._pagedButtonClick();
      });
    }
  }

  private nextPageClick = () => {
    const currentPage = this.state.selectedDropdown ? parseInt(this.state.selectedDropdown.key.toString()) : 1;
    if (currentPage !== this.options.length) {
      this.setState({ selectedDropdown: this.options.filter(val => val.key === (currentPage + 1).toString())[0] }, () => {
        this._pagedButtonClick();
      });
    }
  }

  private firstPageClick = () => {
    this.setState({ selectedDropdown: this.options[0] }, () => {
      this._pagedButtonClick();
    });
  }

  private lastPageClick = () => {
    this.setState({ selectedDropdown: this.options[this.options.length - 1] }, () => {
      this._pagedButtonClick();
    });
  }
  //#endregion

  public render(): React.ReactElement<IMyTasksProps> {
    const pageCount = Math.ceil(this.state.myTasks.length / this.props.itemsPerPage);
    this.options = [];

    for (let i = 0; i < pageCount; i++) {
      this.options.push({
        key: (i + 1).toLocaleString(),
        text: (i + 1).toLocaleString()
      });
    }

    return (
      <div className={styles.myTasks}>
        <div className={styles.container}>
          <span className={styles.title}>{this.props.webPartTitle}</span>
          <Pivot className='tabs'
            aria-label='Task Type'
            selectedKey={this.state.selectedKey}
            onLinkClick={this.handleLinkClick}
            headersOnly={true}
          >
            <PivotItem headerText={strings.AllRequestsPivotHeader} itemKey='allRequests' />
            <PivotItem headerText={strings.PendingApprovalsPivotHeader} itemKey='pendingApprovals' />
            <PivotItem headerText={strings.TranslationRequestsPivotHeader} itemKey='translationRequests' />
            <PivotItem headerText={strings.HistoryPivotHeader} itemKey='history' />
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
                onRenderRow={this._onRenderRow}
                ariaLabelForSelectionColumn='Toggle selection'
                ariaLabelForSelectAllCheckbox='Toggle selection for all items'
                checkButtonAriaLabel='Row checkbox'
              />
              {this.options.length > 1 &&
                <div className={styles.pagination}>
                  <IconButton title={strings.FirstPageLabel} iconProps={{ iconName: 'DoubleChevronLeft' }} onClick={this.firstPageClick} />
                  <IconButton title={strings.PreviousPageLabel} iconProps={{ iconName: 'ChevronLeft' }} onClick={this.prevPageClick} />
                  <Dropdown options={this.options}
                    selectedKey={this.state.selectedDropdown ? this.state.selectedDropdown.key : undefined}
                    onChange={this.dropdownOnChange}
                    placeholder='1'
                  />
                  <p> of <span>{this.options.length}</span></p>
                  <IconButton title={strings.NextPageLabel} iconProps={{ iconName: 'ChevronRight' }} onClick={this.nextPageClick} />
                  <IconButton title={strings.LastPageLabel} iconProps={{ iconName: 'DoubleChevronRight' }} onClick={this.lastPageClick} />
                </div>
              }
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
