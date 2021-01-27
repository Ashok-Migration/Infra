import { WebPartContext } from "@microsoft/sp-webpart-base";

export interface INavigationContentProps {
  marketplaceUrl: string;
  context: WebPartContext;
  showEntities: boolean;
}
