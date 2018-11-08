process.env["DEBUG"] = "*"

import DiscoveryCloudClient from "./Client"

const crypto = require("crypto")
const id = crypto.randomBytes(32)
const url = "ws://0.0.0.0:8080"
const stream = null

const dk = new DiscoveryCloudClient({ id, url, stream })
dk.join(Buffer.from("foo"))
dk.join(Buffer.from("bar"))
dk.listen()

console.log("TEST")
