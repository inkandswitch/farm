process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

import App from "./App"
import Debug from "debug"
import { ipcRenderer } from "electron"

const app = new App()

Object.assign(self, {
  Debug,
  app,
})

ipcRenderer.on("open-url", (_event: any, url: string) => {
  console.log("Opening url", url)
  app.handleUrl(url)
})
