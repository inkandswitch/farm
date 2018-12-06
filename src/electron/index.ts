process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

console.log("App starting...")

import { app, shell, BrowserWindow } from "electron"

app.on("ready", createWindow)

app.setAsDefaultProtocolClient("realm")

app.on("open-url", (_event, url) => {
  getWindow().webContents.send("open-url", url)
})

function createWindow(): BrowserWindow {
  const win = new BrowserWindow({
    width: 1200,
    height: 720,
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
  win.webContents.openDevTools()
  // win.loadFile("./dist/index.html") // production

  win.webContents.on("will-navigate", (e, url) => {
    console.log("Opening externally...", url)
    e.preventDefault()
    shell.openExternal(url)
  })

  return win
}

function getWindow(): BrowserWindow {
  return (
    BrowserWindow.getFocusedWindow() ||
    BrowserWindow.getAllWindows()[0] ||
    createWindow()
  )
}
