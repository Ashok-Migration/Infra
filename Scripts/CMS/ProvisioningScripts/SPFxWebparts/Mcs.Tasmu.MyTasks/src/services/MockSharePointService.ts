import { IMyTask } from '../models/IMyTasks';
import { ISharePointService } from './ISharePointService';

export class MockSharePointService implements ISharePointService {
  public async getAllPendingRequests(list: string, approvalTaskContentTypeId: string, translationTaskContentTypeId: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    myTasks = [
      {
        Title: 'Task Item 1',
        Id: 1,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: null,
        TASMUTaskStatus: '',
        Translation: null
      },
      {
        Title: 'Task Item 2',
        Id: 2,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      },
      {
        Title: 'Task Item 3',
        Id: 3,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '5678',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: null
      }
    ];
    return myTasks;
  }

  public async getAllPendingApprovals(list: string, approvalTaskContentTypeId: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    myTasks = [
      {
        Title: 'Task Item 3',
        Id: 3,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '5678',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: null
      }
    ];

    return myTasks;
  }

  public async getAllTranslationRequests(list: string, translationTaskContentTypeId: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    myTasks = [
      {
        Title: 'Task Item 1',
        Id: 1,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: null,
        TASMUTaskStatus: '',
        Translation: null
      },
      {
        Title: 'Task Item 2',
        Id: 2,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      }
    ];

    return myTasks;
  }

  public async getPreviousRequests(list: string): Promise<IMyTask[]> {
    let myTasks: IMyTask[] = [];

    myTasks = [
      {
        Title: 'Task Item 4',
        Id: 4,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Finish Translation'
      },
      {
        Title: 'Task Item 5',
        Id: 5,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '5678',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: null
      }
    ];

    return myTasks;
  }

  public async updateTranslationStatus(list: string, itemId: number, status: string, taskComment: string, userName: string): Promise<string> {
    let myTasks: IMyTask[] = [
      {
        Title: 'Task Item 1',
        Id: 1,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      },
      {
        Title: 'Task Item 2',
        Id: 2,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      },
      {
        Title: 'Task Item 3',
        Id: 3,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      }
    ];
    let task: IMyTask = myTasks.filter(v => v.Id === itemId)[0];
    if (task.Translation === status) {
      return 'The task has already been updated';
    }
    return '';
  }

  public async updateApprovalStatus(list: string, itemId: number, status: string, taskComment: string, userName: string): Promise<string> {
    let myTasks: IMyTask[] = [
      {
        Title: 'Task Item 1',
        Id: 1,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      },
      {
        Title: 'Task Item 2',
        Id: 2,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: 'Approved',
        Translation: null
      },
      {
        Title: 'Task Item 3',
        Id: 3,
        Modified: '2020-23-12T04:00:00Z',
        ContentTypeId: '1234',
        ParentSiteUrl: 'https://contoso.sharepoint.com/sites/siteA',
        ParentItemLink: 'https://contoso.sharepoint.com/sites/siteA',
        cmsactionby: 'Megan Bowen',
        cmsAssignedToUserId: [1],
        arPreviewUrl: 'abcd',
        ListName: 'Announcements',
        PreviewUrl: 'abcd',
        TaskComments: 'Testing',
        TASMUTaskStatus: '',
        Translation: 'Start Translation'
      }
    ];
    let task: IMyTask = myTasks.filter(v => v.Id === itemId)[0];
    if (task.TASMUTaskStatus === 'Approved') {
      return 'The task has already been updated';
    }
    return '';
  }
}
