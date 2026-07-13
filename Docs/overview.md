# 文档地图

`Docs/` 是本项目的知识库入口，负责“深度内容”。项目规则手册见根目录 [`AGENTS.md`](../AGENTS.md)；5 分钟上手见根目录 [`README.md`](../README.md)。

## 按主题导航

- **架构与数据流** → [`architecture.md`](architecture.md)：分层结构、依赖方向、从地图到战斗的完整数据流、测试分布。
- **依赖清单** → [`dependencies.md`](dependencies.md)：允许使用的 Apple 框架与本地 vendored 依赖（目前只有 SKTiled），以及明确禁止引入的依赖类型。
- **美术 / 音频资源** → [`assets.md`](assets.md)：资源授权契约、当前来源登记、多帧 spritesheet 分帧约定、替换规则。
- **首章数值基线** → [`balance-starting-values.md`](balance-starting-values.md)：职业初始属性、技能数值、装备加成、首章 5 场固定战斗与调参方向。
- **第一章世界图谱** → [`chapter1-worldgraph.md`](chapter1-worldgraph.md)：9 个区域及其连接关系、设计约束。
- **Tiled 地图契约** → [`tiled-map-contract.md`](tiled-map-contract.md)：`.tmx` 必需对象层、校验规则、校验工具 CLI 用法。
- **术语表** → [`glossary.md`](glossary.md)：项目里常见英文/技术术语的大白话说明。

## 运行界面核对

Debug 构建可通过 -uiState 启动参数直接展示 party、exploration、inventory、skills、quests 或 save 状态。该入口只用于可复现的窗口截图与布局检查；状态、存档兼容和测试边界见 architecture.md。

## 报告与生成产物（不入库）

地图校验报告与预览 SVG 是 `Tools/RiftValidator` 的生成产物，已在 `.gitignore` 忽略，不提交到仓库；需要时按 [`tiled-map-contract.md`](tiled-map-contract.md) 里的命令现生成到 `Docs/Reports/`。

## 维护须知

本目录按 `neat-freak` 文档维护约定管理：

- 减优于加：代码变化影响到文档时，优先编辑既有条目，不新增“更新记录”流水账。
- 深度内容只放这里；`README.md` 只做入口，`AGENTS.md` 只放规则。
- 出现日期一律用 `YYYY-MM-DD`，不写相对日期描述。

本次文档同步的基线（commit、生成时间、已知覆盖缺口）记录在 [`GENERATION.md`](GENERATION.md)，下次同步文档前先看这里，只更新受代码改动影响的页面。


- [`aaa-interface-upgrade.md`](aaa-interface-upgrade.md)：本轮界面、叙事、角色、装备与交互升级记录及验收基线。
