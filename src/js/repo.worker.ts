declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"

if ((self as any).module) {
  ;(self as any).module.paths.push(resolve("./node_modules"))
}

import raf from "random-access-file"
import { RepoBackend } from "hypermerge"
const Client = require("discovery-swarm")

const storagePath = process.env.REPO_ROOT || "./.data"

const repo = new RepoBackend({ storage: raf, path: storagePath })
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
  }),
)
