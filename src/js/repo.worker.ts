declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"

if ((self as any).module) {
  ;(self as any).module.paths.push(resolve("./node_modules"))
}

import raf from "random-access-file"
import { RepoBackend } from "hypermerge"
//import discoverySwarm from "discovery-swarm"
//import datDefaults from "dat-swarm-defaults"
import discoveryCloud from "discovery-cloud-client"

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
  // discoverySwarm(
  //   datDefaults({
  //     port: 0,
  //     id: repo.id,
  //     stream: repo.stream,
  //   }),
  // )
  new discoveryCloud({url: "wss://discovery-cloud.herokuapp.com", id: repo.id, stream: repo.stream})
)

console.log('repo worker loaded', repo)