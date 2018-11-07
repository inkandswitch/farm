import Socket from "./Socket"
import { Elm } from "../elm/Main"
import * as Msg from "./Msg"
import QueuedWorker from "./QueuedWorker"

export default class App {
  server = new Socket<Msg.ToServer, Msg.FromServer>(
    "ws://localhost:4000/socket",
  )

  repo = new QueuedWorker<Msg.ToRepo, Msg.FromRepo>("repo.worker.js")

  elm = Elm.Main.init({
    flags: null,
  })

  start() {
    this.server.connect()

    this.elm.ports.toServer.subscribe(msg => {
      this.server.send(msg as Msg.ToServer)
    })

    this.server.subscribe(msg => {
      this.elm.ports.fromServer.send(msg)
    })

    this.repo.connect()

    this.elm.ports.toRepo.subscribe(doc => {
      this.repo.send({ t: "Doc", doc })
    })

    this.repo.subscribe(msg => {
      this.elm.ports.fromRepo.send(msg)
    })
  }
}
