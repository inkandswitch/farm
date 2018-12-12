import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import * as Link from "./Link"
import { Handle } from "hypermerge/dist/Handle"
import QueuedWorker from "./QueuedWorker"


export default class Repo {
  worker: QueuedWorker<any, any>
  front: RepoFrontend

  constructor(url: string) {
    this.front = new RepoFrontend()
    this.worker = new QueuedWorker(url)

    this.worker.subscribe(this.front.receive)
    this.front.subscribe(this.worker.send)
  }

  create = (props: object = { fixme__: "orion" }): string => {
    const id = this.front.create()

    this.front
      .open(id)
      .change((state: any) => {
        Object.assign(state, props)
      })
      .close()

    return Link.fromId(id)
  }

  open = <T>(url: string): Handle<T> => {
    return this.front.open(Link.toId(url))
  }

  once = <T>(url: string, fn: Function): this => {
    const handle = this.open(url)
    handle.subscribe(doc => {
      fn(doc)
      handle.close()
    })
    return this
  }

  change = (url: string, fn: Function): this => {
    this.front
      .open(Link.toId(url))
      .change(fn)
      .close()
    return this
  }

  clone = (url: string): string => {
    const newUrl = this.create()

    this.once(url, (doc: any) => {
      this.change(newUrl, (state: any) => {
        Object.assign(state, doc)
      })
    })

    return newUrl
  }

  terminate() {
    this.worker.terminate()
  }
}
