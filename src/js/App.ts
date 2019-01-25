import Repo from "./Repo"
import Compiler from "./Compiler"
import * as Gizmo from "./Gizmo"
import * as FarmUrl from "./FarmUrl"
import * as GizmoWindow from "./GizmoWindow"
import * as Identity from "./bootstrap/Identity"
import * as Workspace from "./bootstrap/Workspace"
import * as Registry from "./bootstrap/Registry"
import * as Bs from "./bootstrap"

require("utp-native")

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = new Repo("./repo.worker.js")
  compiler: Compiler = new Compiler(this.repo, "./compile.worker.js")
  root?: HTMLElement

  registryUrl = load("rootRegistryUrl", () => Registry.data(this.repo))
  rootDataUrl = load("rootDataUrl", () => Workspace.data(this.repo))
  rootCodeUrl?: string
  selfDataUrl = load("selfDataUrl", () => Identity.data(this.repo))

  constructor() {
    ;(self as any).repo = this.repo
    Gizmo.setRepo(this.repo)
    Gizmo.setCompiler(this.compiler)
    Gizmo.setSelfDataUrl(this.selfDataUrl)

    customElements.define("farm-ui", Gizmo.constructorForWindow(window))
    customElements.define(
      "farm-window",
      GizmoWindow.constructorForWindow(window),
    )

    const style = document.createElement("style")
    style.innerHTML = css()
    document.body.appendChild(style)

    this.repo.setRegistry(this.registryUrl).then(() => {
      this.rootCodeUrl = load("rootCodeUrl", () => "hypermerge:/@ink/workspace")

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
    const bs = require("./bootstrap/" + name)
    const code = bs.code(this.repo)
    const data = bs.data(this.repo)
    console.log("\n\ncode url:", code, "\n\n")
    console.log("\n\ndata url:", data, "\n\n")

    const farmUrl = FarmUrl.create({ code, data })
    console.log("\n\nfarm url:", farmUrl, "\n\n")
  }

  bootstrapCode(file: string, options: Bs.Opts) {
    return Bs.code(this.repo, file, options)
  }
}

function load(key: string, def: () => string): string {
  if (localStorage[key]) return localStorage[key]
  const value = def()
  localStorage[key] = value
  return value
}

function css(): string {
  return `
  @import url('https://fonts.googleapis.com/css?family=IBM+Plex+Sans:300,300i,400,400i,700,700i')

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
