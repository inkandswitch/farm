process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

console.log("App starting...")

import {
  app,
  shell,
  Menu,
  BrowserWindow,
  MenuItemConstructorOptions,
} from "electron"
import contextMenu from "electron-context-menu"
import path from "path"

app.on("ready", createWindow)

app.setAsDefaultProtocolClient("farm")

// If we are running a non-packaged version of the app
if (process.defaultApp) {
  // If we have the path to our app we set the protocol client to launch electron.exe with the path to our app
  if (process.argv.length >= 2) {
    app.setAsDefaultProtocolClient("farm", process.execPath, [
      path.resolve(process.argv[1]),
    ])
  }
} else {
  app.setAsDefaultProtocolClient("farm")
}

app.on("open-url", (_event, url) => {
  getWindow().webContents.send("open-url", url)
})

contextMenu({})

function createWindow(): BrowserWindow {
  // BrowserWindow.addDevToolsExtension(path.resolve("./dist/hypermerge-devtools"))

  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      sandbox: false,
      nodeIntegration: true,
      nodeIntegrationInWorker: true,
      nativeWindowOpen: true,
      webSecurity: false,
      experimentalFeatures: true,
    },
  })

  win.loadFile("./dist/index.html") // production

  win.webContents.on("will-navigate", (e, url) => {
    console.log("Opening externally...", url)
    e.preventDefault()
    shell.openExternal(url)
  })

  const template: MenuItemConstructorOptions[] = [
    {
      label: "Edit",
      submenu: [
        { role: "undo" },
        { role: "redo" },
        { type: "separator" },
        { role: "cut" },
        { role: "copy" },
        { role: "paste" },
        { role: "pasteandmatchstyle" },
        { role: "delete" },
        { role: "selectall" },
      ],
    },
    {
      label: "View",
      submenu: [
        { role: "reload" },
        { role: "forcereload" },
        { role: "toggledevtools" },
        { type: "separator" },
        { role: "resetzoom" },
        { role: "zoomin" },
        { role: "zoomout" },
        { type: "separator" },
        { role: "togglefullscreen" },
      ],
    },
    {
      role: "window",
      submenu: [{ role: "minimize" }, { role: "close" }],
    },
    {
      role: "help",
      submenu: [
        {
          label: "Farm on Github",
          click() {
            shell.openExternal("https://github.com/inkandswitch/farm")
          },
        },
      ],
    },
  ]

  if (process.platform === "darwin") {
    template.unshift({
      label: app.getName(),
      submenu: [
        { role: "about" },
        { type: "separator" },
        { role: "services", submenu: [] },
        { type: "separator" },
        { role: "hide" },
        { role: "hideothers" },
        { role: "unhide" },
        { type: "separator" },
        { role: "quit" },
      ],
    })
  }

  Menu.setApplicationMenu(Menu.buildFromTemplate(template))

  return win
}

function getWindow(): BrowserWindow {
  return (
    BrowserWindow.getFocusedWindow() ||
    BrowserWindow.getAllWindows()[0] ||
    createWindow()
  )
}
