import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import { Handle } from "hypermerge/dist/Handle"
import QueuedWorker from "./QueuedWorker"
// import FakeWorker from "./FakeWorker"

const decoder = new TextDecoder()

export interface HyperFile {
  data: Uint8Array
  mimeType: string
  text: string
}

export default class Repo {
  worker: QueuedWorker<any, any>
  front: RepoFrontend
  fileCache: Map<string, HyperFile>

  constructor(url: string) {
    this.front = new RepoFrontend()
    this.fileCache = new Map()

    // Swap to allow utp-native usage:
    this.worker = new QueuedWorker(url)
    // this.worker = new FakeWorker(url)

    this.worker.subscribe(this.front.receive)
    this.front.subscribe(this.worker.send)
  }

  async readFile(url: string): Promise<HyperFile> {
    return (
      this.fileCache.get(url) ||
      new Promise(res => {
        this.front.readFile(url, (data, mimeType) => {
          const file: HyperFile = { data, mimeType, text: decoder.decode(data) }
          this.fileCache.set(url, file)
          res(file)
        })
      })
    )
  }

  writeFile(data: Uint8Array, mimeType: string): string {
    return this.front.writeFile(data, mimeType)
  }

  create = (props: object = {}): string => {
    return this.front.create(props)
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
