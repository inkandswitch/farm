import QueuedResource from "./QueuedResource"

export interface Ports {
  output: {
    subscribe(fn: Function): void
    unsubscribe(fn: Function): void
  }
  input: {
    send(msg: any): void
  }
}

export interface ElmApp {
  ports?: Ports
}

export default class QueuedElmApp extends QueuedResource<any, any> {
  app: ElmApp
  ports?: Ports

  constructor(app: ElmApp, name?: string) {
    super(name || "ElmApp")

    const { ports } = app

    this.app = app
    this.ports = ports

    if (ports) {
      ports.output.subscribe(this.receiveQ.push)

      this.sendQ.subscribe(msg => {
        ports.input.send(msg)
      })
    }
  }

  close() {
    this.sendQ.unsubscribe()
    this.ports && this.ports.output.unsubscribe(this.receiveQ.push)
  }
}
