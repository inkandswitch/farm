import { defaults, times } from "lodash"
import { observableDiff, applyChange } from "deep-diff"
import Repo from "./Repo"
import Compiler from "./Compiler"
import Handle from "hypermerge/dist/Handle"

export interface ReceivePort<T> {
  subscribe(fn: (msg: T) => void): void
  unsubscribe(fn: (msg: T) => void): void
}

export interface SendPort<T> {
  send(msg: T): void
}

export interface Ports {
  initDoc?: ReceivePort<any>
  saveDoc: ReceivePort<any>
  loadDoc: SendPort<any>
  repoOut?: ReceivePort<any>
  created?: SendPort<[string, string[]]>
  output?: ReceivePort<string[]>
}

export interface ElmApp {
  ports?: Ports
}

export default class ElmGizmo {
  static repo: Repo
  static compiler: Compiler
  static selfDataUrl: string

  handle: Handle<any>
  app: ElmApp
  repo: Repo

  constructor(node: HTMLElement | null, elm: any, code: string, data: string) {
    this.repo = ElmGizmo.repo
    this.handle = this.repo.open(data)

    ElmGizmo.compiler.add(code)

    this.app = elm.init({
      node,
      flags: {
        data,
        code,
        self: ElmGizmo.selfDataUrl,
      },
    })

    if (this.app.ports) {
      // console.log("ports", this.app.ports)
      this.subscribe(this.app.ports)
    }
  }

  subscribe(ports: Ports) {
    if (!ports.initDoc) {
      console.error("This looks like an invalid component. Not subscribing.")
      return
    }
    ports.initDoc.subscribe(this.onInit)
    ports.saveDoc.subscribe(this.onSave)
    ports.repoOut && ports.repoOut.subscribe(this.onRepoOut)
    ports.output && ports.output.subscribe(this.onOutput)
  }

  unsubscribe(ports: Ports) {
    if (!ports.initDoc) {
      console.error("This looks like an invalid component. Not unsubscribing.")
      return
    }
    ports.initDoc.unsubscribe(this.onInit)
    ports.saveDoc.unsubscribe(this.onSave)

    if (ports.repoOut) {
      ports.repoOut.unsubscribe(this.onRepoOut)
    }

    if (ports.output) {
      ports.output.unsubscribe(this.onOutput)
    }
  }

  sendDoc(doc: any) {
    if (this.app.ports) {
      try {
        this.app.ports.loadDoc.send(doc)
      } catch (e) {
        console.error("Trying to send invalid doc to Gizmo", doc)
      }
    }
  }

  sendCreated(ref: string, urls: string[]) {
    this.app.ports &&
      this.app.ports.created &&
      this.app.ports.created.send([ref, urls])
  }

  onSave = ({ doc, prevDoc }: any) => {
    this.handle.change((state: any) => {
      if (!prevDoc) return

      observableDiff(prevDoc, doc, (change: any) => {
        // console.log("Applying", change)
        applyChange(state, doc, change)
      })
    })
  }

  onInit = (doc: any) => {
    this.handle.change((state: any) => {
      defaults(state, doc)
    })

    this.handle.subscribe(doc => {
      if (isEmptyDoc(doc)) return
      this.sendDoc(doc)
    })
  }

  onRepoOut = (msg: any) => {
    switch (msg.t) {
      case "Create":
        const urls = times(msg.n, () => this.repo.create())
        console.log("sending urls", urls)
        this.sendCreated(msg.ref, urls)
        break

      case "Clone":
        const url = this.repo.clone(msg.url)
        this.sendCreated(msg.ref, [url])
    }
  }

  onOutput = (strs: string[]) => {
    console.log(...strs)
  }

  close() {
    this.handle.close()
    if (this.app.ports) {
      this.unsubscribe(this.app.ports)
    }
  }
}

function isEmptyDoc(doc: object | null): boolean {
  return !doc || Object.keys(doc).length === 0
}
