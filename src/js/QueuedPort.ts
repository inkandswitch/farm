import QueuedResource from "./QueuedResource"

export interface Port {
  postMessage(msg: any): void
  onmessage: null | ((msg: any) => void)
}

export default class QueuedPort<S, R> extends QueuedResource<S, R> {
  port: Port

  constructor(port: Port) {
    super()
    this.port = port
  }

  connect() {
    this.sendQ.subscribe(msg => {
      this.port.postMessage(msg)
    })

    this.port.onmessage = event => {
      const msg: R = event.data
      this.receiveQ.push(msg)
    }

    return this
  }
}
