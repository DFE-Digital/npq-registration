const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';
const path = require("path")
const webpack = require("webpack")

module.exports = {
  mode,
  optimization: {
    moduleIds: 'deterministic',
  },
  entry: {
    application: "./app/javascript/application.js"
  },
  module: {
    rules: [
      {
        test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg|ico)$/i,
        use: 'file-loader',
      },
    ],
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    chunkFormat: "module",
    path: path.resolve(__dirname, 'app/assets/builds'),
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    })
  ]
}
