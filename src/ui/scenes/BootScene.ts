export default class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' })
  }

  create(): void {
    this.add
      .text(this.cameras.main.centerX, this.cameras.main.centerY, '加载中...', {
        color: '#ffffff',
      })
      .setOrigin(0.5)

    this.scene.start('BattleScene')
    this.scene.launch('UIScene')
  }
}
