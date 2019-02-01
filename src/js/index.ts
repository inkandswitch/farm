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
  const { mimeType, data } = await app.repo.readFile(url)
  callback({ mimeType, data: Buffer.from(data) })
})

ipcRenderer.on("open-url", (_event: any, url: string) => {
  console.log("Opening url", url)
  app.handleUrl(url)
})
