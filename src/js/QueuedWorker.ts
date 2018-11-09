import QueuedPort from "./QueuedPort"

export default class QueuedWorker<S, R> extends QueuedPort<S, R> {
  worker: Worker

  constructor(url: string, name?: string) {
    const worker = new Worker(url)
    super(worker, name || "Worker")
    this.worker = worker
  }

  close() {
    super.close()
    this.worker.terminate()
  }
}
