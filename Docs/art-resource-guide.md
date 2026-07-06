# 美术资源制作说明

## 当前策略

- 首版使用自制程序化像素资源，避免来源不明、GPL、CC-BY-SA 或灰盒占位图进入正式资源。
- 资源文件放在 `RiftExpedition/Resources/Assets/`，授权记录在 `assets-manifest.json`。
- 当前 P2 资源覆盖 tileset、四职业角色、野猪、偷猎者、蜘蛛、村长、宝箱和木堆。

## 如何审查

- 地图源文件：`RiftExpedition/Resources/Maps/vertical_slice.tmx`。
- 地图预览：运行 validator 生成到 `Docs/Reports/map-previews/vertical_slice/`。
- 资源清单：检查 `RiftExpedition/Resources/Assets/assets-manifest.json` 中每个条目的 `license`、`source`、`path`。
- 禁止提交文件名或 id 含 `placeholder`、`temp`、`graybox` 的正式资源。

## 后续替换规则

- 可替换为 CC0 资源包，例如专门面向 RPG 的 tileset 和 spritesheet。
- 替换时必须记录来源 URL、license、下载日期和作者。
- 若使用 AI，只用于静态头像、图标或单张补充图；角色行走/攻击动画优先使用成套 spritesheet，避免帧间不一致。
- 文件名和内部 id 使用英文；玩家可见文本使用中文。
