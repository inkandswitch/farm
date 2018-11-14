import * as Repo from "./Repo"
import { readFileSync } from "fs"
import path from "path"
import Compiler from "./Compiler"
import Widget from "./Widget"

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = Repo.worker("./repo.worker.js")
  compiler: Compiler = new Compiler(this.repo)

  rootId: string = load("rootId", () =>
    this.bootstrapDoc({
      sourceId: this.bootstrapWidget("Chat", "Chat.elm"),
      id: this.repo.create(),
    }),
  )
  rootSourceId: string = load("rootSourceId", () =>
    this.bootstrapWidget("Nav", "Nav.elm"),
  )

  constructor() {
    Widget.repo = this.repo
    Widget.compiler = this.compiler
    customElements.define("realm-ui", Widget)

    // this.compiler.add(this.rootSourceId)

    const root = document.createElement("realm-ui")
    root.setAttribute("sourceId", this.rootSourceId)
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
    handle.close()
    return id
  }

  bootstrapDoc(props: object): string {
    const id = this.repo.create()
    const handle = this.repo.open(id)
    handle.change((doc: any) => {
      Object.assign(doc, props)
    })
    handle.close()
    return id
  }
}

function sourceFor(name: string) {
  return readFileSync(path.resolve(`src/elm/${name}`)).toString()
}

function load(key: string, def: () => string): string {
  if (localStorage[key]) return localStorage[key]
  const value = def()
  localStorage[key] = value
  return value
}
