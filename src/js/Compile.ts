import QueuedWorker from "./QueuedWorker"
import * as Msg from "./Msg"

export type Compiler = QueuedWorker<Msg.ToCompiler, Msg.FromCompiler>

export function worker(url: string): Compiler {
  return new QueuedWorker(url)
}
