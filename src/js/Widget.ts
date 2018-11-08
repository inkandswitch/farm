import QueuedWorker from "./QueuedWorker"
import * as Msg from "./Msg"

type Repo = QueuedWorker<Msg.ToRepo, Msg.FromRepo>

interface App {
  ports: {
    output: {
      subscribe(fn: Function): void
      unsubscribe(fn: Function): void
    }
    input: {
      send(msg: any): void
    }
  }
}

export default class Widget {
  app?: App
  doc: null | object = null
  repo: Repo

  constructor(repo: Repo) {
    this.repo = repo
  }

  start(elm: any, parent: HTMLElement) {
    this.stop(parent)

    const node = document.createElement("div")
    parent.appendChild(node)
    const app = elm.init({
      flags: this.doc,
      node,
    })

    app.ports.output.subscribe(this.sendToRepo)

    this.repo.subscribe(msg => {
      this.doc = msg.doc
      app.ports.input.send(msg.doc)
    })
    this.app = app
  }

  sendToRepo = (doc: object) => {
    this.repo.send({ t: "Doc", doc })
  }

  stop(parent: HTMLElement) {
    if (this.app) {
      this.repo.unsubscribe()
      this.app.ports.output.unsubscribe(this.sendToRepo)
      delete this.app

      while (parent.firstChild) {
        parent.removeChild(parent.firstChild)
      }
    }
  }
}
