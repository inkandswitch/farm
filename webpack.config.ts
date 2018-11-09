import path from "path"
import webpack from "webpack"
import HtmlWebpackPlugin from "html-webpack-plugin"
import nodeExternals from "webpack-node-externals"

interface NamedConfig extends webpack.Configuration {
  name: string
}

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
          { loader: "elm-hot-webpack-loader" },
          {
            loader: "elm-webpack-loader",
            options: {},
          },
        ],
      },
    ],
  },
}

function config(opts: NamedConfig) {
  return Object.assign(
    {},
    shared,
    {
      output: {
        path: path.resolve(__dirname, "dist"),
        filename: `${opts.name}.js`,
        publicPath: "/",
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
  }),

  config({
    name: "renderer",
    entry: ["webpack-hot-middleware/client", "./src/js"],
    target: "electron-renderer",
    plugins: [
      new webpack.HotModuleReplacementPlugin({}),
      new HtmlWebpackPlugin(),
    ],
    devServer: {
      hot: true,
    },
  }),

  config({
    name: "repo.worker",
    entry: ["webpack-hot-middleware/client", "./src/js/repo.worker"],
    target: "electron-renderer",
    plugins: [new webpack.HotModuleReplacementPlugin({})],
    devServer: {
      hot: true,
    },
  }),

  config({
    name: "compile.worker",
    entry: ["webpack-hot-middleware/client", "./src/js/compile.worker"],
    target: "electron-renderer",
    plugins: [new webpack.HotModuleReplacementPlugin({})],
    devServer: {
      hot: true,
    },
  }),

  config({
    name: "nettest",
    entry: ["./src/nettest"],
    target: "node",
  }),

  config({
    name: "doccat",
    entry: ["./src/doccat"],
    target: "node",
  }),
]
