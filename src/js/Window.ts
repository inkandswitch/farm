export default class WindowElement extends HTMLElement {
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
      // TODO: close window?
  }

  attributeChangedCallback(name: string, _oldValue: string, _newValue: string) {
      // TODO: should this be here?
    this.disconnectedCallback()
    this.connectedCallback()
  }

  mount() {
    if (this.window) return

    const { codeUrl, dataUrl } = this
    if (!codeUrl || !dataUrl) return

    // TODO: only look this up once.
    const styleNode = document.getElementsByTagName('style')[0]

    const root = document.createElement("realm-ui")
    root.setAttribute("code", codeUrl)
    root.setAttribute("data", dataUrl)

    this.window = open("","")
    if (this.window) {
        styleNode && this.window.document.body.appendChild(styleNode.cloneNode(true))
        this.window.document.body.appendChild(root)
        this.window.onbeforeunload = () => {
            this.setAttribute("closed", "")
            this.window = null
            // TODO: remove this element from the dom
        }
    }
  }

  unmount() {
  }
}