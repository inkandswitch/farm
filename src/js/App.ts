import Repo from "./Repo"
import Compiler from "./Compiler"
import * as Gizmo from "./Gizmo"
import * as FarmUrl from "./FarmUrl"
import * as GizmoWindow from "./GizmoWindow"
import * as Bs from "./bootstrap"
import * as Workspace from "./bootstrap/Workspace"
import * as Draggable from "./Draggable"

require("utp-native")

const REPO_ROOT = process.env.REPO_ROOT || ""

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = new Repo("./repo.worker.js")
  compiler: Compiler = new Compiler(this.repo, "./compile.worker.js")
  root?: HTMLElement

  selfDataUrl = load("selfDataUrl", () => Workspace.identityData(this.repo))
  registryUrl = load("rootRegistryUrl", () => Workspace.registryData(this.selfDataUrl, this.repo))
  rootCodeUrl = load("rootCodeUrl", () => Workspace.code(this.selfDataUrl, this.repo))
  rootDataUrl = load("rootDataUrl", () => Workspace.data(this.selfDataUrl, this.repo))

  constructor() {
    ;(self as any).repo = this.repo
    Gizmo.setRepo(this.repo)
    Gizmo.setCompiler(this.compiler)
    Gizmo.setSelfDataUrl(this.selfDataUrl)
    Compiler.setSelfDataUrl(this.selfDataUrl)

    customElements.define("farm-draggable", Draggable.constructorForWindow(window))
    customElements.define("farm-ui", Gizmo.constructorForWindow(window))
    customElements.define(
      "farm-window",
      GizmoWindow.constructorForWindow(window),
    )

    // Deprecated
    customElements.define("realm-ui", Gizmo.constructorForWindow(window))
    customElements.define(
      "realm-window",
      GizmoWindow.constructorForWindow(window),
    )

    // XXX: Elm-compatible DataTransfer
    Object.defineProperty(DataTransfer.prototype, "elmFiles", {
      get() {
        return Array.prototype.map.call(this.items, (item: DataTransferItem) => {
          const file = item.getAsFile()
          if (file) {
            return file
          } else {
            return new File([this.getData(item.type)], item.type, { type: item.type })
          }
        })
      }
    })


    const style = document.createElement("style")
    style.innerHTML = css()
    document.body.appendChild(style)

    this.repo.setRegistry(this.registryUrl).then(() => {
      this.root = document.createElement("farm-ui")
      this.root.setAttribute("code", this.rootCodeUrl)
      this.root.setAttribute("data", this.rootDataUrl)
      document.body.appendChild(this.root)
    })
  }

  handleUrl(url: string) {
    this.root && (<any>this.root).navigateTo(url)
  }

  bootstrap(name: string) {
    const mkCode = (<any>Workspace)[name]
    const mkData =
      (<any>Workspace)[name + "Data"] || ((repo: Repo) => repo.create())

    if (!mkCode)
      throw new Error(
        `Could not find gizmo named "${name}". Check Workspace.ts`,
      )
    const code = mkCode(this.repo)
    const data = mkData(this.repo)
    const farm = FarmUrl.create({ code, data })

    console.log("\n\ncode url:", code, "\n\n")
    console.log("\n\ndata url:", data, "\n\n")
    console.log("\n\nfarm url:", farm, "\n\n")

    return { code, data, farm }
  }

  createCode(file: string, options: Bs.Opts) {
    return Bs.createCode(this.selfDataUrl, this.repo, file, options)
  }
}

function load(key: string, def: () => string): string {
  key = REPO_ROOT + key
  if (localStorage[key]) return localStorage[key]
  const value = def()
  localStorage[key] = value
  return value
}

function css(): string {
  return `
  @import url('https://fonts.googleapis.com/css?family=IBM+Plex+Sans:300,300i,400,400i,700,700i');

  * {
    box-sizing: border-box;
  }

  html, body, div, span, applet, object, iframe,
  h1, h2, h3, h4, h5, h6, p, blockquote, pre,
  a, abbr, acronym, address, big, cite, code,
  del, dfn, em, font, img, ins, kbd, q, s, samp,
  small, strike, strong, sub, sup, tt, var,
  dl, dt, dd, ol, ul, li,
  fieldset, form, label, legend,
  table, caption, tbody, tfoot, thead, tr, th, td {
    margin: 0;
    padding: 0;
    border: 0;
    outline: 0;
    font-weight: inherit;
    font-style: inherit;
    font-size: 100%;
    font-family: inherit;
    vertical-align: baseline;
  }
  /* remember to define focus styles! */
  :focus {
    outline: 0;
  }
  body {
    line-height: 1;
    color: black;
    background: white;
    font-family: 'IBM Plex Sans', Helvetica, Arial, system-ui, sans-serif;
  }
  ol, ul {
    list-style: none;
  }
  /* tables still need 'cellspacing="0"' in the markup */
  table {
    border-collapse: separate;
    border-spacing: 0;
  }
  caption, th, td {
    text-align: left;
    font-weight: normal;
  }
  blockquote:before, blockquote:after,
  q:before, q:after {
    content: "";
  }
  blockquote, q {
    quotes: "" "";
  }

  farm-ui {
    display: contents;
  }
`
}
