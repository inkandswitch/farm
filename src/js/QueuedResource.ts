import Queue from "./Queue"

export default abstract class QueuedResource<SendMsg, ReceiveMsg> {
  sendQ = new Queue<SendMsg>()
  receiveQ = new Queue<ReceiveMsg>()

  abstract connect(): this

  send = this.sendQ.push
  subscribe = this.receiveQ.subscribe
  unsubscribe = this.receiveQ.unsubscribe
}
