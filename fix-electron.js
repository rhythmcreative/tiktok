const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

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
      const result = spawnSync(electronBin, ['-v']);
      if (result.status === 0) {
        return true;
      }
    } catch (e) {
      // Ignore
    }
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
    console.log('Still broken. Manual extraction required.');
    // We could try to find the zip in cache, but for now we'll just advise
    console.log('Please run ./install.sh to fix dependencies.');
  } else {
    console.log('Electron fixed successfully.');
  }
} else {
  console.log('Electron binary is verified.');
}
