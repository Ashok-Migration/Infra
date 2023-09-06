import { IDropdownOption } from 'office-ui-fabric-react';
import { IColumn } from 'office-ui-fabric-react/lib/DetailsList';
import { IMyTask } from '../../../models/IMyTasks';

export interface IMyTasksState {
  myTasks: IMyTask[];
  selectedDropdown: IDropdownOption;
  pagedTasks: IMyTask[];
  selectedItemId: number;
  selectedStatus: string;
  taskComment: string;
  hideDialog: boolean;
  hideCommentDialog: boolean;
  selectedTaskComment: string;
  selectedKey: string;
  columns: IColumn[];
}
