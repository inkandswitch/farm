import { Repo } from "hypermerge"
import raf from "random-access-file"

import DiscoveryCloud from "discovery-cloud/Client"

const repo = new Repo({ storage: raf, path: "./.data2" })

const stream = repo.stream
const id = Buffer.from("nettest" + Math.random())
const url = "wss://discovery-cloud.herokuapp.com"

const cloud = new DiscoveryCloud({ stream, id, url })
repo.replicate(cloud)

const docId = process.argv[2]
console.log("docId", docId)

const handle = repo.open(docId)
;(global as any).handle = handle
;(global as any).repo = repo

handle.subscribe((doc: any) => console.log("doc", doc))
