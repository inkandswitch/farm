import express from "express"
import devServer from "webpack-dev-middleware"
import webpack from "webpack"
import config from "../../webpack.config"

const PORT = 4000
const webpackCompiler = webpack(config)
const app = express()

app.use(
  devServer(webpackCompiler, {
    publicPath: "/",
    logLevel: "warn",
    writeToDisk(filename: string): boolean {
      return /(realm|\.worker)\.js$/.test(filename)
    },
  }),
)

app.listen(PORT, () => console.log(`App listening at http://localhost:${PORT}`))
