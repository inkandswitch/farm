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
    localStorage.rootSourceId ||
    (localStorage.rootSourceId = this.bootstrapWidget("root", "Chat.elm"))

  rootId: string =
    localStorage.rootId || (localStorage.rootId = this.repo.create())

  registry = new Registry(this.repo)

  start() {
    this.registry.add(this.rootSourceId)
    const root = document.createElement("realm-root")
    root.setAttribute("docId", this.rootId)
    document.body.appendChild(root)
  }

  bootstrapWidget(name: string, file: string): string {
    const id = this.repo.create()
    const handle = this.repo.open(id)
    handle.change((doc: any) => {
      doc.name = name
      doc["source.elm"] = sourceFor(file)
    })
    handle.cleanup()
    return id
  }
}

function sourceFor(name: string) {
  return readFileSync(path.resolve(`src/elm/${name}`)).toString()
}
