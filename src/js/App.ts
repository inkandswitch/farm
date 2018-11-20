import Repo from "./Repo"
import { readFileSync } from "fs"
import path from "path"
import Compiler from "./Compiler"
import Gizmo from "./Gizmo"

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = new Repo("./repo.worker.js")
  compiler: Compiler = new Compiler(this.repo)

  rootDataUrl: string = load("rootDataUrl", () =>
    this.repo.create({
      title: "CreateExample data",
    }),
  )

  rootCodeUrl: string = load("rootCodeUrl", () =>
    this.bootstrapWidget("CreateExample.elm"),
  )

  constructor() {
    ;(self as any).repo = this.repo
    Gizmo.repo = this.repo
    Gizmo.compiler = this.compiler
    customElements.define("realm-ui", Gizmo)

    const style = document.createElement("style")
    style.innerHTML = "body { margin: 0px; }"
    document.body.appendChild(style)

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
