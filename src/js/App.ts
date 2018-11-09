import * as Repo from "./Repo"
import { readFileSync } from "fs"
import path from "path"
import Registry from "./Registry"

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = Repo.worker("./repo.worker.js")
  rootSourceId: string =
    localStorage.rootSourceId || (localStorage.rootSourceId = this.createRoot())

  rootId: string =
    localStorage.rootId || (localStorage.rootId = this.repo.create())

  registry = new Registry(this.repo)

  start() {
    this.registry.add(this.rootSourceId)
    const root = document.createElement("realm-root")
    root.setAttribute("docId", this.rootId)
    document.body.appendChild(root)
  }

  createRoot(): string {
    const id = this.repo.create()
    const handle = this.repo.open(id)
    handle.change((doc: any) => {
      doc.name = "root"
      doc["source.elm"] = ROOT_SOURCE_CODE
    })
    handle.cleanup()
    return id
  }
}

const ROOT_SOURCE_CODE = readFileSync(
  path.resolve("src/elm/Example.elm"),
).toString()
