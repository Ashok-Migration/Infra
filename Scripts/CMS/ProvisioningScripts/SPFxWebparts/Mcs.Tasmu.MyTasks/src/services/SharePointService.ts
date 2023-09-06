import { IMyTask } from '../models/IMyTasks';
import { ISharePointService } from './ISharePointService';
import { sp } from '@pnp/sp';
import '@pnp/sp/webs';
import '@pnp/sp/lists';
import '@pnp/sp/items';

export class SharePointService implements ISharePointService {
  private _userId: number;
  private selectables: string[] = [
    'Title',
    'Id',
    'Modified',
    'ContentTypeId',
    'ParentItemLink',
    'cmsAssignedToUserId',
    'arPreviewUrl',
    'PreviewUrl',
    'ListName',
    'TASMUTaskStatus',
    'Translation'
  ];
  private pendingTaskSelectables: string[] = [
    'Title',
    'Id',
    'Modified',
    'ParentItemLink',
    'cmsAssignedToUserId',
    'cmsactionby',
    'ListName',
    'TaskComments',
    'TASMUTaskStatus',
    'Translation'
  ];

  /**
   * Set _userId to the current logged in user's Id
   */
  public async setUserId() {
    try {
      const userDetails = await sp.web.currentUser.get();
      this._userId = userDetails.Id;
    } catch (error) {
      console.log(error);
    }
  }

  public async getAllPendingRequests(list: string, approvalTaskContentTypeId: string, translationTaskContentTypeId: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    try {
      myTasks = await sp.web.lists.getById(list).items
        .select(...this.selectables)
        .filter(`(((TASMUTaskStatus eq ${null}) or (TASMUTaskStatus eq 'Created')) and (Translation ne 'Finish Translation') and ((ContentTypeId eq '${approvalTaskContentTypeId}') or (ContentTypeId eq '${translationTaskContentTypeId}')) and (cmsAssignedToUserId eq ${this._userId}))`)
        .orderBy('Modified', false)
        .getAll();
      myTasks = myTasks.sort((a, b) => b.Modified.localeCompare(a.Modified));
    } catch (error) {
      console.log(error);
    }
    return myTasks;
  }

  public async getAllPendingApprovals(list: string, approvalTaskContentTypeId: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    try {
      myTasks = await sp.web.lists.getById(list).items
        .select(...this.selectables)
        .filter(`(((TASMUTaskStatus eq ${null}) or (TASMUTaskStatus eq 'Created')) and (ContentTypeId eq '${approvalTaskContentTypeId}') and (cmsAssignedToUserId eq ${this._userId}))`)
        .orderBy('Modified', false)
        .getAll();
      myTasks = myTasks.sort((a, b) => b.Modified.localeCompare(a.Modified));
    } catch (error) {
      console.log(error);
    }
    return myTasks;
  }

  public async getAllTranslationRequests(list: string, translationTaskContentTypeId: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    try {
      myTasks = await sp.web.lists.getById(list).items
        .select(...this.selectables)
        .filter(`(((TASMUTaskStatus eq ${null}) or (TASMUTaskStatus eq 'Created')) and (Translation ne 'Finish Translation') and (ContentTypeId eq '${translationTaskContentTypeId}') and (cmsAssignedToUserId eq ${this._userId}))`)
        .orderBy('Modified', false)
        .getAll();
      myTasks = myTasks.sort((a, b) => b.Modified.localeCompare(a.Modified));
    } catch (error) {
      console.log(error);
    }
    return myTasks;
  }

  public async getPreviousRequests(list: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    try {
      myTasks = await sp.web.lists.getById(list).items
        .select(...this.pendingTaskSelectables)
        .filter(`((Translation eq 'Finish Translation') or (TASMUTaskStatus eq 'Approved') or (TASMUTaskStatus eq 'Rejected') and (cmsAssignedToUserId eq ${this._userId}))`)
        .orderBy('Modified', false)
        .getAll();
      myTasks = myTasks.sort((a, b) => b.Modified.localeCompare(a.Modified));
    } catch (error) {
      console.log(error);
    }
    return myTasks;
  }

  public async updateTranslationStatus(list: string, itemId: number, status: string, taskComment: string, userName: string): Promise<string> {
    try {
      const task: IMyTask = await sp.web.lists.getById(list).items.select('Translation', 'Id').getById(itemId).get();
      if (task.Translation === status) {
        return 'The task has already been updated';
      }
      await sp.web.lists.getById(list).items.getById(itemId).update({
        Translation: status,
        TaskComments: taskComment,
        cmsactionby: userName
      });
      return '';
    } catch (error) {
      console.log(error);
      return 'Some error has occurred';
    }
  }

  public async updateApprovalStatus(list: string, itemId: number, status: string, taskComment: string, userName: string): Promise<string> {
    try {
      const task: IMyTask = await sp.web.lists.getById(list).items.select('TASMUTaskStatus', 'Id').getById(itemId).get();
      if (task.TASMUTaskStatus === 'Approved') {
        return 'The task has already been updated';
      }
      await sp.web.lists.getById(list).items.getById(itemId).update({
        TASMUTaskStatus: status,
        TaskComments: taskComment,
        cmsactionby: userName
      });
      return '';
    } catch (error) {
      console.log(error);
      return 'Some error has occurred';
    }
  }

  /**
   * Get Content Types available in the selected list
   * @param list List Id
   */
  public async getContentTypes(list: string) {
    let contentTypes = [];

    try {
      contentTypes = await sp.web.lists.getById(list).contentTypes.select('Name', 'StringId').get();
    } catch (error) {
      console.log(error);
    }

    return contentTypes;
  }
}
