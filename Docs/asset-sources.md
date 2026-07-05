# 首章资源来源

生成日期：2026-07-06

本项目首章资源采用自制程序化资源作为正式 MVP 美术与音频，不使用灰盒、占位图、GPL、CC-BY-SA 或来源不明素材。所有正式资源均登记在 `RiftExpedition/Resources/Assets/assets-manifest.json`，授权为 `self-made`。

## 目录

- `RiftExpedition/Resources/Assets/Tilesets/`：首章村庄、野外、洞穴 tileset。
- `RiftExpedition/Resources/Assets/Sprites/`：P2 竖切使用的独立角色/敌人/物件 sprite。
- `RiftExpedition/Resources/Assets/Characters/`：首章角色 spritesheet，覆盖玩家职业、村民、人类敌人、动物和污染怪物。
- `RiftExpedition/Resources/Assets/Icons/`：技能、消耗品、宝箱、元素矿图标。
- `RiftExpedition/Resources/Assets/Audio/`：UI、战斗、探索、洞穴音效和环境循环。音频沿用现有 App 加载路径 `Assets/Audio`。

## 授权记录

| 资源组 | 来源 | License | 作者 |
| --- | --- | --- | --- |
| chapter1 village/wilds/cave tilesets | 本项目本地程序化绘制 | self-made | Rift Expedition project |
| party/village/human/beast character spritesheets | 本项目本地程序化绘制 | self-made | Rift Expedition project |
| skill/item icons | 本项目本地程序化绘制 | self-made | Rift Expedition project |
| WAV cues and ambience loops | 本项目本地程序化合成 | self-made | Rift Expedition project |

## 替换规则

后续如替换为外部资源，只允许 CC0 或等价可商用免署名授权，并必须同步更新：

1. `RiftExpedition/Resources/Assets/assets-manifest.json`
2. 本文档的来源、作者、下载日期和 license
3. `rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources` 校验结果
