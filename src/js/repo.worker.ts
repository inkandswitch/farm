declare const self: DedicatedWorkerGlobalScope

import { remote } from "electron"
import QueuedPort from "./QueuedPort"
import * as Msg from "./Msg"
import { keyPair } from "hypercore/lib/crypto"
import { applyDiff } from "deep-diff"
const { app } = remote

import { Hypermerge, FrontendManager } from "hypermerge"
import { join } from "path"

const port = new QueuedPort<Msg.FromRepo, Msg.ToRepo>(self).connect()

const path = join(app.getPath("documents"), "Realm")

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
