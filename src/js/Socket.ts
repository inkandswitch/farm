import Queue from "./Queue"
import QueuedResource from "./QueuedResource"

export default class Socket<S, R> extends QueuedResource<S, R> {
  url: string

  constructor(url: string) {
    super()
    this.url = url
  }

  connect() {
    const socket = new WebSocket(this.url)
    console.log(`Connecting to ${this.url}`)

    socket.onopen = () => {
      this.sendQ.subscribe(msg => {
        socket.send(JSON.stringify(msg))
      })
    }

    socket.onmessage = ev => {
      const msg: R = JSON.parse(ev.data)
      this.receiveQ.push(msg)
    }

    socket.onclose = () => {
      this.sendQ.unsubscribe()
      console.log("Disconnected. Reconnecting in 5s...")
      setTimeout(() => {
        this.connect()
      }, 5000)
    }

    socket.onerror = ev => {
      console.log(ev)
    }

    return this
  }
}
