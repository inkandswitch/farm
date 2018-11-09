declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
;(self as any).module.paths.push(resolve("./node_modules"))

import raf from "random-access-file"
import { RepoBackend } from "hypermerge"
import Client from "discovery-cloud/Client"

const repo = new RepoBackend({ storage: raf, path: "./.data" })
;(self as any).repo = repo

self.onmessage = msg => {
  repo.receive(msg.data)
}

repo.subscribe(msg => {
  self.postMessage(msg)
})

repo.replicate(
  new Client({
    id: repo.id,
    stream: repo.stream,
    url: "wss://discovery-cloud.herokuapp.com",
  }),
)
