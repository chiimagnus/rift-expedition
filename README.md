# 裂隙远征 · 高分辨率像素战棋

纯 **HTML + CSS + JavaScript** 的回合制战棋（SRPG）。零运行时依赖、无需构建、无需联网——双击 `index.html` 即可离线开玩。

## 目录结构

```
rift-expedition/
├── index.html          # 入口页面（按序加载 rules → render → game）
├── src/
│   ├── rules.js        # 纯规则/数据：地图、地形、单位定义、寻路、伤害结算（DOM 无关）
│   ├── render.js       # 渲染：程序化像素精灵、地形、粒子特效、UI 面板、渲染循环
│   ├── game.js         # 状态、回合流程、敌方 AI、输入、启动
│   └── style.css       # 样式
├── test/
│   └── rules.test.js   # 纯逻辑单元测试（node:test，零依赖）
├── scripts/
│   └── gate.sh         # 验证门：类型检查 + 单元测试 + 渲染冒烟
├── tsconfig.json       # 仅供 tsc 类型检查（allowJs + checkJs + JSDoc）
└── .gitignore
```

三个脚本是**经典脚本**（非 ES module），按 `rules → render → game` 顺序加载、共享全局作用域，因此双击本地 `file://` 打开也不会触发跨域限制。

## 开玩

直接双击 `index.html`，或本地起个静态服务器后访问。

- 左键：选中我方单位 → 高亮可移动/可攻击/可治疗范围 → 点击目标格执行。
- 右键 / Esc：取消当前选择。
- Enter / “结束回合”：结束我方回合。

## 开发与自检

本项目仅使用 Notion AI Linux 沙盒预装工具，**零新增依赖、不联网**：

```bash
bash scripts/gate.sh   # 1) tsc 类型检查  2) node:test 单元测试  3) chromium 渲染冒烟
```

- 类型检查：`npx --no-install tsc --noEmit`（JS + JSDoc，不产物）。
- 单元测试：`node --test test/rules.test.js`（覆盖地图完整性、地形代价、单位数值、伤害下限、寻路与路径重建）。
- 渲染冒烟：`chromium --headless` 截图，若画布空白（启动/解析报错）则失败。
