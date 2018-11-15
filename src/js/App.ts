import Repo from "./Repo"
import { readFileSync } from "fs"
import path from "path"
import Compiler from "./Compiler"
import Widget from "./Widget"

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = new Repo("./repo.worker.js")
  compiler: Compiler = new Compiler(this.repo)

  rootDocUrl: string = load("rootDocUrl", () =>
    this.bootstrapDoc({
      sourceId: this.bootstrapWidget("Chat", "Chat.elm"),
      id: this.repo.create(),
    }),
  )
  rootSrc: string = load("rootSrc", () =>
    this.bootstrapWidget("Nav", "Nav.elm"),
  )

  constructor() {
    ;(self as any).repo = this.repo
    Widget.repo = this.repo
    Widget.compiler = this.compiler
    customElements.define("realm-ui", Widget)

    // this.compiler.add(this.rootSrc)

    const root = document.createElement("realm-ui")
    root.setAttribute("src", this.rootSrc)
    root.setAttribute("doc", this.rootDocUrl)
    document.body.appendChild(root)
  }

  bootstrapWidget(name: string, file: string): string {
    const url = this.repo.create()
    const handle = this.repo.open(url)
    handle.change((doc: any) => {
      doc.name = name
      doc["source.elm"] = sourceFor(file)
    })
    handle.close()
    return url
  }

  bootstrapDoc(props: object): string {
    const url = this.repo.create()
    const handle = this.repo.open(url)
    handle.change((doc: any) => {
      Object.assign(doc, props)
    })
    handle.close()
    return url
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
