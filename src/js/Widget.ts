import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import Handle from "hypermerge/dist/Handle"
import { applyDiff } from "deep-diff"
import ElmApp from "./ElmApp"

type Repo = RepoFrontend

export function create(repo: Repo, name: string, code: string) {
  const tag = "realm-" + name
  console.log("creating widget", tag)

  class Widget extends HTMLElement {
    static code = code

    static app: any = toApp(code)
    static instances = new Set<Widget>()

    static upgrade(code: string) {
      if (code === this.code) return
      this.code = code
      this.app = toApp(code)

      this.instances.forEach(widget => {
        widget.upgrade()
      })
    }

    app?: ElmApp
    handle?: Handle<any>
    node = document.createElement("div")

    constructor() {
      super()

      Widget.instances.add(this)

      console.log("constructing widget", name)

      this.attachShadow({ mode: "open" }).append(this.node)
    }

    connectedCallback() {
      this.start()
    }

    disconnectedCallback() {
      this.stop()
    }

    start() {
      const handle = repo.open(this.docId)
      this.handle = handle

      const app = new ElmApp(
        Widget.app.init({
          flags: null,
          node: this.node,
        }),
        tag,
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
