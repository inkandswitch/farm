import { defaults, times } from "lodash"
import * as Diff from "./Diff"
import Repo from "./Repo"
import Compiler from "./Compiler"
import { Handle } from "hypermerge/dist/Handle"
import * as Author from "./Author"
import { shell } from "electron"

export interface ReceivePort<T> {
  subscribe(fn: (msg: T) => void): void
  unsubscribe(fn: (msg: T) => void): void
}

export interface SendPort<T> {
  send(msg: T): void
}

export interface ReceivePorts {
  initDoc?: ReceivePort<any>
  saveDoc: ReceivePort<any>
  command?: ReceivePort<[string, string]>
  emitted?: ReceivePort<[string, any]>
  repoOut?: ReceivePort<any>
  output?: ReceivePort<string[]>
  navigateToUrl?: ReceivePort<string>
  sentNotifications?: ReceivePort<ElmNotification>
}

export interface SendPorts {
  msgs?: SendPort<Msg>
  loadDoc: SendPort<any>
  created?: SendPort<[string, string[]]>
  rawDocs?: SendPort<[string, any]>
  navigatedUrls?: SendPort<string>
  notificationClicked?: SendPort<string>
  pasted?: SendPort<ClipboardEvent>
}

export type Ports = ReceivePorts & SendPorts

export interface ElmNotification {
  ref: string
  title: string
  body: string
}

export interface Unmount {
  t: "Unmount"
}

export type Msg = Unmount

export interface ElmApp {
  ports?: Ports
}

export interface Attributes {
  code: string
  data: string
  config: any
  doc: any
  all: { [k: string]: string }
}

export interface Detail {
  name: string
  value: string
  code: string
  data: string
}

export default class ElmGizmo {
  static repo: Repo
  static compiler: Compiler
  static selfDataUrl: string

  handle: Handle<any>
  app: ElmApp
  repo: Repo
  attrs: Attributes
  disposables: Array<() => void>

  constructor(node: HTMLElement | null, elm: any, attrs: Attributes) {
    this.repo = ElmGizmo.repo
    this.handle = this.repo.open(attrs.data)
    this.attrs = attrs
    this.disposables = []

    this.app = elm.init({
      node,
      flags: {
        ...attrs,
        self: ElmGizmo.selfDataUrl,
      },
    })

    this.subscribe()
  }

  dispatchEvent(e: CustomEvent<Detail>) {}

  subscribeTo<T>(port: ReceivePort<T> | undefined, fn: (msg: T) => void): void {
    if (!port) return
    port.subscribe(fn)
    this.disposables.push(() => port.unsubscribe(fn))
  }

  subscribe() {
    const { ports } = this.app
    if (!ports) return

    this.subscribeTo(ports.initDoc, this.onInit)
    this.subscribeTo(ports.saveDoc, this.onSave)
    this.subscribeTo(ports.command, this.onCommand)
    this.subscribeTo(ports.emitted, this.onEmitted)
    this.subscribeTo(ports.repoOut, this.onRepoOut)
    this.subscribeTo(ports.output, this.onOutput)
    this.subscribeTo(ports.navigateToUrl, this.onNavigateToUrl)
    this.subscribeTo(ports.sentNotifications, this.onNotification)

    if (this.hasPort("pasted")) {
      const onPaste = (event: ClipboardEvent) => {
        const { srcElement } = event
        if (srcElement && srcElement.localName === "input") return
        if (srcElement && srcElement.localName === "textarea") return

        event.preventDefault()
        this.withPort("pasted", this.send(event))
      }

      document.addEventListener("paste", onPaste)
      this.disposables.push(() => {
        document.removeEventListener("paste", onPaste)
      })
    }
  }

  hasPort<K extends keyof Ports>(name: K): boolean {
    return Boolean(this.app.ports && this.app.ports[name])
  }

  withPort<K extends keyof Ports>(name: K, fn: (port: Ports[K]) => void) {
    const port = this.app.ports && this.app.ports[name]
    if (port) fn(port)
  }

  send<T>(msg: T): ((port?: SendPort<T>) => void) {
    return port => {
      if (!port) return
      try {
        port.send(msg)
      } catch (e) {
        console.error("Trying to send invalid message to port", msg)
      }
    }
  }

  sendDoc(doc: any) {
    this.withPort("loadDoc", this.send(doc))
  }

  sendMsg(msg: Msg) {
    this.withPort("msgs", this.send(msg))
  }

  sendCreated(ref: string, urls: string[]) {
    this.withPort("created", this.send([ref, urls]))
  }

  sendOpened(url: string, doc: any) {
    this.withPort("rawDocs", this.send([url, doc]))
  }

  navigateTo(url: string) {
    this.withPort("navigatedUrls", this.send(url))
  }

  onNavigateToUrl = (url: string) => {
    // TODO: ReceivePort->SendPort doesn't work
    this.navigateTo(url)
  }

  onSave = ({ doc, prevDoc }: any) => {
    this.handle.change((state: any) => {
      if (!prevDoc) return

      const changes = Diff.getChanges(prevDoc, doc)
      Diff.applyChanges(state, changes)
      state.authors = Author.recordAuthor(ElmGizmo.selfDataUrl, state.authors)
    })
  }

  onInit = (doc: any) => {
    this.handle.change((state: any) => {
      defaults(state, doc)

      // On init, only record the author if there is no existing authors
      // list. If there is no authors list, this is the very first init
      // of the doc and we want to record the current author as its
      // creator. If there is an author's list, we don't want to record
      // the current author unless a change is made - othewise we would
      // record everyone who *views* the document as an author.
      if (!state.authors) {
        state.authors = Author.recordAuthor(ElmGizmo.selfDataUrl, state.authors)
      }
    })

    this.handle.subscribe(doc => {
      if (isEmptyDoc(doc)) return
      this.sendDoc(doc)
    })
  }

  onRepoOut = (msg: any) => {
    switch (msg.t) {
      case "Create": {
        const props = msg.p || undefined
        const urls = times(msg.n, () => this.repo.create(props))
        console.log("sending urls", urls)
        this.sendCreated(msg.ref, urls)
        break
      }

      case "Fork": {
        const forkedUrl = this.repo.fork(msg.url)
        this.sendCreated(msg.ref, [forkedUrl])
        break
      }

      case "Clone": {
        const url = this.repo.clone(msg.url)
        this.sendCreated(msg.ref, [url])
        break
      }

      case "Open": {
        const handle = this.repo.open(msg.url)

        this.disposables.push(() => handle.close())

        handle.subscribe(doc => {
          this.sendOpened(msg.url, doc)
        })
        break
      }
    }
  }

  onOutput = (strs: string[]) => {
    console.log(...strs)
  }

  onCommand = ([cmd, str]: [string, string]) => {
    switch (cmd) {
      case "Copy":
        ;(<any>navigator).clipboard.writeText(str)
        break
      case "OpenExternal":
        shell.openExternal(str)
    }
  }

  onEmitted = ([name, value]: [string, any]) => {
    const { code, data } = this.attrs
    const detail = { name, value, code, data }
    console.log(detail)
    this.dispatchEvent(
      new CustomEvent(name, {
        detail,
        bubbles: true,
        composed: true,
      }),
    )
  }

  onNotification = (notif: ElmNotification) => {
    const result = new Notification(notif.title, {
      body: notif.body,
    })

    result.onclick = () => {
      this.withPort("notificationClicked", this.send(notif.ref))
    }
  }

  close() {
    this.sendMsg({ t: "Unmount" })

    this.handle.close()

    this.disposables.forEach(d => d())
    this.disposables = []
  }
}

function isEmptyDoc(doc: object | null): boolean {
  return !doc || Object.keys(doc).length === 0
}
