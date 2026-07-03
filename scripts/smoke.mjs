import { access, readFile } from "node:fs/promises";

await access("index.html");
await access("vendor/phaser.min.js");
await access("dist/main.js");

const html = await readFile("index.html", "utf8");
const bundle = await readFile("dist/main.js", "utf8");

if (!html.includes("./vendor/phaser.min.js") || !html.includes("./dist/main.js")) {
  throw new Error("index.html does not load the Phaser vendor file and game bundle");
}

if (!bundle.includes("BattleScene")) {
  throw new Error("game bundle does not contain the battle scene");
}

console.log("smoke ok");
