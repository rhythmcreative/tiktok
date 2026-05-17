"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateAssetCatalogForIcon = void 0;
const cross_spawn_promise_1 = require("@malept/cross-spawn-promise");
const promises_1 = __importDefault(require("node:fs/promises"));
const node_os_1 = __importDefault(require("node:os"));
const node_path_1 = __importDefault(require("node:path"));
const plist_1 = __importDefault(require("plist"));
const semver_1 = __importDefault(require("semver"));
async function generateAssetCatalogForIcon(inputPath) {
    if (!semver_1.default.gte(node_os_1.default.release(), '25.0.0')) {
        throw new Error(`actool .icon support is currently limited to macOS 26 and higher`);
    }
    const acToolVersionOutput = await (0, cross_spawn_promise_1.spawn)('actool', ['--version']);
    const versionInfo = plist_1.default.parse(acToolVersionOutput);
    if (!versionInfo ||
        !versionInfo['com.apple.actool.version'] ||
        !versionInfo['com.apple.actool.version']['short-bundle-version']) {
        throw new Error('Unable to query actool version. Is Xcode 26 or higher installed? See output of the `actool --version` CLI command for more details.');
    }
    const acToolVersion = versionInfo['com.apple.actool.version']['short-bundle-version'];
    if (!semver_1.default.gte(semver_1.default.coerce(acToolVersion), '26.0.0')) {
        throw new Error(`Unsupported actool version. Must be on actool 26.0.0 or higher but found ${acToolVersion}. Install XCode 26 or higher to get a supported version of actool.`);
    }
    const tmpDir = await promises_1.default.mkdtemp(node_path_1.default.resolve(node_os_1.default.tmpdir(), 'icon-compile-'));
    const iconPath = node_path_1.default.resolve(tmpDir, 'Icon.icon');
    const outputPath = node_path_1.default.resolve(tmpDir, 'out');
    try {
        await promises_1.default.cp(inputPath, iconPath, {
            recursive: true,
        });
        await promises_1.default.mkdir(outputPath, {
            recursive: true,
        });
        await (0, cross_spawn_promise_1.spawn)('actool', [
            iconPath,
            '--compile',
            outputPath,
            '--output-format',
            'human-readable-text',
            '--notices',
            '--warnings',
            '--output-partial-info-plist',
            node_path_1.default.resolve(outputPath, 'assetcatalog_generated_info.plist'),
            '--app-icon',
            'Icon',
            '--include-all-app-icons',
            '--accent-color',
            'AccentColor',
            '--enable-on-demand-resources',
            'NO',
            '--development-region',
            'en',
            '--target-device',
            'mac',
            '--minimum-deployment-target',
            '26.0',
            '--platform',
            'macosx',
        ]);
        return await promises_1.default.readFile(node_path_1.default.resolve(outputPath, 'Assets.car'));
    }
    finally {
        await promises_1.default.rm(tmpDir, {
            recursive: true,
            force: true,
        });
    }
}
exports.generateAssetCatalogForIcon = generateAssetCatalogForIcon;
//# sourceMappingURL=icon-composer.js.map