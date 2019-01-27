declare const self: DedicatedWorkerGlobalScope
import { resolve } from "path"
import elmFormat from "elm-format"

if ((self as any).module) {
  ;(self as any).module.paths.push(resolve("./node_modules"))
}

import QueuedPort from "./QueuedPort"
import { ToCompiler, FromCompiler } from "./Msg"
import fs from "fs"
import elm from "node-elm-compiler"
import AsyncQueue from "./AsyncQueue"
import { lock } from "proper-lockfile"
import { promisify } from "util"
import { sha1 } from "./Digest"
import { spawn } from "child_process"

const writeFile = promisify(fs.writeFile)

const port = new QueuedPort<FromCompiler, ToCompiler>(self)
;(self as any).port = port

const workQ = new AsyncQueue<ToCompiler>("compiler:workQ")

workQ.take(work)

port.subscribe(workQ.push)

if (!fs.existsSync(".tmp")) {
  fs.mkdirSync(".tmp")
}

async function work(msg: ToCompiler) {
  const { url } = msg
  switch (msg.t) {
    case "Compile":
      const { sourceHash } = msg
      const source = msg.source.replace(/^module \w+/, "module Source")

      const sourceFile = "./.tmp/Source.elm"
      const lockOpts = { stale: 5000, retries: 5, realpath: false }

      const release = await lock(sourceFile, lockOpts)

      function done() {
        release()
        workQ.take(work)
      }

      try {
        await writeFile(sourceFile, source)

        // TODO: support other config types
        const configContents = [
          "module Config exposing (..)",
          "",
          ...Object.keys(msg.config).map(k => `${k} = "${msg.config[k]}"`),
          "",
        ].join("\n")

        await writeFile("./.tmp/Config.elm", configContents)

        const filename = getFilename(source)
        const out = await elm.compileToString([filename], {
          output: ".js",
          report: "json",
          debug: msg.debug,
        })

        if (msg.persist) {
          const [, name = "Unknown"] = msg.source.match(/^module (\w+)/) || []
          await saveElmCode(`./src/elm/examples/${name}.elm`, msg.source)
        }

        const output = `
              (new function Wrapper() {
                ${out}
              }).Elm
            `

        const outputHash = await sha1(output)

        port.send({ t: "Compiled", url, output, sourceHash, outputHash })
        console.log(`Elm compile success: ${url}`)
        return done()
      } catch (err) {
        port.send({ t: "CompileError", url, sourceHash, error: err.message })
        console.log(`Elm compile error: ${url}`)
        return done()
      }
      break
  }
}

function getFilename(source: string): string {
  return /^main /m.test(source)
    ? "./.tmp/Source.elm" // Compile directly if `main` function exists
    : /^gizmo /m.test(source)
      ? "./src/elm/Harness.elm" // Compile via Harness if `gizmo` function exists
      : "./src/elm/BotHarness.elm" // Otherwise, compile via BotHarness
}

function saveElmCode(filename: string, source: string): Promise<void> {
  return new Promise((res, rej) => {
    const format = spawn(elmFormat.paths["elm-format"], [
      "--stdin",
      "--yes",
      "--output",
      filename,
    ])
    format.stdin.write(source)
    format.stdin.end()
  })
}
