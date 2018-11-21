import Repo from "./Repo"
import Handle from "hypermerge/dist/Handle"
import { whenChanged } from "./Subscription"
import Compiler from "./Compiler"
import ElmGizmo from "./ElmGizmo"

export default class GizmoElement extends HTMLElement {
  static set repo(repo: Repo) {
    ElmGizmo.repo = repo
  }

  static set compiler(compiler: Compiler) {
    ElmGizmo.compiler = compiler
  }

  static get observedAttributes() {
    return ["code", "data"]
  }

  gizmo?: ElmGizmo
  source?: Handle<any>

  constructor() {
    super()

    // this.attachShadow({ mode: "open" })
  }

  get dataUrl(): string | null {
    return this.getAttribute("data") || null
  }

  get codeUrl(): string | null {
    return this.getAttribute("code") || null
  }

  connectedCallback() {
    const { codeUrl } = this
    if (!codeUrl) return

    this.source = ElmGizmo.repo.open(codeUrl)
    ElmGizmo.compiler.add(codeUrl)

    this.source.subscribe(
      whenChanged(getJsSource, source => {
        this.remount(toElm(eval(source)))
      }),
    )
  }

  disconnectedCallback() {
    if (this.source) {
      this.source.close()
      delete this.source
    }
  }

  attributeChangedCallback(name: string, _oldValue: string, _newValue: string) {
    this.disconnectedCallback()
    this.connectedCallback()
  }

  remount(elm: any) {
    this.unmount()
    this.mount(elm)
  }

  mount(elm: any) {
    // if (!this.shadowRoot) throw new Error("No shadow root! " + this.codeUrl)

    const { codeUrl, dataUrl } = this

    if (!codeUrl || !dataUrl) return

    const node = document.createElement("div")
    // this.shadowRoot.appendChild(node)
    this.appendChild(node)

    this.gizmo = new ElmGizmo(node, elm, codeUrl, dataUrl)
  }

  unmount() {
    // if (this.shadowRoot) {
    //   this.shadowRoot.innerHTML = ""
    // }
    this.innerHTML = ""

    if (this.gizmo) {
      this.gizmo.close()
      delete this.gizmo
    }
  }
}

const getJsSource = (doc: any): string | undefined =>
  doc["Source.js"] || doc["source.js"]

function toElm(code: string) {
  return Object.values(eval(code))[0]
}

// function isArrayPush(lhs: any, change: Diff<any, any>) {
//   return change.kind === "A" && change.index === _.get(lhs, change.path).length
// }
