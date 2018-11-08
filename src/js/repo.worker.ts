declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
;(self as any).module.paths.push(resolve("./node_modules"))

import QueuedPort from "./QueuedPort"
import * as Msg from "./Msg"
import { keyPair } from "hypercore/lib/crypto"
import { Hypermerge, FrontendManager } from "hypermerge"
import { applyDiff } from "deep-diff"
import DiscoveryCloud from "discovery-cloud/Client"
import Debug from "debug"

Debug.enable("*")

const port = new QueuedPort<Msg.FromRepo, Msg.ToRepo>(self).connect()

const path = "./.data"

const repo = new Hypermerge({ path })

const stream = repo.stream
const id = Buffer.from("repo-" + Math.random())
const url = "wss://discovery-cloud.herokuapp.com"

const cloud = new DiscoveryCloud({ stream, id, url })
repo.joinSwarm(cloud)

let manager: FrontendManager<any>

port.subscribe(msg => {
  switch (msg.t) {
    case "Doc": {
      if (manager) {
        manager.change((doc: any) => {
          applyDiff(doc, msg.doc)
        })
      } else {
        manager = repo.createDocumentFrontend(keyPair())
        console.log("Model docId", manager.docId)

        manager.change((doc: any) => {
          Object.assign(doc, msg.doc)
        })

        manager.on("doc", doc => {
          console.log("doc", doc)
          port.send({
            t: "Doc",
            doc,
          })
        })
      }

      break
    }
  }
})
