export function constructorForWindow(window: Window) {
  class Draggable extends (window as any).HTMLElement {
    static get observedAttributes() {
      return ["dragtype", "dragdata"]
    }

    constructor() {
      super()
    }

    get dragDataType(): string | null {
        return this.getAttribute("dragtype") || null
    }

    get dragData(): string | null {
        return this.getAttribute("dragdata") || null
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
      const { dragData, dragDataType } = this
      if (!dragData || !dragDataType) {
          return
      }

      this.style.display = "block"
      this.draggable = true
      this.addEventListener("dragstart", function(event: any) {
        event.dataTransfer.setData(dragDataType, dragData) 
      })
    }

    disconnectedCallback() {
    }

    attributeChangedCallback(
      name: string,
      _oldValue: string,
      _newValue: string,
    ) {
    }

  }
  return Draggable
}
