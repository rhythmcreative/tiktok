import { Win32MetadataOptions } from './types';
import { FileRecord } from '@electron/asar';
export type ExeMetadata = {
    productVersion?: string;
    fileVersion?: string;
    legalCopyright?: string;
    productName?: string;
    iconPath?: string;
    asarIntegrity?: Record<string, Pick<FileRecord['integrity'], 'algorithm' | 'hash'>>;
    win32Metadata?: Win32MetadataOptions;
};
export declare function resedit(exePath: string, options: ExeMetadata): Promise<void>;
