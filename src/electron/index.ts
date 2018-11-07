process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

console.log(__dirname)
console.log(process.env["NODE_PATH"])
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

  win.loadURL("http://localhost:4000")
  // win.loadFile("./dist/index.html") // production
}
