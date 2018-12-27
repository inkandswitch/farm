import QueuedPort from "./QueuedPort"

var PseudoWorker = require("pseudo-worker")
const xhr = require("xmlhttprequest")
;(<any>global).XMLHttpRequest = xhr.XMLHttpRequest

export default class QueuedWorker<S, R> extends QueuedPort<S, R> {
  worker: Worker

  constructor(url: string, name?: string) {
    const worker = new PseudoWorker(url)
    super(worker, name || "Worker")
    this.worker = worker

    if (process && process.on) {
      // Ensure the worker is terminated in node
      process.on("SIGTERM", () => this.close())
      process.on("SIGINT", () => this.close())
    }
  }

  close() {
    this.terminate()
  }

  terminate() {
    super.close()
    this.worker.terminate()
  }
}
