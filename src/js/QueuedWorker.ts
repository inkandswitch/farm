import QueuedPort from "./QueuedPort"

export default class QueuedWorker<S, R> extends QueuedPort<S, R> {
  worker: Worker

  constructor(url: string) {
    const worker = new Worker(url)
    super(worker)
    this.worker = worker
  }
}
