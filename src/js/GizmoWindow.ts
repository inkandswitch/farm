import * as Gizmo from "./Gizmo"


export function constructorForWindow(window: Window) {
  class GizmoWindowElement extends (window as any).HTMLElement {
    openedWindow : Window | null = null

    static get observedAttributes() {
      return ["code", "data"]
    }

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

      this.mount()
    }

    disconnectedCallback() {
      if (this.openedWindow) {
        this.openedWindow.close()
        this.openedWindow = null
      }
    }

    attributeChangedCallback(name: string, _oldValue: string, _newValue: string) {
      this.disconnectedCallback()
      this.connectedCallback()
    }

    mount() {
      if (this.openedWindow) return

      const { codeUrl, dataUrl } = this
      if (!codeUrl || !dataUrl) return

      const currentWindow = this.ownerDocument.defaultView

      // TODO: use realm url or per-gizmo url once we can auto-focus an already open window.
      this.openedWindow = open("", "")
      if (!this.openedWindow) return
      this.openedWindow.customElements.define('realm-ui', Gizmo.constructorForWindow(this.openedWindow))
      this.openedWindow.customElements.define('realm-window', constructorForWindow(this.openedWindow))
      const root = this.openedWindow.document.createElement("realm-ui")
      root.setAttribute("code", codeUrl)
      root.setAttribute("data", dataUrl)


      const body = this.openedWindow.document.body
      const styleNode = currentWindow.document.getElementsByTagName('style')[0]
      styleNode && body.appendChild(styleNode.cloneNode(true))
      body.appendChild(root)
      this.openedWindow.addEventListener('beforeunload', this.onBeforeWindowUnload)
    }

    onBeforeWindowUnload = () => {
      this.openedWindow = null
      // if (this.parentElement) {
      //   this.parentElement.removeChild(this)
      // }
    }
  }
  return GizmoWindowElement
}