import QueuedWorker from "./QueuedWorker"
import * as Msg from "./Msg"
import { RepoFrontend } from "hypermerge"
import { whenChanged } from "./Subscription"

type CompileWorker = QueuedWorker<Msg.ToCompiler, Msg.FromCompiler>

export default class Compiler {
  worker: CompileWorker = new QueuedWorker("compile.worker.js")
  repo: RepoFrontend
  docIds: Set<String> = new Set()

  constructor(repo: RepoFrontend) {
    this.repo = repo

    this.worker.subscribe(msg => {
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

      handle.close()
    })
  }

  add(id: string): this {
    if (this.docIds.has(id)) return this

    this.docIds.add(id)

    this.repo.open(id).subscribe(
      whenChanged(getElmSource, source => {
        this.worker.send({
          t: "Compile",
          id,
          source,
        })
      }),
    )

    return this
  }
}

const getElmSource = (doc: any): string | undefined => doc["source.elm"]
