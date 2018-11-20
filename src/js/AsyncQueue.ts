import Debug, { IDebugger } from "debug"

export default class AsyncQueue<T> {
  queue: T[] = []
  subscription?: (item: T) => void
  log: IDebugger

  constructor(name: string = "unknown") {
    this.log = Debug(`queue:${name}`)
  }

  push = (item: T): this => {
    if (this.subscription) {
      this.log("push subbed", item)
      this.subscription(item)
      delete this.subscription
    } else {
      this.log("push queued", item)
      this.queue.push(item)
    }
    return this
  }

  take = (subscriber: (item: T) => void): this => {
    if (this.subscription) {
      throw new Error("only one subscriber at a time to a queue")
    }

    this.log("subscribed")

    if (this.queue.length) {
      subscriber(this.queue.shift()!)
    } else {
      this.subscription = subscriber
    }

    return this
  }

  unsubscribe = (): this => {
    this.log("unsubscribed")

    this.subscription = undefined
    return this
  }
}
