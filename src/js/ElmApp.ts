import QueuedResource from "./QueuedResource"

export interface ElmApp {
  ports: {
    output: {
      subscribe(fn: Function): void
      unsubscribe(fn: Function): void
    }
    input: {
      send(msg: any): void
    }
  }
}

export default class QueuedElmApp extends QueuedResource<any, any> {
  app: ElmApp

  constructor(app: ElmApp, name?: string) {
    super(name || "ElmApp")
    this.app = app

    app.ports.output.subscribe(this.receiveQ.push)

    this.sendQ.subscribe(msg => {
      app.ports.input.send(msg)
    })
  }

  close() {
    this.sendQ.unsubscribe()
    this.app.ports.output.unsubscribe(this.receiveQ.push)
  }
}
