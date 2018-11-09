import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import Handle from "hypermerge/dist/Handle"
import { applyDiff } from "deep-diff"
import ElmApp from "./ElmApp"

type Repo = RepoFrontend

export function create(
  repo: Repo,
  name: string,
  sourceId: string,
  code: string,
) {
  const tag = "realm-" + name

  class Widget extends HTMLElement {
    static code = code

    static app: any = toApp(code)
    static instances = new Set<Widget>()

    static upgrade(newCode: string) {
      if (newCode === this.code) return
      this.code = newCode
      this.app = toApp(newCode)

      this.instances.forEach(widget => {
        widget.upgrade()
      })
    }

    app?: ElmApp
    handle?: Handle<any>

    constructor() {
      super()

      Widget.instances.add(this)

      this.attachShadow({ mode: "open" })
    }

    connectedCallback() {
      this.start()
    }

    disconnectedCallback() {
      this.stop()
    }

    start() {
      if (!this.shadowRoot) throw new Error("No shadow root! " + tag)

      const handle = repo.open(this.docId)
      this.handle = handle

      const node = document.createElement("div")
      this.shadowRoot.innerHTML = ""
      this.shadowRoot.appendChild(node)

      const app = new ElmApp(
        Widget.app.init({
          flags: {
            docId: this.docId,
            sourceId,
          },
          node,
        }),
        tag + Math.random(),
      )

      this.app = app

      app.subscribe(newDoc => {
        handle.change((doc: any) => {
          applyDiff(doc, newDoc)
        })
      })

      this.handle.subscribe(doc => {
        if (isEmptyDoc(doc)) return
        app.send(doc)
      })
    }

    upgrade() {
      this.stop()
      this.start()
    }

    stop() {
      this.handle && this.handle.close()
      this.app && this.app.close()
    }

    get docId(): string {
      const id = this.getAttribute("docId")

      if (!id) throw new Error(name + " docId attribute is required!")

      return id
    }

    set docId(id: string) {
      this.setAttribute("docId", id)
    }
  }

  customElements.define(tag, Widget)

  return Widget
}

function isEmptyDoc(doc: object | null): boolean {
  return !doc || Object.keys(doc).length === 0
}

function toApp(code: string) {
  return Object.values(eval(code))[0]
}
