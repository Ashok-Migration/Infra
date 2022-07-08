/// <reference types='jest' />

import { MockSharePointService } from '../../../services/MockSharePointService';
import { ISharePointService } from '../../../services/ISharePointService';

describe('Testing MockSharePointService', () => {
  let sharePointServiceInstance: ISharePointService;

  beforeAll(() => {
    sharePointServiceInstance = new MockSharePointService();
  });

  test('getAllPendingRequests returns pending translation and approval requests', () => {
    sharePointServiceInstance.getAllPendingRequests('MyTasksListId', 'approvalTaskContentTypeId', 'translationTaskContentTypeId').then((response) => {
      expect(response.length).toEqual(3);
    });
  });

  test('getAllPendingApprovals returns pending approval requests', () => {
    sharePointServiceInstance.getAllPendingApprovals('MyTasksListId', 'approvalTaskContentTypeId').then((response) => {
      expect(response.length).toEqual(1);
    });
  });

  test('getAllTranslationRequests returns pending translation requests', () => {
    sharePointServiceInstance.getAllTranslationRequests('MyTasksListId', 'translationTaskContentTypeId').then((response) => {
      expect(response.length).toEqual(2);
    });
  });

  test('getPreviousRequests gets previously completed requests', () => {
    sharePointServiceInstance.getPreviousRequests('MyTasksListId').then((response) => {
      expect(response.length).toEqual(2);
    });
  });

  test('updateTranslationStatus updates Translation successfully', () => {
    sharePointServiceInstance.updateTranslationStatus('MyTasksListId', 1, 'Finish Translation', 'Task Comments', 'Megan Bowen').then((response) => {
      expect(response).toEqual('');
    });
  });

  test('updateTranslationStatus does not update when Translation  is same', () => {
    sharePointServiceInstance.updateTranslationStatus('MyTasksListId', 1, 'Start Translation', 'Task Comments', 'Megan Bowen').then((response) => {
      expect(response).toEqual('The task has already been updated');
    });
  });

  test('updateApprovalStatus updates TASMUTaskStatus successfully', () => {
    sharePointServiceInstance.updateApprovalStatus('MyTasksListId', 1, 'Approved', 'Task Comments', 'Megan Bowen').then((response) => {
      expect(response).toEqual('');
    });
  });

  test('updateApprovalStatus does not update when TASMUTaskStatus is same', () => {
    sharePointServiceInstance.updateApprovalStatus('', 2, 'Approved', 'Task Comments', 'Megan Bowen').then((response) => {
      expect(response).toEqual('The task has already been updated');
    });
  });
});
