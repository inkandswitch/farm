import Queue from "./Queue"

export default class Socket<SendMsg, ReceiveMsg> {
  url: string
  sendQ = new Queue<SendMsg>()
  receiveQ = new Queue<ReceiveMsg>()

  constructor(url: string) {
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
      const msg: ReceiveMsg = JSON.parse(ev.data)
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

  send(msg: SendMsg) {
    this.sendQ.push(msg)
  }
}
