import express from "express"
import devServer from "webpack-dev-middleware"
import hot from "webpack-hot-middleware"
import webpack from "webpack"
import config from "../../webpack.config"
import elm from "node-elm-compiler"
import ws from "express-ws"
import tmp from "tmp"
import fs from "fs"
import * as Msg from "../js/Msg"
import Debug from "debug"

Debug.enable("server")

const log = Debug("server")

const PORT = 4000
const webpackCompiler = webpack(config)
const { app } = ws(express())

app.use(
  devServer(webpackCompiler, {
    publicPath: "/",
  }),
)

app.use(hot(webpackCompiler))

app.ws("/socket", (ws, req) => {
  ws.on("message", data => {
    const [type, content]: Msg.ToServer = JSON.parse(data.toString())

    switch (type) {
      case "Compile":
        tmp.file({ postfix: ".elm" }, (err, filename, fd) => {
          if (err) ws.send(["CompileError", err.message])

          fs.write(fd, content, async err => {
            if (err) ws.send(["CompileError", err.message])

            try {
              const out = await elm.compileToString([filename], {
                output: ".js",
              })
              console.log(out)
              ws.send(JSON.stringify(["Compiled", out]))
              log("Sent compiled Elm program")
            } catch (e) {
              ws.send(JSON.stringify(["CompileError", e.message]))
              log("Sent Elm compile error")
            }
          })
        })
        break
    }
  })
})

app.listen(PORT, () => console.log(`App listening at http://localhost:${PORT}`))
