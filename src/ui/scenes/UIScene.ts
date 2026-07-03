export default class UIScene extends Phaser.Scene {
  constructor() {
    super({ key: 'UIScene' })
  }

  create(): void {
    console.log('[UIScene] ready')
  }
}
