import { BattleScene } from "../ui/BattleScene";

declare const Phaser: any;

const config = {
  type: Phaser.AUTO,
  parent: "game",
  width: 448,
  height: 320,
  backgroundColor: "#101014",
  pixelArt: true,
  roundPixels: true,
  antialias: false,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  scene: [BattleScene],
};

new Phaser.Game(config);
