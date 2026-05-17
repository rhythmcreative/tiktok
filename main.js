// Modules to control application life and create native browser window
const { app, BrowserWindow, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const https = require('https');

// Single Instance Lock
const additionalData = { myKey: 'tiktok-desktop' };
const gotTheLock = app.requestSingleInstanceLock(additionalData);

// Global reference of the window object
let mainWindow;

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', (event, commandLine, workingDirectory, additionalData) => {
    // Someone tried to run a second instance, we should focus our window.
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  // Dynamically import electron-context-menu (default export)
  import('electron-context-menu').then((contextMenuModule) => {
    const contextMenu = contextMenuModule.default;

    contextMenu({
      prepend: (defaultActions, parameters, browserWindow) => [
        {
          label: 'Search Google for “{selection}”',
          // Only show it when right-clicking text
          visible: parameters.selectionText.trim().length > 0,
          click: () => {
            shell.openExternal(`https://google.com/search?q=${encodeURIComponent(parameters.selectionText)}`);
          }
        }
      ]
    });
  });
}

// Set the app user model id as early as possible
app.setAppUserModelId('TikTok');

function createWindow () {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1360,
    height: 765,
    title: 'TikTok',
    icon: path.join(__dirname, 'icon.png'),
    backgroundColor: '#2C2C2C',
    webPreferences: {
     contextIsolation: true,
     spellcheck: true,
     preload: path.join(app.getAppPath(), 'preload.js')
    }
  })

  // and load the index.html of the app.
  mainWindow.loadFile('splash.html')
  
  const loadTikTok = () => {
    mainWindow.loadURL('https://www.tiktok.com/', { 
      userAgent: "Mozilla/5.0 (TikTok-Desktop) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    }).catch(e => {
      console.error('Failed to load TikTok:', e);
      // Show a simple error message if loading fails
      mainWindow.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(`
        <body style="background:#121212;color:white;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;font-family:sans-serif;">
          <h2>Failed to load TikTok</h2>
          <p>Please check your internet connection and try again.</p>
          <button onclick="location.href='https://www.tiktok.com/'" style="padding:10px 20px;background:#ff0050;color:white;border:none;border-radius:5px;cursor:pointer;font-weight:bold;">Retry</button>
        </body>
      `));
    });
  };

  setTimeout(loadTikTok, 3000) // Load page after 3 secs
  mainWindow.maximize() // start maximized
  mainWindow.setMenuBarVisibility(false)
  mainWindow.setMenu(null)
  mainWindow.show();
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  // Open the DevTools.
  // mainWindow.webContents.openDevTools()
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
if (gotTheLock) {
  app.whenReady().then(createWindow)
}

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On macOS it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', function () {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) createWindow()
})
