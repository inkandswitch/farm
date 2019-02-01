import { RepoFrontend } from "hypermerge/dist/RepoFrontend"
import { Handle } from "hypermerge/dist/Handle"
import QueuedWorker from "./QueuedWorker"
import { validateDocURL } from "hypermerge/dist/Metadata"
import * as Base58 from "bs58"
import * as URL from "url"
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
  registry?: object
  registryHandle?: Handle<any>

  constructor(url: string) {
    this.front = new RepoFrontend()
    this.fileCache = new Map()

    // Swap to allow utp-native usage:
    this.worker = new QueuedWorker(url)
    // this.worker = new FakeWorker(url)

    this.worker.subscribe(this.front.receive)
    this.front.subscribe(this.worker.send)
  }

  async setRegistry(url: string): Promise<any> {
    if (this.registryHandle) {
      this.registryHandle.close()
      delete this.registryHandle
    }

    const registry = await this.read(url)
    this.registry = registry

    this.registryHandle = this.open(url).subscribe(newRegistry => {
      this.registry = newRegistry
    })
    return registry
  }

  async readFile(origUrl: string): Promise<HyperFile> {
    const url = origUrl.replace(":///", ":/")
    return (
      this.fileCache.get(url) ||
      new Promise<HyperFile>(res => {
        this.front.readFile(this.resolveUrl(url), (data, mimeType) => {
          const file: HyperFile = { data, mimeType, text: decoder.decode(data) }
          this.fileCache.set(url, file)
          res(file)
        })
      })
    )
  }

  writeFile(data: Uint8Array, mimeType: string): string {
    return this.front.writeFile(data, mimeType).replace(":/", ":///")
  }

  create = (props: object = {}): string => {
    return this.front.create(props)
  }

  open = <T>(url: string): Handle<T> => {
    return this.front.open(this.resolveUrl(url))
  }

  read<T>(url: string): Promise<T> {
    return new Promise(res => this.once(url, res))
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
      .open(this.resolveUrl(url))
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
    return this.front.fork(this.resolveUrl(url))
  }

  // hypermerge:/registry/key -> hypermerge:/abc123
  resolveUrl(url: string): string {
    // console.log("Resolving url:", url)
    const { path } = URL.parse(url)
    if (!path) throw new Error("No path in this url")

    const keys = path
      .slice(1)
      .split("/")
      .filter(key => key)

    const [id] = keys

    if (isValidId(id)) {
      // console.log("No resolution needed:", url)
      return url
    }

    if (!this.registry) throw new Error("Registry has not loaded")

    let content: any = this.registry

    keys.forEach(key => {
      if (typeof content !== "object" || !(key in content))
        throw new Error(`Registry could not resolve ${url}`)
      content = content[key]
    })
    // console.log("Resolved", url, "to", content)
    return content
  }

  terminate() {
    if (this.registryHandle) this.registryHandle.close()
    this.worker.terminate()
  }
}

function isValidId(id: string): boolean {
  try {
    const buffer = Base58.decode(id)
    return buffer.length === 32
  } catch {
    return false
  }
}
