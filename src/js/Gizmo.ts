import Repo from "./Repo"
import { Handle } from "hypermerge/dist/Handle"
import { whenChanged } from "./Subscription"
import Compiler from "./Compiler"
import ElmGizmo from "./ElmGizmo"


export function setRepo(repo: Repo) {
  ElmGizmo.repo = repo
}

export function setCompiler(compiler: Compiler) {
  ElmGizmo.compiler = compiler
}

export function  setSelfDataUrl(selfDataUrl: string) {
  ElmGizmo.selfDataUrl = selfDataUrl
}

export function constructorForWindow(window: Window) {
  class GizmoElement extends (window as any).HTMLElement {
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
            this.mount(this.toElm(source))
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

        const node = (this as any).ownerDocument.createElement("div")
        // this.shadowRoot.appendChild(node)
        this.appendChild(node)

        ElmGizmo.repo.once(dataUrl, (doc: any) => {
          this.gizmo = new ElmGizmo(node, elm, {
            code: codeUrl,
            data: dataUrl,
            doc,
            all: this.attrs,
          })

          this.gizmo.dispatchEvent = e => this.dispatchEvent(e)
        })
      }

      unmount() {
        this.innerHTML = ""

        if (this.gizmo) {
          this.gizmo.close()
          delete this.gizmo
        }
      }

      toElm(code: string) {
        // TODO: explore using vm.runInNewContext
        // Get a reference to this element's `window` (which may be different than
        // the global `window` if the gizmo was launched into its own window) to
        // ensure Elm javascript type checks are correct.
        // e.g. When evaluated in window A: `arrayFromWindowB instanceof Array == false`
        const ourWindow = (this as any).ownerDocument.defaultView

        // Elm logs warnings when being evaled, so temporarily noop `console.warn`
        const { warn } = ourWindow.console
        ourWindow.console.warn = () => {}
        const app = ourWindow.eval(code)
        ourWindow.console.warn = warn
        return Object.values(app)[0]
      }
    }
    return GizmoElement
  }

const getJsSource = (doc: any): string | undefined =>
  doc["Source.js"] || doc["source.js"]
