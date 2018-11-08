import Socket from "./Socket"
import { Elm } from "../elm/Main"
import * as Msg from "./Msg"
import QueuedWorker from "./QueuedWorker"
import Widget from "./Widget"

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  server = new Socket<Msg.ToServer, Msg.FromServer>(
    "ws://localhost:4000/socket",
  )

  repo = new QueuedWorker<Msg.ToRepo, Msg.FromRepo>("./repo.worker.js")

  elm = Elm.Main.init({
    flags: null,
  })

  widget = new Widget(this.repo)

  start() {
    this.server.connect()

    this.elm.ports.toServer.subscribe(msg => {
      this.server.send(msg as Msg.ToServer)
    })

    this.server.subscribe(msg => {
      const [t, body] = msg
      switch (t) {
        case "Compiled":
          this.elm.ports.fromServer.send(msg)
          this.mount(eval(body))
          break

        default:
          this.elm.ports.fromServer.send(msg)
      }
    })

    this.repo.connect()

    // this.elm.ports.toRepo.subscribe(doc => {
    //   this.repo.send({ t: "Doc", doc })
    // })

    // this.repo.subscribe(msg => {
    //   this.elm.ports.fromRepo.send(msg)
    // })
  }

  mount(result: any) {
    const preview = document.getElementById("preview")
    const elm = Object.values(result)[0]
    if (preview) {
      this.widget.start(elm, preview)
    } else {
      console.log("No preview node!")
    }
  }
}
