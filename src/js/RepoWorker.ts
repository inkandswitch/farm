import QueuedPort, { Port } from "./QueuedPort"
import * as Msg from "./Msg"
import { keyPair } from "hypercore/lib/crypto"
import { Hypermerge, FrontendManager } from "hypermerge"
import { applyDiff } from "deep-diff"
import DiscoveryCloud from "discovery-cloud/Client"

export default class RepoWorker {
  port: QueuedPort<Msg.FromRepo, Msg.ToRepo>
  repo = new Hypermerge({ path: "./.data" })
  rootUrl?: string
  root?: FrontendManager<any>

  constructor(self: Port) {
    this.port = new QueuedPort<Msg.FromRepo, Msg.ToRepo>(self)
  }

  start() {
    this.port.connect()

    this.port.subscribe(this.receive)
  }

  startNetworking() {
    const stream = this.repo.stream
    const id = Buffer.from("repo-" + Math.random())
    const url = "wss://discovery-cloud.herokuapp.com"

    const cloud = new DiscoveryCloud({ stream, id, url })
    this.repo.joinSwarm(cloud)
  }

  receive = (msg: Msg.ToRepo) => {
    switch (msg.t) {
      case "Start": {
        if (msg.rootUrl) {
          this.rootUrl = msg.rootUrl
          this.root = this.repo.openDocumentFrontend(this.rootUrl)
        } else {
          this.root = this.repo.createDocumentFrontend(keyPair())
          this.rootUrl = this.root.docId
        }

        this.port.send({
          t: "Ready",
          rootUrl: this.rootUrl,
        })

        this.watch(this.root)
        break
      }

      case "Open":
        this.watch(this.repo.openDocumentFrontend(msg.docId))
        break

      case "Create": {
        const man = this.repo.createDocumentFrontend(keyPair())

        man.change((doc: any) => {
          Object.assign(doc, msg.doc)
        })

        this.watch(man)
        break
      }

      case "Doc":
        this.repo.openDocumentFrontend(msg.docId).change((doc: any) => {
          applyDiff(doc, msg.doc)
        })

        break
    }
  }

  watch(manager: FrontendManager<any>) {
    manager.on("doc", doc => {
      this.port.send({
        t: "Doc",
        docId: manager.docId,
        doc,
      })
    })
  }
}
