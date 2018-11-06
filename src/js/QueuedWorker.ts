import Queue from "./Queue"
import QueuedResource from "./QueuedResource"

export default class QueuedWorker<S, R> extends QueuedResource<S, R> {
  url: string

  constructor(url: string) {
    super()
    this.url = url
  }

  connect() {
    const worker = new Worker(this.url)

    this.sendQ.subscribe(msg => {
      worker.postMessage(msg)
    })

    worker.onmessage = event => {
      const msg: R = event.data
      this.receiveQ.push(msg)
    }

    return this
  }
}
