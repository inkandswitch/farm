export default class GizmoWindowElement extends HTMLElement {
  static styleNode?: Node

  window : Window | null = null

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
    if (this.window) {
      this.window.close()
      this.window = null
    }
  }

  attributeChangedCallback(name: string, _oldValue: string, _newValue: string) {
    this.disconnectedCallback()
    this.connectedCallback()
  }

  mount() {
    if (this.window) return

    const { codeUrl, dataUrl } = this
    if (!codeUrl || !dataUrl) return

    const root = document.createElement("realm-ui")
    root.setAttribute("code", codeUrl)
    root.setAttribute("data", dataUrl)

    // TODO: use realm url or per-gizmo url once we can auto-focus an already open window.
    this.window = open("", "")
    if (!this.window) return

    const body = this.window.document.body
    GizmoWindowElement.styleNode && body.appendChild(GizmoWindowElement.styleNode.cloneNode(true))
    body.appendChild(root)
    this.window.addEventListener('beforeunload', this.onBeforeWindowUnload)
  }

  onBeforeWindowUnload = () => {
    this.window = null
    // if (this.parentElement) {
    //   this.parentElement.removeChild(this)
    // }
  }
}