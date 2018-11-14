process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

console.log("App starting...")

import { app, BrowserWindow } from "electron"

app.on("ready", createWindow)

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 720,
    webPreferences: {
      sandbox: false,
      nodeIntegration: true,
      nodeIntegrationInWorker: true,
    },
  })

  const url = "http://localhost:4000"

  console.log(`Opening '${url}'...`)
  win.loadURL(url)
  // win.loadFile("./dist/index.html") // production
}
