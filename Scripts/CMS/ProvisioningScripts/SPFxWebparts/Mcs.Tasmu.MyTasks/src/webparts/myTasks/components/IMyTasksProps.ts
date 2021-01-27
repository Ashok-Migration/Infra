import { ISharePointService } from '../../../services/ISharePointService';

export interface IMyTasksProps {
  webPartTitle: string;
  list: string;
  approvalTaskContentType: string;
  translationTaskContentType: string;
  sharePointService: ISharePointService;
  itemsPerPage: number;
  userName: string;
}
