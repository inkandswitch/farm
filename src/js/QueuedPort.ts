import QueuedResource from "./QueuedResource"

export interface Port {
  postMessage(msg: any): void
  onmessage: null | ((msg: any) => void)
}

export default class QueuedPort<S, R> extends QueuedResource<S, R> {
  port: Port

  constructor(port: Port, name?: string) {
    super(name || "Port")
    this.port = port

    this.sendQ.subscribe(msg => {
      port.postMessage(msg)
    })

    port.onmessage = event => {
      const msg: R = event.data
      this.receiveQ.push(msg)
    }
  }

  close() {
    super.unsubscribe()
    this.sendQ.unsubscribe()
  }
}
