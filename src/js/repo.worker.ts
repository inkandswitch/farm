import { app } from "electron"
import { Hypermerge } from "hypermerge"
import { join } from "path"

const path = join(app.getPath("documents"), "Realm")

const hm = new Hypermerge({ path })
