import * as React from 'react';
import styles from './NavigationContent.module.scss';
import { INavigationContentProps } from './INavigationContentProps';
import { SharePointService } from '../../../services/SharePointService/SharePointService';
import { ISPHubSiteCollection } from '../../../models/ISPHubSiteCollection';
import * as strings from 'NavigationContentWebPartStrings';

export interface INavigationContentState {
  hubSites: ISPHubSiteCollection[];
  filteredHubSites: ISPHubSiteCollection[];
  searchText: string;
}

export default class NavigationContent extends React.Component<INavigationContentProps, INavigationContentState> {

  private sharePointService = this.props.context.serviceScope.consume(SharePointService.serviceKey);

  constructor(props: INavigationContentProps) {
    super(props);
    this.search = this.search.bind(this);
    this.searchTextChanged = this.searchTextChanged.bind(this);
    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.state = ({ hubSites: [], filteredHubSites: [], searchText: '' });
  }

  public componentDidMount() {
    this.getHubSites();
  }

  public render(): React.ReactElement<INavigationContentProps> {

    return (
      <div className={styles.navigateContent}>
        <div className="container pb-5 pt-5">
          <div className="row">
            <div className="col-md-8">
              <input title="Search box" type="text" placeholder={strings.SearchBarTextLabel}
                className={`form-control ${styles["search-box"]}`} value={this.state.searchText}
                onChange={this.searchTextChanged} onKeyDown={this.handleKeyPress} />
              <button title="Search Button" className={styles["btn-search"]} onClick={this.search}></button></div>
          </div>
          <div className={`row mt-5 mb-5 ${styles["category-row"]}`}>
            <div className={styles["entity-name"]} title="Marketplace">
              {strings.TASMUCMSLabel}
            </div>
            <div className="col-md-4" style={{ paddingBottom: '20px' }}>
              <ul className={styles["category-items"]}>
                <li><a href={this.props.marketplaceUrl} title="Marketplace" data-interception='off' target='_blank'>{strings.TASMUCMSLabel}</a></li>
              </ul>
            </div>
          </div>
          <div className={`row ${styles["category-row"]}`}>
            <div className={styles["entity-name"]} title="Marketplace">
              {strings.SectorsEntitiesLabel}
            </div>
            {this.state.filteredHubSites.filter(item => !!item).map((item) => {
              return (
                <div className="col-md-4" style={{ paddingBottom: '20px' }}>
                  <ul className={styles["category-items"]}>
                    <div className={styles["category-name"]}>
                      {item.HasPermission ? <a href={item.SiteUrl} title={item.Title} data-interception='off' target='_blank'>{item.Title}</a> : item.Title}
                    </div>
                    {item.Sites && item.Sites.map((hubSite, i) => {
                      return (<li><a href={hubSite.Url} data-interception='off' target='_blank'>{hubSite.Title}</a></li>);
                    })}
                  </ul>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    );
  }

  private async getHubSites() {
    let response = await this.sharePointService.getHubSites(this.props.showEntities);
    response = response.filter(val => !!val);
    this.setState({ hubSites: response, filteredHubSites: response });
  }

  private searchTextChanged(e) {
    this.setState({ searchText: e.target.value });
    // setTimeout(() => {
    //   this.search();
    // }, 50);
  }

  private handleKeyPress(e) {
    if (e.keyCode === 13) {
      this.search();
    }
  }

  private async search() {
    if (this.state.searchText == "") {
      this.setState({ filteredHubSites: this.state.hubSites });
      return;
    }

    const filteredResponse = JSON.parse(JSON.stringify(this.state.hubSites));
    const hub = filteredResponse.filter(x => { return x.Title.toLocaleLowerCase().includes(this.state.searchText.toLocaleLowerCase()); });
    if (hub.length > 0) { this.setState({ filteredHubSites: hub }); return; }
    const hubSites = this.filterResults(filteredResponse, this.state.searchText);
    this.setState({ filteredHubSites: hubSites });
  }

  private filterResults(results: ISPHubSiteCollection[], text: string) {
    const rDetails = results.filter(det => !!det.Sites.find(l => l.Title.toLocaleLowerCase().includes(text.toLocaleLowerCase())));

    return rDetails.map(det => {
      det.Sites = det.Sites.filter(l => l.Title.toLocaleLowerCase().includes(text.toLocaleLowerCase()));
      return det;
    });
  }
}
