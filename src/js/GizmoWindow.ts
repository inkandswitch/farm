import * as Gizmo from "./Gizmo"
import * as FarmUrl from "./FarmUrl"

export function constructorForWindow(window: Window) {
  class GizmoWindowElement extends (window as any).HTMLElement {
    openedWindow: Window | null = null

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

    attributeChangedCallback(
      name: string,
      _oldValue: string,
      _newValue: string,
    ) {
      this.disconnectedCallback()
      this.connectedCallback()
    }

    // TODO: a lot going on here
    mount() {
      if (this.openedWindow) return

      const { codeUrl, dataUrl } = this
      if (!codeUrl || !dataUrl) return

      const currentWindow = this.ownerDocument.defaultView

      const windowName = FarmUrl.create({ code: codeUrl, data: dataUrl })
      this.openedWindow = open("", windowName)
      if (!this.openedWindow) return

      if (!this.openedWindow.customElements.get("farm-ui")) {
        this.openedWindow.customElements.define(
          "farm-ui",
          Gizmo.constructorForWindow(this.openedWindow),
        )
      }
      if (!this.openedWindow.customElements.get("farm-window")) {
        this.openedWindow.customElements.define(
          "farm-window",
          constructorForWindow(this.openedWindow),
        )
      }
      // TODO: focus window when opened.
      // Currently doesn't work due to this bug: https://github.com/electron/electron/issues/8969
      //this.openedWindow.focus()

      this.openedWindow.onbeforeunload = () => {
        console.log("on before unload")
        this.dispatchEvent(
          new CustomEvent("windowclose", {
            bubbles: true,
            composed: true,
          }),
        )
      }

      const root = this.openedWindow.document.createElement("farm-ui")
      root.setAttribute("code", codeUrl)
      root.setAttribute("data", dataUrl)

      const body = this.openedWindow.document.body
      const styleNode = currentWindow.document.getElementsByTagName("style")[0]
      styleNode && body.appendChild(styleNode.cloneNode(true))
      body.appendChild(root)
      this.openedWindow.addEventListener(
        "beforeunload",
        this.onBeforeWindowUnload,
      )
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
