export default class BattleScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BattleScene' })
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#1d1f2b')
    console.log('[BattleScene] ready')
  }
}
