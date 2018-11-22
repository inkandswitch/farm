import Queue from "./Queue"

export default abstract class QueuedResource<SendMsg, ReceiveMsg> {
  sendQ: Queue<SendMsg>
  receiveQ: Queue<ReceiveMsg>

  constructor(name: string) {
    this.sendQ = new Queue(`${name}:sendQ`)
    this.receiveQ = new Queue(`${name}:receiveQ`)
  }

  send = (item: SendMsg): this => {
    this.sendQ.push(item)
    return this
  }

  subscribe = (subscriber: (item: ReceiveMsg) => void): this => {
    this.receiveQ.subscribe(subscriber)
    return this
  }

  unsubscribe(): this {
    this.receiveQ.unsubscribe()
    return this
  }

  abstract close(): void
}
