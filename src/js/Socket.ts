import Queue from "./Queue"
import QueuedResource from "./QueuedResource"

export default class Socket<S, R> extends QueuedResource<S, R> {
  url: string
  socket?: WebSocket

  constructor(url: string) {
    super("Socket")
    this.url = url
    this.connect()
  }

  connect() {
    const socket = new WebSocket(this.url)
    this.socket = socket
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
  }

  close() {
    this.socket && this.socket.close()
  }
}
