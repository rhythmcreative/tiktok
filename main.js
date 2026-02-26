// Modules to control application life and create native browser window
const { app, BrowserWindow, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const https = require('https');

// Dynamically import electron-context-menu (default export)
import('electron-context-menu').then((contextMenuModule) => {
  const contextMenu = contextMenuModule.default;

  contextMenu({
    prepend: (defaultActions, parameters, browserWindow) => [
      //{
        //label: 'Save Image',
        // Only show it when right-clicking images
        //visible: parameters.mediaType === 'image'
      //},
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

// and load the index.html of the app.
let mainWindow;

// Set the app user model id as early as possible
app.setAppUserModelId('TikTok');

function createWindow () {
  // Create the browser window.
  const mainWindow = new BrowserWindow({
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
  setTimeout(function () {
    mainWindow.loadURL('https://www.tiktok.com/',{ userAgent: "Mozilla/5.0 (TikTok-Desktop) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'"});
  }, 3000) // Load store page after 3 secs
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
app.whenReady().then(createWindow)

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

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
