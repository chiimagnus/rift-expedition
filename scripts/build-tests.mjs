import { readdir, rm } from "node:fs/promises";
import { join } from "node:path";
import { build } from "esbuild";

await rm("dist-tests", { force: true, recursive: true });

const tests = (await readdir("tests"))
  .filter((name) => name.endsWith(".test.ts"))
  .map((name) => join("tests", name));

await Promise.all(
  tests.map((entryPoint) =>
    build({
      entryPoints: [entryPoint],
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node24",
      sourcemap: true,
      outfile: join("dist-tests", entryPoint.replace(/^tests\//, "").replace(/\.ts$/, ".js")),
    }),
  ),
);
