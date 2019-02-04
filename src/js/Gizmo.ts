import Repo from "./Repo"
import { Handle } from "hypermerge/dist/Handle"
import { whenChanged } from "./Subscription"
import Compiler from "./Compiler"
import ElmGizmo from "./ElmGizmo"
import * as Code from "./Code"
import * as Link from "./Link"

export function setRepo(repo: Repo) {
  ElmGizmo.repo = repo
}

export function setCompiler(compiler: Compiler) {
  ElmGizmo.compiler = compiler
}

export function setSelfDataUrl(selfDataUrl: string) {
  ElmGizmo.selfDataUrl = selfDataUrl
}

export function constructorForWindow(window: Window) {
  class GizmoElement extends (window as any).HTMLElement {
    static get observedAttributes() {
      return ["code", "data", "portaltarget"]
    }

    gizmo?: ElmGizmo
    source?: Handle<any>
    repo = ElmGizmo.repo
    portal: HTMLElement | null

    constructor() {
      super()
      this.portal = null
    }

    get dataUrl(): string | null {
      return this.getAttribute("data") || null
    }

    get codeUrl(): string | null {
      return this.getAttribute("code") || null
    }

    get portalTarget(): string | null {
      return this.getAttribute("portaltarget") || null
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

      this.source = this.repo.open(codeUrl)
      ElmGizmo.compiler.add(codeUrl)

      this.source.subscribe(
        whenChanged(
          doc => doc.outputHash,
          async (outputHash, doc) => {
            const source = await Code.source(this.repo, doc)
            this.mount(this.toElm(source, outputHash), doc)
          },
        ),
      )
    }

    disconnectedCallback() {
      this.unmount()
      if (this.source) {
        this.source.close()
        delete this.source
      }
    }

    attributeChangedCallback(
      name: string,
      _oldValue: string,
      _newValue: string,
    ) {
      this.disconnectedCallback()
      this.connectedCallback()
    }

    navigateTo(url: string) {
      this.gizmo && this.gizmo.navigateTo(url)
    }

    mount(elm: any, codeDoc: any) {
      this.unmount()

      const { codeUrl, dataUrl, portalTarget } = this
      if (!codeUrl || !dataUrl) return

      let elmNode: any
      if (portalTarget) {
        const portalTargetNode = (this as any).ownerDocument.querySelector(portalTarget)
        if (!portalTargetNode) return
        this.portal = this.getPortal(codeUrl, dataUrl)
        elmNode = (this as any).ownerDocument.createElement("div")

        if (!this.portal) return
        this.portal.appendChild(elmNode)
        portalTargetNode.appendChild(this.portal)
      } else {
        elmNode = (this as any).ownerDocument.createElement("div")
        this.appendChild(elmNode)
      }

      this.repo.once(dataUrl, (doc: any) => {
        this.gizmo = new ElmGizmo(elmNode, elm, {
          code: codeUrl,
          data: dataUrl,
          config: codeDoc.config,
          doc,
          all: this.attrs,
        })

        this.gizmo.dispatchEvent = e => this.dispatchEvent(e)

        if (doc.config) {
          Object.values<any>(doc.config).forEach(url => {
            if (typeof url === "string" && Link.isValidLink(url)) {
              this.repo.preload(url)
            }
          })
        }
      })
    }

    unmount() {
      if (this.gizmo) {
        this.gizmo.close()
        delete this.gizmo
      }

      if (this.portal) {
        this.portal.innerHTML = ""
        this.portal.remove()
      } else {
        this.innerHTML = ""
      }
    }

    getPortal(code: string, data: string) {
      const portal = (this as any).ownerDocument.createElement("div")
      portal.setAttribute("portal-code", code)
      portal.setAttribute("portal-data", data)
      return portal
    }

    toElm(code: string, outputHash: string) {
      // TODO: explore using vm.runInNewContext
      // Get a reference to this element's `window` (which may be different than
      // the global `window` if the gizmo was launched into its own window) to
      // ensure Elm javascript type checks are correct.
      // e.g. When evaluated in window A: `arrayFromWindowB instanceof Array == false`
      const ourWindow = (this as any).ownerDocument.defaultView
      if (!ourWindow.elmCache) ourWindow.elmCache = new Map()

      if (outputHash && ourWindow.elmCache.has(outputHash)) {
        return ourWindow.elmCache.get(outputHash)
      }
      // Elm logs warnings when being evaled, so temporarily noop `console.warn`
      const { warn } = ourWindow.console
      ourWindow.console.warn = () => {}
      const app = ourWindow.eval(code)
      ourWindow.console.warn = warn
      const result = Object.values(app)[0]
      ourWindow.elmCache.set(outputHash, result)
      return result
    }
  }
  return GizmoElement
}
