import { app, BrowserWindow } from "electron"

app.on("ready", createWindow)

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 720,
    webPreferences: {
      nodeIntegration: true,
      nodeIntegrationInWorker: true,
    },
  })

  win.loadURL("http://localhost:4000")
  // win.loadFile("./dist/index.html") // production
}
