import express from "express"
import devServer from "webpack-dev-middleware"
import hot from "webpack-hot-middleware"
import webpack from "webpack"
import config from "../../webpack.config"

import ws from "express-ws"

import Debug from "debug"

Debug.enable("server")

const log = Debug("server")

const PORT = 4000
const webpackCompiler = webpack(config)
const { app } = ws(express())

app.use(
  devServer(webpackCompiler, {
    publicPath: "/",
    logLevel: "warn",
    writeToDisk(filename: string): boolean {
      return /(realm|\.worker)\.js$/.test(filename)
    },
  }),
)

app.use(
  hot(webpackCompiler, {
    path: "/__webpack_hmr",
  }),
)

// app.ws("/socket", (ws, req) => {
//   ws.on("message", data => {
//     const [type, content]: Msg.ToServer = JSON.parse(data.toString())

//     switch (type) {
//       case "Compile":
//         tmp.file({ postfix: ".elm" }, (err, filename, fd) => {
//           if (err) ws.send(["CompileError", err.message])

//           fs.write(fd, content, async err => {
//             if (err) ws.send(["CompileError", err.message])

//             try {
//               const out = await elm.compileToString([filename], {
//                 output: ".js",
//               })

//               const program = `
//                 (new function Wrapper() {
//                   ${out}
//                 }).Elm
//               `

//               ws.send(JSON.stringify(["Compiled", program]))
//               log("Sent compiled Elm program")
//             } catch (e) {
//               ws.send(JSON.stringify(["CompileError", e.message]))
//               log("Sent Elm compile error")
//             }
//           })
//         })
//         break
//     }
//   })
// })

app.listen(PORT, () => console.log(`App listening at http://localhost:${PORT}`))
