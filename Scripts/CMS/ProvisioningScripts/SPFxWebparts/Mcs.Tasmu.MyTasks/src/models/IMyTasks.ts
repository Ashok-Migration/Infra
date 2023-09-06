export interface IMyTask {
  Title: string;
  Id: number;
  Modified: string;
  ContentTypeId: string;
  ParentSiteUrl?: string;
  ParentItemLink: any;
  cmsAssignedToUserId: number[];
  cmsactionby: string;
  ListName: string;
  arPreviewUrl?: string;
  PreviewUrl?: string;
  TaskComments?: string;
  TASMUTaskStatus: string;
  Translation: string;
}
