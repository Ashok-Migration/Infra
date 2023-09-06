declare interface ICopyCdnUrlCommandSetStrings {
  Command1: string;
  Command2: string;
  LinkCopiedLabel: string;
  UseCopiedLinkLabel: string;
}

declare module 'CopyCdnUrlCommandSetStrings' {
  const strings: ICopyCdnUrlCommandSetStrings;
  export = strings;
}
