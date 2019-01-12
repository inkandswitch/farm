import QueuedPort from "./QueuedPort"

import PseudoWorker from "pseudo-worker"
import xhr from "xmlhttprequest"

if (typeof XMLHttpRequest === "undefined") {
  ;(<any>global).XMLHttpRequest = xhr.XMLHttpRequest
}

export default class FakeWorker<S, R> extends QueuedPort<S, R> {
  worker: Worker

  constructor(url: string, name?: string) {
    const worker = new PseudoWorker(url)
    super(worker, name || "PseudoWorker")
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
