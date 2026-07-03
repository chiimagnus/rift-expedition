// ponytail: 没有安装 Phaser 包/类型（从本地 vendor/phaser.min.js 全局引入），这里用宽松 any 声明全局变量兜底；
// 升级路径：若后续允许联网安装，改用 `npm i -D phaser` 并删除此文件，改为 `import type Phaser from 'phaser'`。
declare const Phaser: any
