declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
;(self as any).module.paths.push(resolve("./node_modules"))

import QueuedPort from "./QueuedPort"
import { ToCompiler, FromCompiler } from "./Msg"
import fs from "fs"
import elm from "node-elm-compiler"

const port = new QueuedPort<FromCompiler, ToCompiler>(self)
;(self as any).port = port

port.subscribe(receive)

if (!fs.existsSync(".tmp")) {
  fs.mkdirSync(".tmp")
}

function receive(msg: ToCompiler) {
  port.unsubscribe()

  const { url } = msg
  switch (msg.t) {
    case "Compile":
      const source = msg.source.replace(/^module \w+/, "module Subject")

      fs.writeFile("./.tmp/Subject.elm", source, async err => {
        if (err) port.send({ t: "CompileError", url, error: err.message })

        try {
          // Compile via Harness.elm if missing `main` function
          const filename = /^main /.test(source)
            ? "./.tmp/Subject.elm"
            : "./src/elm/Harness.elm"

          const out = await elm.compileToString([filename], {
            output: ".js",
          })

          const output = `
            (new function Wrapper() {
              ${out}
            }).Elm
          `

          port.send({ t: "Compiled", url, output })
          console.log("Sent compiled Elm program")
          port.subscribe(receive)
        } catch (e) {
          port.send({ t: "CompileError", url, error: e.message })
          console.log("Sent Elm compile error")
          console.error(e.message)
          port.subscribe(receive)
        }
      })
      break
  }
}
