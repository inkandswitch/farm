import Socket from "./Socket"
import { Elm } from "../elm/Main"
import * as Msg from "./Msg"

export default class App {
  server = new Socket<Msg.ToServer, Msg.FromServer>(
    "ws://localhost:4000/socket",
  )
  elm = Elm.Main.init({
    flags: null,
  })

  start() {
    this.server.connect()

    this.elm.ports.toServer.subscribe(msg => {
      this.server.send(msg as Msg.ToServer)
    })

    this.server.receiveQ.subscribe(msg => {
      this.elm.ports.fromServer.send(msg)
    })
  }
}
