import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import Handle from "hypermerge/dist/Handle"
import { applyDiff } from "deep-diff"
import { defaults } from "lodash"
import ElmApp from "./ElmApp"
import { whenChanged } from "./Subscription"

type Repo = RepoFrontend

export default class WidgetElement extends HTMLElement {
  static set repo(repo: Repo) {
    Widget.repo = repo
  }

  static get observedAttributes() {
    return ["docId", "sourceId"]
  }

  widget?: Widget
  source?: Handle<any>

  constructor() {
    super()
    this.attachShadow({ mode: "open" })
  }

  get docId(): string {
    const id = this.getAttribute("docId")
    if (!id) throw new Error(name + " docId attribute is required!")
    return id
  }

  get sourceId(): string {
    const id = this.getAttribute("sourceId")
    if (!id) throw new Error(name + " sourceId attribute is required!")
    return id
  }

  connectedCallback() {
    this.source = Widget.repo.open(this.sourceId)

    this.source.subscribe(
      whenChanged(getJsSource, (source, doc) => {
        this.remount(toElm(eval(source)))
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

  remount(elm: any) {
    this.unmount()
    this.mount(elm)
  }

  mount(elm: any) {
    if (!this.shadowRoot) throw new Error("No shadow root! " + this.sourceId)

    const node = document.createElement("div")
    this.shadowRoot.appendChild(node)

    this.widget = new Widget(node, elm, this.sourceId, this.docId)
  }

  unmount() {
    if (this.shadowRoot) {
      this.shadowRoot.innerHTML = ""
    }

    if (this.widget) {
      this.widget.close()
      delete this.widget
    }
  }
}

export class Widget {
  static repo: RepoFrontend

  handle: Handle<any>
  app: ElmApp

  constructor(node: HTMLElement, elm: any, sourceId: string, docId: string) {
    this.handle = Widget.repo.open(docId)
    this.app = new ElmApp(elm)

    this.app = new ElmApp(
      elm.init({
        node,
        flags: {
          docId,
          sourceId,
        },
      }),
    )

    this.app.subscribe(msg => {
      if (msg.doc) {
        this.handle.change((state: any) => {
          applyDiff(state, msg.doc)
        })
      }

      if (msg.init) {
        this.handle.change((state: any) => {
          defaults(state, msg.init)
        })

        this.handle.subscribe(doc => {
          if (isEmptyDoc(doc)) return
          this.app.send({ doc, msg: null })
        })
      }
    })
  }

  close() {
    this.app.unsubscribe()
    this.handle.close()
  }
}

const getJsSource = (doc: any): string | undefined => doc["source.js"]

function isEmptyDoc(doc: object | null): boolean {
  return !doc || Object.keys(doc).length === 0
}

function toElm(code: string) {
  return Object.values(eval(code))[0]
}
