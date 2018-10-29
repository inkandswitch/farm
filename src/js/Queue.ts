export default class Queue<T> {
  queue: T[] = []
  subscription?: (item: T) => void

  push = (item: T): this => {
    if (this.subscription) {
      this.subscription(item)
    } else {
      this.queue.push(item)
    }
    return this
  }

  subscribe = (subscriber: (item: T) => void): this => {
    if (this.subscription) {
      throw new Error("only one subscriber at a time to a queue")
    }

    this.subscription = subscriber

    for (const item of this.queue) {
      subscriber(item)
    }
    this.queue = []
    return this
  }

  unsubscribe = (): this => {
    this.subscription = undefined
    return this
  }
}
