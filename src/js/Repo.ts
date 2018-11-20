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

  once = <T>(url: string, fn: Function): this => {
    const handle = this.open(url)
    handle.subscribe(doc => {
      fn(doc)
      handle.close()
    })
    return this
  }

  change = (url: string, fn: Function): this => {
    super
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
}
