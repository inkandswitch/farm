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

  static set selfDataUrl(selfDataUrl: string) {
    ElmGizmo.selfDataUrl = selfDataUrl
  }

  static get observedAttributes() {
    return ["code", "data"]
  }

  gizmo?: ElmGizmo
  source?: Handle<any>

  constructor() {
    super()
  }

  get dataUrl(): string | null {
    return this.getAttribute("data") || null
  }

  get codeUrl(): string | null {
    return this.getAttribute("code") || null
  }

  get attrs(): { [k: string]: string } {
    const out = {} as { [k: string]: string }
    for (let i = 0; i < this.attributes.length; i++) {
      const attr = this.attributes[i]
      out[attr.name] = attr.value
    }
    return out
  }

  connectedCallback() {
    const { codeUrl } = this
    if (!codeUrl) return

    this.source = ElmGizmo.repo.open(codeUrl)
    ElmGizmo.compiler.add(codeUrl)

    this.source.subscribe(
      whenChanged(getJsSource, source => {
        this.mount(toElm(source))
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

  navigateTo(url: string) {
    this.gizmo && this.gizmo.navigateTo(url)
  }

  mount(elm: any) {
    this.unmount()

    const { codeUrl, dataUrl } = this

    if (!codeUrl || !dataUrl) return

    const node = document.createElement("div")
    // this.shadowRoot.appendChild(node)
    this.appendChild(node)

    this.gizmo = new ElmGizmo(node, elm, {
      code: codeUrl,
      data: dataUrl,
      all: this.attrs,
    })

    this.gizmo.dispatchEvent = e => this.dispatchEvent(e)
  }

  unmount() {
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
  const { warn } = console
  console.warn = () => {}
  const app = eval(code)
  console.warn = warn
  return Object.values(app)[0]
}
