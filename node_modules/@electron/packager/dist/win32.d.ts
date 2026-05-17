import { App } from './platform';
import { ExeMetadata } from './resedit';
export declare class WindowsApp extends App {
    get originalElectronName(): string;
    get newElectronName(): string;
    get electronBinaryPath(): string;
    generateReseditOptionsSansIcon(): ExeMetadata;
    getIconPath(): Promise<string | void>;
    needsResedit(): boolean;
    runResedit(): Promise<void>;
    signAppIfSpecified(): Promise<void>;
    create(): Promise<string>;
}
export { WindowsApp as App };
