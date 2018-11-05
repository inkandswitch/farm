import path from "path"
import webpack from "webpack"
import HtmlWebpackPlugin from "html-webpack-plugin"

const shared: webpack.Configuration = {
  mode: "development",
  context: path.resolve(__dirname),
  devtool: "inline-source-map",
  resolve: {
    extensions: [".js", ".ts", ".elm"],
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        loader: "ts-loader",
        exclude: [/node_modules/],
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

function config(name: string, opts: webpack.Configuration) {
  return Object.assign(
    {},
    shared,
    {
      output: {
        path: path.resolve(__dirname, "dist"),
        filename: `${name}.js`,
      },
    },
    opts,
  )
}

export default [
  config("electron", {
    entry: ["./src/electron"],
    target: "electron-main",
  }),

  config("renderer", {
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
]
