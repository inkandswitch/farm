declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
;(self as any).module.paths.push(resolve("./node_modules"))

import QueuedPort from "./QueuedPort"
import * as Msg from "./Msg"
import { keyPair } from "hypercore/lib/crypto"
import { Hypermerge, FrontendManager } from "hypermerge"
import { applyDiff } from "deep-diff"

const port = new QueuedPort<Msg.FromRepo, Msg.ToRepo>(self).connect()

const path = "./.data"

const repo = new Hypermerge({ path })

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

        manager.change((doc: any) => {
          Object.assign(doc, msg.doc)
        })

        manager.on("doc", doc => {
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
