import QueuedWorker from "./QueuedWorker"
import * as Msg from "./Msg"

type Repo = QueuedWorker<Msg.ToRepo, Msg.FromRepo>

export default class Widget {
  elm: any
  app: any
  node: HTMLElement
  repo: Repo

  constructor(repo: Repo, elm: any) {
    this.elm = elm
    this.node = document.createElement("div")
    this.repo = repo
  }

  mount(parent: HTMLElement) {
    parent.appendChild(this.node)
    this.app = this.elm.init({
      flags: null,
      node: this.node,
    })

    this.app.ports.output.subscribe((doc: object) => {
      this.repo.send({ t: "Doc", doc })
    })

    this.repo.subscribe(msg => {
      this.app.ports.input.send(msg.doc)
    })
  }

  destroy() {
    this.repo.unsubscribe()
    this.app.ports.output.unsubscribe()
    this.node.remove()
  }
}
