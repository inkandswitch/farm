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

  rootDataUrl: string = load("rootDataUrl", () =>
    this.repo.create({
      title: "Nav data",
      code: this.bootstrapWidget("Chat.elm"),
      data: this.repo.create({ title: "Chat data" }),
    }),
  )

  rootCodeUrl: string = load("rootCodeUrl", () =>
    this.bootstrapWidget("Nav.elm"),
  )

  constructor() {
    ;(self as any).repo = this.repo
    Widget.repo = this.repo
    Widget.compiler = this.compiler
    customElements.define("realm-ui", Widget)

    const root = document.createElement("realm-ui")
    root.setAttribute("code", this.rootCodeUrl)
    root.setAttribute("data", this.rootDataUrl)
    document.body.appendChild(root)
  }

  bootstrapWidget(file: string): string {
    return this.repo.create({
      title: `${file} code`,
      "source.elm": sourceFor(file),
    })
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
