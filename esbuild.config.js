const esbuild = require("esbuild");

// Mirror the old webpack behaviour: anything that is not an explicit
// development build is treated as production (minified).
const isDevelopment = process.env.NODE_ENV === "development";
const watch = process.argv.includes("--watch");

const config = {
  entryPoints: [
    "app/javascript/application.js",
    "app/javascript/swagger-ui.js",
  ],
  bundle: true,
  outdir: "app/assets/builds",
  publicPath: "/assets",
  sourcemap: true,
  minify: !isDevelopment,
  target: ["es2019"],
  logLevel: "info",
};

async function run() {
  if (watch) {
    const context = await esbuild.context(config);
    await context.watch();
    console.log("esbuild is watching for changes...");
  } else {
    await esbuild.build(config);
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
