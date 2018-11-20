import QueuedWorker from "./QueuedWorker"
import * as Msg from "./Msg"
import Repo from "./Repo"
import { whenChanged } from "./Subscription"

type CompileWorker = QueuedWorker<Msg.ToCompiler, Msg.FromCompiler>

export default class Compiler {
  worker: CompileWorker = new QueuedWorker("compile.worker.js")
  repo: Repo
  docUrls: Set<String> = new Set()

  constructor(repo: Repo) {
    this.repo = repo

    this.worker.subscribe(msg => {
      const handle = this.repo.open(msg.url)

      handle.change((state: any) => {
        switch (msg.t) {
          case "Compiled":
            if (state.error) state.error = ""
            if (getJsSource(state) !== msg.output) {
              state["Source.js"] = msg.output
            }
            break

          case "CompileError":
            state.error = msg.error
            break
        }
      })

      handle.close()
    })
  }

  add(url: string): this {
    if (this.docUrls.has(url)) return this

    this.docUrls.add(url)

    this.repo.open(url).subscribe(
      whenChanged(getElmSource, source => {
        this.worker.send({
          t: "Compile",
          url,
          source,
        })
      }),
    )

    return this
  }
}

const getElmSource = (doc: any): string | undefined =>
  doc["Source.elm"] || doc["source.elm"]

const getJsSource = (doc: any): string | undefined =>
  doc["Source.js"] || doc["source.js"]
