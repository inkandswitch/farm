process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

import App from "./App"
import Debug from "debug"
import URL from "url"
import { ipcRenderer, remote } from "electron"

const { protocol } = remote

const app = new App()
;(<any>self).app = app

Object.assign(self, {
  Debug,
  app,
})

protocol.registerBufferProtocol("hyperfile", async ({ url }, callback) => {
  console.log("Getting", url)
  const { mimeType, data } = await app.repo.readFile(url)
  console.log("Found", mimeType)
  callback({ mimeType, data: Buffer.from(data) })
})

addEventListener("beforeunload", () => {
  protocol.unregisterProtocol("hyperfile")
})

ipcRenderer.on("open-url", (_event: any, url: string) => {
  console.log("Opening url", url)
  app.handleUrl(url)
})
