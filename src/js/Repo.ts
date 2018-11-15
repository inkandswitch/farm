import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import * as Link from "./Link"
import Handle from "hypermerge/dist/Handle"

export default class Repo extends RepoFrontend {
  worker: Worker

  constructor(url: string) {
    super()
    this.worker = new Worker(url)

    this.worker.onmessage = event => {
      this.receive(event.data)
    }

    this.subscribe(msg => {
      this.worker.postMessage(msg)
    })
  }

  create = (props: object = { fixme__: "orion" }): string => {
    const id = super.create()

    super
      .open(id)
      .change((state: any) => {
        Object.assign(state, props)
      })
      .close()

    return Link.fromId(id)
  }

  open = <T>(url: string): Handle<T> => {
    return super.open(Link.toId(url))
  }

  change = (url: string, fn: Function): this => {
    super
      .open(url)
      .change(fn)
      .close()
    return this
  }
}
