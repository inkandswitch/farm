import Repo from "./Repo"
import Handle from "hypermerge/dist/Handle"
import { whenChanged } from "./Subscription"
import Compiler from "./Compiler"
import ElmGizmo from "./ElmGizmo"

export default class Bot {
  static set repo(repo: Repo) {
    ElmGizmo.repo = repo
  }

  static set compiler(compiler: Compiler) {
    ElmGizmo.compiler = compiler
  }

  static set selfDataUrl(selfDataUrl: string) {
    ElmGizmo.selfDataUrl = selfDataUrl
  }

  gizmo?: ElmGizmo
  source?: Handle<any>
  codeUrl: string
  dataUrl: string

  constructor(codeUrl: string, dataUrl: string) {
    this.codeUrl = codeUrl
    this.dataUrl = dataUrl
  }

  start() {
    this.source = ElmGizmo.repo.open(this.codeUrl)
    ElmGizmo.compiler.add(this.codeUrl)

    this.source.subscribe(
      whenChanged(getJsSource, source => {
        this.remount(toElm(eval(source)))
      }),
    )
  }

  stop() {
    if (this.source) {
      this.source.close()
      delete this.source
    }
  }

  remount(elm: any) {
    this.unmount()
    this.mount(elm)
  }

  mount(elm: any) {
    this.gizmo = new ElmGizmo(null, elm, this.codeUrl, this.dataUrl)
  }

  unmount() {
    if (this.gizmo) {
      this.gizmo.close()
      delete this.gizmo
    }
  }
}

const getJsSource = (doc: any): string | undefined =>
  doc["Source.js"] || doc["source.js"]

function toElm(code: string) {
  return Object.values(eval(code))[0]
}
