process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

import App from "./App"
import Debug from "debug"
import URL from "url"
import { ipcRenderer, remote } from "electron"

const { protocol } = remote

const app = new App()

Object.assign(self, {
  Debug,
  app,
})

protocol.registerBufferProtocol("hyperfile", (request, callback) => {
  const id = request.url.slice(12)
  console.log(`HYPERFILE-RENDER6='${id}'`)
  app.repo.front.readFile(id, (_data, mimeType) => {
    console.log(`HYPERFILE-RENDERb='${_data.length} bytes'`)
    const data = Buffer.from(_data)
    callback({ mimeType, data })
  })
})

ipcRenderer.on("open-url", (_event: any, url: string) => {
  console.log("Opening url", url)
  app.handleUrl(url)
})
