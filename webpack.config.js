const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';
const path = require("path")
const webpack = require("webpack")

module.exports = {
  mode,
  devtool: 'source-map',
  optimization: {
    moduleIds: 'deterministic',
  },
  entry: {
    application: "./app/javascript/application.js",
    mermaid: "./app/javascript/mermaid.js",
    "swagger-ui": "./app/javascript/swagger-ui.js",
  },
  module: {
    rules: [
      {
        test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg|ico)$/i,
        use: 'file-loader',
      },
      {
        test: /\.js$/,
        exclude: /node_modules\/(?!(accessible-autocomplete)\/).*/, // Exclude all node_modules except accessible-autocomplete
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
          },
        },
      },
      {
        test: /\.scss$/, // Add this rule for SCSS files
        use: [
          'style-loader', // Injects styles into DOM
          'css-loader', // Turns CSS into CommonJS
          'sass-loader' // Compiles Sass to CSS
        ],
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
};
