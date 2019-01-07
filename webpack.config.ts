import path from "path"
import webpack from "webpack"
import HtmlWebpackPlugin from "html-webpack-plugin"
import nodeExternals from "webpack-node-externals"
import HardSourcePlugin from "hard-source-webpack-plugin"

const shared: webpack.Configuration = {
  mode: "development",
  context: path.resolve(__dirname),
  devtool: "inline-source-map",
  resolve: {
    extensions: [".js", ".ts", ".elm"],
  },
  externals: [
    nodeExternals({
      whitelist: [/webpack/],
    }),
  ],
  module: {
    rules: [
      {
        test: /\.ts$/,
        loader: "ts-loader",
        exclude: [/realm\/node_modules/],
      },

      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-webpack-loader",
            options: {},
          },
        ],
      },
    ],
  },
}

function config(opts: webpack.Configuration) {
  return Object.assign(
    {},
    shared,
    {
      output: {
        path: path.resolve(__dirname, "dist"),
        filename: `${opts.name}.js`,
        publicPath: "./",
        globalObject: "this",
      },
    },
    opts,
  )
}

export default [
  config({
    name: "electron",
    entry: ["./src/electron"],
    target: "electron-main",
    plugins: [new HardSourcePlugin()],
  }),

  config({
    name: "realm",
    entry: ["./src/js/cli/realm"],
    target: "node",
    plugins: [new HardSourcePlugin()],
  }),

  config({
    name: "renderer",
    entry: ["./src/js"],
    target: "electron-renderer",
    plugins: [
      new HtmlWebpackPlugin({ title: "Realm" }),
      new HardSourcePlugin(),
    ],
  }),

  config({
    name: "repo.worker",
    entry: ["./src/js/repo.worker"],
    target: "electron-renderer",
    plugins: [new HardSourcePlugin()],
  }),

  config({
    name: "compile.worker",
    entry: ["./src/js/compile.worker"],
    target: "electron-renderer",
    plugins: [new HardSourcePlugin()],
  }),
]
