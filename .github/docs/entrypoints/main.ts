import BootScene from '@ui/scenes/BootScene'
import BattleScene from '@ui/scenes/BattleScene'
import UIScene from '@ui/scenes/UIScene'

const zoom = Math.max(1, Math.floor(Math.min(window.innerWidth / 448, window.innerHeight / 320)))

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game-root',
  width: 448,
  height: 320,
  pixelArt: true,
  roundPixels: true,
  antialias: false,
  scale: { mode: Phaser.Scale.FIT, zoom },
  scene: [BootScene, BattleScene, UIScene],
})

;(window as any).game = game
