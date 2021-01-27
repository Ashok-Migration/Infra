import { IMyTask } from '../models/IMyTasks';

export interface ISharePointService {
  /**
   * Get all pending approval and translation requests for the current user
   * @param list List Id
   * @param approvalTaskContentTypeId Content Type ID for Approval Tasks
   * @param translationTaskContentTypeId Content Type ID for Translation Tasks
   */
  getAllPendingRequests(list: string, approvalTaskContentTypeId: string, translationTaskContentTypeId: string): Promise<IMyTask[]>;

  /**
   * Get pending approval requests for the current user
   * @param list List Id
   * @param approvalTaskContentTypeId Content Type ID for Approval Tasks
   */
  getAllPendingApprovals(list: string, approvalTaskContentTypeId: string): Promise<IMyTask[]>;

  /**
   * Get pending translation requests for the current user
   * @param list List Id
   * @param translationTaskContentTypeId Content Type ID for Translation Tasks
   */
  getAllTranslationRequests(list: string, translationTaskContentTypeId: string): Promise<IMyTask[]>;

  /**
   * Get previously active requests for the current user
   * @param list List Id
   */
  getPreviousRequests(list: string): Promise<IMyTask[]>;

  /**
   * Update translation task status along with Task Comments and Action By
   * @param list List Id
   * @param itemId Item Id
   * @param status Translation status to be updated
   * @param taskComment Task Comments
   * @param userName Current user's name
   */
  updateTranslationStatus(list: string, itemId: number, status: string, taskComment: string, userName: string): Promise<string>;

  /**
   * Update approval task status along with Task Comments and Action By
   * @param list List Id
   * @param itemId Item Id
   * @param status TASMUTaskStatus status to be updated
   * @param taskComment Task Comments
   * @param userName Current user's name
   */
  updateApprovalStatus(list: string, itemId: number, status: string, taskComment: string, userName: string): Promise<string>;
}
