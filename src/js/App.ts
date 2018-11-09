import Socket from "./Socket"
import { Elm } from "../elm/Main"
import * as Msg from "./Msg"
import Widget from "./Widget"
import * as Repo from "./Repo"
import { readFileSync } from "fs"
import path from "path"

// make the web worker thread-safe:
import Registry from "./Registry"
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  server = new Socket<Msg.ToServer, Msg.FromServer>(
    "ws://localhost:4000/socket",
  )

  repo = Repo.worker("./repo.worker.js")
  rootId: string = localStorage.rootId || this.createRoot()
  registry = new Registry(this.repo)

  start() {
    this.registry.add("root", this.rootId)

    this.server.connect()

    // this.server.subscribe(msg => {
    //   const [t, body] = msg
    //   switch (t) {
    //     case "Compiled":
    //       this.elm.ports.fromServer.send(msg)
    //       this.mount(eval(body))
    //       break

    //     default:
    //       this.elm.ports.fromServer.send(msg)
    //   }
    // })
  }

  createRoot(): string {
    const id = this.repo.create()
    const handle = this.repo.open(id)
    handle.change((doc: any) => {
      doc["source.elm"] = ROOT_SOURCE_CODE
    })
    handle.cleanup()
    return id
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

const ROOT_SOURCE_CODE = readFileSync(
  path.resolve(__dirname, "../elm/Example.elm"),
)
