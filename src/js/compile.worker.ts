declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
;(self as any).module.paths.push(resolve("./node_modules"))

import QueuedPort from "./QueuedPort"
import { ToCompiler, FromCompiler } from "./Msg"
import tmp from "tmp"
import fs from "fs"
import elm from "node-elm-compiler"

const port = new QueuedPort<FromCompiler, ToCompiler>(self)
;(self as any).port = port

port.subscribe(msg => {
  const { url } = msg
  switch (msg.t) {
    case "Compile":
      tmp.file({ postfix: ".elm" }, (err, filename, fd) => {
        if (err) port.send({ t: "CompileError", url, error: err.message })

        fs.write(fd, msg.source, async err => {
          if (err) port.send({ t: "CompileError", url, error: err.message })

          try {
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
          } catch (e) {
            port.send({ t: "CompileError", url, error: e.message })
            console.log("Sent Elm compile error")
            console.error(e.message)
          }
        })
      })
      break
  }
})
