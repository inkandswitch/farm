import { Hypermerge } from "hypermerge"

import DiscoveryCloud from "discovery-cloud/Client"

const hm = new Hypermerge({ path: "./.data2" })

const stream = hm.stream
const id = Buffer.from("nettest" + Math.random())
const url = "wss://discovery-cloud.herokuapp.com"

const cloud = new DiscoveryCloud({ stream, id, url })
hm.joinSwarm(cloud)

const docId = process.argv[2]
console.log("docId", docId)

const manager = hm.openDocumentFrontend(docId)
;(global as any).manager = manager
;(global as any).repo = hm
manager.on("doc", (doc: any) => console.log("doc", doc))
setInterval(
  () =>
    manager.change((doc: any) => {
      doc.counter += 1
      console.log("counter", doc.counter)
    }),
  3000,
)
