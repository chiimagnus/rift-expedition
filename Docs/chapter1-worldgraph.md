# 第一章世界图谱

世界 ID：`chapter1`

首章采用开放式箱庭结构，入口在村庄广场，玩家可经村外主路或河岸绕路进入野外，最后从旧矿洞入口进入洞穴线。地图先按 9 个区域组织，后续每个区域任务在对应 TMX 上增量填内容。

## 区域

| Area ID | 中文名 | 空间类型 | 作用 |
| --- | --- | --- | --- |
| `village_square` | 裂隙村广场 | 村庄 | 主线开端、村长/未婚夫/守卫、任务导向 |
| `village_riverside` | 裂隙村河岸 | 村庄 | 药师支线、河桥、通往河湾的绕路 |
| `village_outskirts` | 裂隙村外缘 | 村庄 | 战斗入门、村外警戒线、通往野路 |
| `wilds_road` | 断塔野路 | 野外 | 主路、绕路选择、野外遭遇入口 |
| `wilds_ruins` | 旧驿站废墟 | 野外 | 废墟探索、油/火教学、盗匪线索 |
| `wilds_riverbank` | 苦根河湾 | 野外 | 苦根草、浅水地表、洞穴侧路 |
| `cave_entrance` | 旧矿洞入口 | 洞穴 | 污染线索、毒/火组合、洞穴入口战 |
| `cave_mines` | 元素矿道 | 洞穴 | 偷采证据、矿工战、元素矿奖励 |
| `cave_depths` | 裂隙洞心 | 洞穴 | 真相揭露、收尾强敌、章节出口 |

## 连接

- `village_square` -> `village_riverside`
- `village_square` -> `village_outskirts`
- `village_riverside` -> `wilds_riverbank`
- `village_outskirts` -> `wilds_road`
- `wilds_road` -> `wilds_ruins`
- `wilds_road` -> `wilds_riverbank`
- `wilds_ruins` -> `cave_entrance`
- `wilds_riverbank` -> `cave_entrance`
- `cave_entrance` -> `cave_mines`
- `cave_mines` -> `cave_depths`

## 设计约束

- 所有地图都保留固定对象层：`spawn`、`npc`、`encounter`、`trigger`、`exit`、`navObstacle`、`surface`、`item`。
- 地图出口目标必须指向现有 area 和 spawn。
- 世界图谱必须从 `village_square.start` 可连通全部区域。
- 首章不做随机遭遇；所有遭遇由地图对象层固定触发。
