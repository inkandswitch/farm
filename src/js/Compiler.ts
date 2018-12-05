import QueuedWorker from "./QueuedWorker"
import * as Msg from "./Msg"
import Repo from "./Repo"
import { whenChanged } from "./Subscription"

type CompileWorker = QueuedWorker<Msg.ToCompiler, Msg.FromCompiler>

export default class Compiler {
  worker: CompileWorker
  repo: Repo
  docUrls: Set<String> = new Set()

  constructor(repo: Repo, url: string) {
    this.repo = repo
    this.worker = new QueuedWorker(url)

    this.worker.subscribe(msg => {
      const handle = this.repo.open(msg.url)

      handle.change((state: any) => {
        switch (msg.t) {
          case "Compiled":
            if (state.error) state.error = ""
            if (state.hypermergeFsDiagnostics) state.hypermergeFsDiagnostics = null
            if (getJsSource(state) !== msg.output) {
              state["Source.js"] = msg.output
            }
            break

          case "CompileError":
            state.error = msg.error
            state.hypermergeFsDiagnostics = this.produceDiagnosticsFromMessage(msg.error)
            break
        }
      })

      handle.close()
    })
  }

  produceDiagnosticsFromMessage(error: string) {
    const jsonString = error.substring(error.indexOf("\n") + 1)
    const json = JSON.parse(jsonString)

    const nestedProblems = json.errors.map((error: any) => 
      error.problems.map((problem: any) =>{
        const messageLines = problem.message.filter( (_: any, idx: number) => (idx % 2 === 0))
        const message = messageLines.join("\n")

        return {
          severity: "error",
          message,
          startLine: problem.region.start.line,
          startColumn: problem.region.start.column,
          endLine: problem.region.end.line,
          endColumn: problem.region.end.column
        }
      })
    )

    console.log(nestedProblems)
    return { "Source.elm": [].concat(...nestedProblems) } 
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

  terminate() {
    this.worker.terminate()
  }
}

const getElmSource = (doc: any): string | undefined =>
  doc["Source.elm"] || doc["source.elm"]

const getJsSource = (doc: any): string | undefined =>
  doc["Source.js"] || doc["source.js"]
