# 美术与音频资源规范

本文档合并原 `asset-policy.md` / `asset-sources.md` / `art-resource-guide.md` 三份，作为资源授权、来源登记与替换的单一事实来源。所有正式资源以 `RiftExpedition/Resources/Assets/assets-manifest.json` 为准，本文档不逐条重复罗列，只登记资源组与规则。

## 1. 授权契约（Policy）

正式游戏资源必须登记在 `RiftExpedition/Resources/Assets/assets-manifest.json`。

### Manifest 字段

- `id`：稳定英文 id
- `path`：相对 `RiftExpedition/Resources` 的路径
- `type`：资源类型，如 `tileset`、`sprite`、`icon`、`audio`
- `source`：来源 URL 或本地创建说明
- `license`：`CC0` / `self-made` / `ai-static` 之一
- `downloadedAt`：ISO 日期字符串
- `author`：作者或生成器说明

### 允许的 License

- `CC0`
- `self-made`
- `ai-static`

GPL、CC-BY-SA、未知或缺失 license 一律不允许用于正式资源。正式 id 不得包含 `placeholder`、`temp`、`graybox`。主分支不得提交灰盒占位图作为正式资源；不可避免的临时调试资源必须以 `debug-only` 命名并在合并前移除。

## 2. 当前来源登记（Sources）

首章资源采用自制程序化资源作为正式 MVP 美术与音频，license 均为 `self-made`，逐条详见 manifest。

### 溯源说明（Provenance）

所有登记为 `self-made` 的正式资源均为本项目仓库内程序化生成的产物（脚本化像素绘制 / 合成），不基于任何第三方素材包或网络下载内容二次加工、不涉及外部授权链条。仓库自身以 git 记录每次资源新增/替换的提交历史，作为可追溯的生成/变更记录；`assets-manifest.json` 中的 `downloadedAt` 字段对这批资源代表“生成/入库日期”，而非外部下载时间。若日后引入非程序化来源（例如美术外包或 AI 生成图像），必须在提交信息与本文档第 2 节同步登记来源链接、生成参数或作者信息，不能仅依赖 `license: self-made` 标注了事。

目录：

- `Assets/Tilesets/`：首章村庄、野外、洞穴 tileset。
- `Assets/Sprites/`：竖切使用的独立角色 / 敌人 / 物件 sprite。
- `Assets/Characters/`：首章角色 spritesheet（玩家职业、村民、人类敌人、动物、污染怪物）。
- `Assets/Icons/`：技能、消耗品、宝箱、元素矿图标。
- `Assets/Audio/`：UI、战斗、探索、洞穴音效与环境循环（加载路径 `Assets/Audio`）。

| 资源组 | 来源 | License | 作者 |
| --- | --- | --- | --- |
| chapter1 village/wilds/cave tilesets | 本地程序化绘制 | self-made | Rift Expedition project |
| party/village/human/beast character spritesheets | 本地程序化绘制 | self-made | Rift Expedition project |
| skill/item icons | 本地程序化绘制 | self-made | Rift Expedition project |
| WAV cues / ambience loops | 本地程序化合成 | self-made | Rift Expedition project |

## 3. 替换规则（Guide）

- 可替换为 CC0 或等价可商用免署名资源（例如面向 RPG 的 tileset / spritesheet）。
- 替换时必须同步更新：
  1. `RiftExpedition/Resources/Assets/assets-manifest.json`
  2. 本文档第 2 节的来源、作者、下载日期、license
  3. 重新跑校验：`rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources`
- 若使用 AI：只用于静态头像、图标或单张补充图；角色行走 / 攻击动画优先使用成套 spritesheet，避免帧间不一致。
- 文件名与内部 id 用英文；玩家可见文本用中文。

## 4. 如何审查

- 资源清单：检查 `assets-manifest.json` 每个条目的 `license`、`source`、`path`。
- 地图预览 / 校验：运行 validator（预览与报告为生成产物，不入库，见 `tiled-map-contract.md`）。
- 禁止提交文件名或 id 含 `placeholder`、`temp`、`graybox` 的正式资源。
