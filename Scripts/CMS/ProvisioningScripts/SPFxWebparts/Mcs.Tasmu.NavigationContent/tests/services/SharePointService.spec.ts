import * as Adapter from 'enzyme-adapter-react-16';
import 'mocha';
import { expect } from 'chai';
import { configure } from 'enzyme';

import { ISharePointService } from '../../src/services/SharePointService/ISharePointService'
import { MockSharePointService } from './MockSharePointService';

configure({ adapter: new Adapter() });

describe('sharePointService', () => {
    let sharePointService: ISharePointService;

    it('getHubSites', () => {
        sharePointService = new MockSharePointService();
        sharePointService.getHubSites(true).then((response) => { expect(response.length).equal(2); })
    });

    it('getSitesInHubSite', () => {
        sharePointService = new MockSharePointService();
        sharePointService.getSitesInHubSite().then((response) => { expect(response.length).equal(1); })
    });

});
