const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const os = require('os');

const electronDir = path.join(__dirname, 'node_modules', 'electron');
const pathFile = path.join(electronDir, 'path.txt');
const distDir = path.join(electronDir, 'dist');
const electronBin = path.join(distDir, 'electron');

if (!fs.existsSync(electronDir)) {
  console.log('Electron directory not found, skipping fix.');
  process.exit(0);
}

function verifyElectron() {
  if (fs.existsSync(electronBin) && fs.existsSync(pathFile)) {
    try {
      // Check version too
      const versionFile = path.join(distDir, 'version');
      if (fs.existsSync(versionFile)) {
         return true;
      }
    } catch (e) {}
  }
  return false;
}

if (!verifyElectron()) {
  console.log('Electron binary missing or corrupted. Attempting fix...');
  
  // Try running the install script first
  const installScript = path.join(electronDir, 'install.js');
  if (fs.existsSync(installScript)) {
    console.log('Running electron/install.js...');
    spawnSync(process.execPath, [installScript], { stdio: 'inherit' });
  }

  // Check again
  if (!verifyElectron()) {
    console.log('install.js failed. Attempting manual extraction from cache...');
    
    try {
      const { version } = require(path.join(electronDir, 'package.json'));
      const cacheBase = path.join(os.homedir(), '.cache', 'electron');
      
      if (fs.existsSync(cacheBase)) {
        // Look for the zip file in subdirectories
        const findZip = (dir) => {
          const files = fs.readdirSync(dir);
          for (const file of files) {
            const fullPath = path.join(dir, file);
            if (fs.statSync(fullPath).isDirectory()) {
              const found = findZip(fullPath);
              if (found) return found;
            } else if (file.endsWith('.zip') && file.includes(version)) {
              return fullPath;
            }
          }
          return null;
        };
        
        const zipPath = findZip(cacheBase);
        if (zipPath) {
          console.log('Found zip in cache:', zipPath);
          if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
          
          console.log('Extracting...');
          const unzip = spawnSync('unzip', ['-o', zipPath, '-d', distDir]);
          
          if (unzip.status === 0) {
            fs.writeFileSync(pathFile, 'electron');
            fs.writeFileSync(path.join(distDir, 'version'), 'v' + version);
            
            if (process.platform !== 'win32') {
               fs.chmodSync(electronBin, 0o755);
            }
            console.log('Manual extraction successful.');
          } else {
            console.error('Unzip failed.');
          }
        } else {
          console.error('Could not find Electron zip in cache for version', version);
        }
      }
    } catch (err) {
      console.error('Manual fix failed:', err.message);
    }
  }

  if (!verifyElectron()) {
    console.log('Still broken. Please run ./install.sh to fix dependencies.');
  } else {
    console.log('Electron fixed successfully.');
  }
} else {
  // Even if verified, ensure path.txt is correct (no newlines)
  const currentPath = fs.readFileSync(pathFile, 'utf-8');
  if (currentPath !== 'electron') {
     fs.writeFileSync(pathFile, 'electron');
  }
}
