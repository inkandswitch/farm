import { RepoFrontend } from "hypermerge"
import * as Compile from "./Compile"
import { whenChanged } from "./Subscription"
import * as Widget from "./Widget"

export default class Registry {
  repo: RepoFrontend
  entries = new Map<string, Entry>()
  compiler = Compile.worker("compile.worker.js")

  constructor(repo: RepoFrontend) {
    this.repo = repo

    this.compiler.subscribe(msg => {
      const handle = this.repo.open(msg.id)

      handle.change((state: any) => {
        switch (msg.t) {
          case "Compiled":
            if (state.error) state.error = ""
            if (state["source.js"] !== msg.output) {
              state["source.js"] = msg.output
            }
            break

          case "CompileError":
            state.error = msg.error
            break
        }
      })

      handle.cleanup()
    })
  }

  add(id: string): void {
    const handle = this.repo.open(id)

    handle.subscribe(
      whenChanged(getElmSource, source => {
        this.compiler.send({
          t: "Compile",
          id,
          source,
        })
      }),
    )

    this.entries.set(id, new Entry(this.repo, id))
  }
}

export class Entry {
  widget?: any

  constructor(repo: RepoFrontend, id: string) {
    const handle = repo.open(id)
    handle.subscribe(
      whenChanged(getJsSource, (source, doc) => {
        if (this.widget) {
          this.widget.upgrade(source)
        } else {
          this.widget = Widget.create(repo, doc.name, source)
        }
      }),
    )
  }
}

const getElmSource = (doc: any): string | undefined => doc["source.elm"]
const getJsSource = (doc: any): string | undefined => doc["source.js"]
