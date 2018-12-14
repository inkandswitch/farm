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

app.on("ready", createWindow)

app.setAsDefaultProtocolClient("realm")

app.on("open-url", (_event, url) => {
  getWindow().webContents.send("open-url", url)
})

contextMenu({})

function createWindow(): BrowserWindow {
  const win = new BrowserWindow({
    width: 325,
    height: 400,
    webPreferences: {
      sandbox: false,
      nodeIntegration: true,
      nodeIntegrationInWorker: true,
      nativeWindowOpen: true,
    },
  })

  const url = "http://localhost:4000"

  console.log(`Opening '${url}'...`)
  win.loadURL(url)
  // win.loadFile("./dist/index.html") // production

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
          label: "Realm on Github",
          click() {
            shell.openExternal("https://github.com/inkandswitch/realm")
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
