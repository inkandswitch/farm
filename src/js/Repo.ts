import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import { Handle } from "hypermerge/dist/Handle"
import QueuedWorker from "./QueuedWorker"
// import FakeWorker from "./FakeWorker"

export default class Repo {
  worker: QueuedWorker<any, any>
  front: RepoFrontend

  constructor(url: string) {
    this.front = new RepoFrontend()

    // Swap to allow utp-native usage:
    this.worker = new QueuedWorker(url)
    // this.worker = new FakeWorker(url)

    this.worker.subscribe(this.front.receive)
    this.front.subscribe(this.worker.send)
  }

  create = (props: object = { fixme__: "orion" }): string => {
    const url = this.front.create()

    this.front
      .open(url)
      .change((state: any) => {
        Object.assign(state, props)
      })
      .close()

    return url
  }

  open = <T>(url: string): Handle<T> => {
    return this.front.open(url)
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
      .open(url)
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

  fork = (url: string): string => {
    return this.front.fork(url)
  }

  terminate() {
    this.worker.terminate()
  }
}
