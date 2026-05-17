"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.App = exports.WindowsApp = void 0;
const path_1 = __importDefault(require("path"));
const windows_sign_1 = require("@electron/windows-sign");
const platform_1 = require("./platform");
const common_1 = require("./common");
const resedit_1 = require("./resedit");
class WindowsApp extends platform_1.App {
    get originalElectronName() {
        return 'electron.exe';
    }
    get newElectronName() {
        return `${(0, common_1.sanitizeAppName)(this.executableName)}.exe`;
    }
    get electronBinaryPath() {
        return path_1.default.join(this.stagingPath, this.newElectronName);
    }
    generateReseditOptionsSansIcon() {
        const win32Metadata = {
            FileDescription: this.opts.name,
            InternalName: this.opts.name,
            OriginalFilename: this.newElectronName,
            ProductName: this.opts.name,
            ...this.opts.win32metadata,
        };
        return {
            productVersion: this.opts.appVersion,
            fileVersion: this.opts.buildVersion || this.opts.appVersion,
            legalCopyright: this.opts.appCopyright,
            productName: this.opts.win32metadata?.ProductName || this.opts.name,
            asarIntegrity: this.asarIntegrity,
            win32Metadata,
        };
    }
    async getIconPath() {
        if (!this.opts.icon) {
            return Promise.resolve();
        }
        if (Array.isArray(this.opts.icon)) {
            throw new Error('opts.path must be a single path on Windows');
        }
        return this.normalizeIconExtension('.ico');
    }
    needsResedit() {
        return Boolean(this.opts.icon ||
            this.opts.win32metadata ||
            this.opts.appCopyright ||
            this.opts.appVersion ||
            this.opts.buildVersion ||
            this.opts.name);
    }
    async runResedit() {
        /* istanbul ignore if */
        if (!this.needsResedit()) {
            return Promise.resolve();
        }
        const resOpts = this.generateReseditOptionsSansIcon();
        // Icon might be omitted or only exist in one OS's format, so skip it if normalizeExt reports an error
        const icon = await this.getIconPath();
        if (icon) {
            resOpts.iconPath = icon;
        }
        (0, common_1.debug)(`Running resedit with the options ${JSON.stringify(resOpts)}`);
        await (0, resedit_1.resedit)(this.electronBinaryPath, resOpts);
    }
    async signAppIfSpecified() {
        const windowsSignOpt = this.opts.windowsSign;
        const windowsMetaData = this.opts.win32metadata;
        if (windowsSignOpt) {
            const signOpts = createSignOpts(windowsSignOpt, windowsMetaData, this.stagingPath);
            (0, common_1.debug)(`Running @electron/windows-sign with the options ${JSON.stringify(signOpts)}`);
            try {
                await (0, windows_sign_1.sign)(signOpts);
            }
            catch (err) {
                // Although not signed successfully, the application is packed.
                if (signOpts.continueOnError) {
                    (0, common_1.warning)(`Code sign failed; please retry manually. ${err}`, this.opts.quiet);
                }
                else {
                    throw err;
                }
            }
        }
    }
    async create() {
        await this.initialize();
        await this.renameElectron();
        await this.copyExtraResources();
        await this.runResedit();
        await this.signAppIfSpecified();
        return this.move();
    }
}
exports.WindowsApp = WindowsApp;
exports.App = WindowsApp;
function createSignOpts(properties, windowsMetaData, appDirectory) {
    let result = {};
    if (typeof properties === 'object') {
        result = { ...properties };
    }
    // A little bit of convenience
    if (windowsMetaData &&
        windowsMetaData.FileDescription &&
        !result.description) {
        result.description = windowsMetaData.FileDescription;
    }
    return { ...result, appDirectory };
}
//# sourceMappingURL=win32.js.map