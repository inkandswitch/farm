declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
;(self as any).module.paths.push(resolve("./node_modules"))

import RepoWorker from "./RepoWorker"

new RepoWorker(self).start()
