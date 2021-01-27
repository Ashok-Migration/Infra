declare interface ICopyClassicLinkCommandSetStrings {
  Command1: string;
  Command2: string;
  LinkCopiedLabel: string;
  UseCopiedLinkLabel: string;
}

declare module 'CopyClassicLinkCommandSetStrings' {
  const strings: ICopyClassicLinkCommandSetStrings;
  export = strings;
}
