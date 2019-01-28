import path from "path"
import webpack from "webpack"
import HtmlPlugin from "html-webpack-plugin"
import CopyPlugin from "copy-webpack-plugin"
import nodeExternals from "webpack-node-externals"
import HardSourcePlugin from "hard-source-webpack-plugin"

const cacheDirectory = undefined //path.resolve(__dirname, ".cache")

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
        exclude: [/farm\/node_modules/],
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
    plugins: [new HardSourcePlugin({ cacheDirectory })],
  }),

  config({
    name: "farm",
    entry: ["./src/js/cli/farm"],
    target: "node",
    plugins: [new HardSourcePlugin({ cacheDirectory })],
  }),

  config({
    name: "renderer",
    entry: ["./src/js"],
    target: "electron-renderer",
    plugins: [
      new HtmlPlugin({ title: "Farm" }),
      new HardSourcePlugin({ cacheDirectory }),
    ],
  }),

  config({
    name: "repo.worker",
    entry: ["./src/js/repo.worker"],
    target: "electron-renderer",
    plugins: [new HardSourcePlugin({ cacheDirectory })],
  }),

  config({
    name: "compile.worker",
    entry: ["./src/js/compile.worker"],
    target: "electron-renderer",
    plugins: [new HardSourcePlugin({ cacheDirectory })],
  }),

  config({
    name: "hypermerge-devtools/main",
    entry: ["./src/hypermerge-devtools/main"],
    target: "web",
    plugins: [
      new HtmlPlugin({
        title: "Hypermerge 1",
        filename: "hypermerge-devtools/main.html",
      }),
      new CopyPlugin([
        {
          from: "./src/hypermerge-devtools/manifest.json",
          to: "hypermerge-devtools/",
        },
      ]),
      new HardSourcePlugin({ cacheDirectory }),
    ],
  }),

  config({
    name: "hypermerge-devtools/panel",
    entry: ["./src/hypermerge-devtools/panel"],
    target: "web",
    plugins: [
      new HtmlPlugin({
        title: "Hypermerge 2",
        filename: "hypermerge-devtools/panel.html",
      }),
      new HardSourcePlugin({ cacheDirectory }),
    ],
  }),
]
