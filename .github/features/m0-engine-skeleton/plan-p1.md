# Plan P1 - m0-engine-skeleton

**Goal:** 搭建双生圣痕项目的分层架构与 Phaser 3 启动骨架，使空场景可运行且门禁全绿。

**Non-goals:** 不写任何战斗/寻路/AI/地形/存档逻辑（M1+）；不接入真实美术/音频资源；不做移动端适配；不引入额外构建工具链/状态管理库。

**Approach:** 从空仓库开始，先搭配置与目录骨架，再自下而上写 Scene（Boot → Battle/UI），然后组装 Phaser.Game 入口，最后补齐构建、冒烟与门禁脚本。每个 task 完成后立即验证并原子提交。

**Acceptance:**
- `bash scripts/gate.sh` 一键跑完“类型检查 → 测试 → 构建 → 冒烟”四步且 exit code 0。
- `git log --oneline` 显示 10 次与 task 一一对应的原子提交。

**Rules:**
- 只在 `/data/twin-stigma-tactics` 仓库内操作，不要创建其他平行目录。
- 不要 `git add`/`git commit` `.github/features/**` 下的任何文件（`idea.md`/`todo.toml`/`plan-p1.md`/未来的 `audit-p1.md`）。
- 每个 task 只做自己范围内的事，不要提前实现后面 task 才需要的内容。
- 沙箱默认无网络访问，不要执行 `npm install`/`npm ci`；`esbuild`、`typescript`、`chromium` 已在环境中可直接使用（包位于 `/vercel/sandbox/node_modules`，必要时用 `require.resolve` 确认路径）。
- Phaser 只能通过 `index.html` 里的 CDN `<script>` 引入，绝不能 `import` 或 `require('phaser')`。
- 每个 task 完成后，先跑验证命令确认通过，再提交；commit subject 格式 `<type>: <task-id> - <中文描述>`，例如 `feat: P1-T1 - 初始化仓库骨架与分层目录`。
- 若某个 task 的实现替换/废弃了之前 task 写的内容，须在替换发生的同一个 task 内直接删除旧代码，不要拖到最后一个 task 或 Phase Audit 才清理（全局 AGENTS.md 执行约定）。

---

## P1-T1 初始化仓库骨架与分层目录

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `.gitignore`
- Create: `README.md`
- Create: `src/entrypoints/.gitkeep`, `src/ui/scenes/.gitkeep`, `src/viewmodels/.gitkeep`, `src/services/.gitkeep`, `src/models/.gitkeep`, `src/types/.gitkeep`

**Step 1: 实现功能**

`package.json`（`type: module`，脚本仅定义，后绪 task 会填充对应脚本文件）：
```json
{
  "name": "twin-stigma-tactics",
  "private": true,
  "type": "module",
  "version": "0.0.0",
  "scripts": {
    "typecheck": "tsc --noEmit",
    "test": "npx --no-install tsx --test",
    "build": "node scripts/build.mjs",
    "smoke": "node scripts/smoke.mjs",
    "gate": "bash scripts/gate.sh"
  }
}
```

`tsconfig.json`（严格模式 + 路径别名，`baseUrl` 指向 `./src`）：
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2022", "DOM"],
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "baseUrl": "./src",
    "paths": {
      "@ui/*": ["ui/*"],
      "@viewmodels/*": ["viewmodels/*"],
      "@services/*": ["services/*"],
      "@models/*": ["models/*"]
    }
  },
  "include": ["src"]
}
```

`.gitignore`：
```text
node_modules/
dist/
*.log
.DS_Store
```

`README.md`：写一句项目一句话介绍即可，例如：`# 双生圣痕 · 血脉宿命战棋\n\nWeb 像素风战棋，基于 Phaser 3 + TypeScript。`

目录：创建 `src/entrypoints`、`src/ui/scenes`、`src/viewmodels`、`src/services`、`src/models`、`src/types`，每个目录下放一个空 `.gitkeep` 文件以便 git 跟踪空目录。

**Step 2: 验证**

Run: `test -f package.json && test -f tsconfig.json && node -e "JSON.parse(require('fs').readFileSync('tsconfig.json','utf8')); JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('CONFIG_OK')"`

Expected: 输出 `CONFIG_OK`，退出码 0。

**Step 3: 原子提交**

Run: `git add package.json tsconfig.json .gitignore README.md src`

Run: `git commit -m "feat: P1-T1 - 初始化仓库骨架与分层目录"`

---

## P1-T2 index.html 与 Phaser 全局类型声明

**Files:**
- Create: `index.html`
- Create: `src/types/phaser-global.d.ts`（替换 `.gitkeep`）

**Step 1: 实现功能**

`index.html`（锁定 Phaser CDN 版本号，例如 `3.80.1`；画布容器 id 为 `game-root`；入口脚本以 `type="module"` 引入 `dist/main.js`）：
```html
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <title>双生圣痕 · 血脉宿命战棋</title>
  <style>html,body{margin:0;background:#000;display:flex;justify-content:center;align-items:center;height:100%;}</style>
</head>
<body>
  <div id="game-root"></div>
  <script src="https://cdn.jsdelivr.net/npm/phaser@4.2.0/dist/phaser.min.js"></script>
  <script type="module" src="./dist/main.js"></script>
</body>
</html>
```

`src/types/phaser-global.d.ts`（宽松 ambient 声明，需要在文件开头加 `// ponytail:` 注释说明这是有意的简化）：
```ts
// ponytail: 没有安装 Phaser 包/类型（CDN 引入），这里用宽松 any 声明全局变量兜底；
// 升级路径：若后续允许联网安装，改用 `npm i -D phaser` 并删除此文件，改为 `import type Phaser from 'phaser'`。
declare const Phaser: any
```

**Step 2: 验证**

Run: `test -f index.html && grep -q 'phaser@4.2.0' index.html && npx tsc --noEmit`

Expected: 无输出或仅有正常日志，退出码 0（此时 `src/entrypoints` 下还没有 `.ts` 文件，`tsc --noEmit` 仍应成功）。

**Step 3: 原子提交**

Run: `git add index.html src/types`

Run: `git commit -m "feat: P1-T2 - 新增 index.html 与 Phaser 全局类型声明"`

---

## P1-T3 实现 BootScene

**Files:**
- Create: `src/ui/scenes/BootScene.ts`

**Step 1: 实现功能**

继承 `Phaser.Scene`，`key: 'BootScene'`；`create()` 中用 `this.add.text(...)` 居中显示占位文字（如 `加载中...`），然后立即调用 `this.scene.start('BattleScene')` 与 `this.scene.launch('UIScene')`。不需要真实资源预加载（非目标），只需验证场景切换链路。使用 `@ui/scenes/...` 相对路径引用其他 scene 文件（如需）。

**Step 2: 验证**

Run: `npx tsc --noEmit`

Expected: 退出码 0（注意：此时 `BattleScene`/`UIScene` 还不存在，`BootScene.ts` 中对它们的引用只能用字符串 key `'BattleScene'`/`'UIScene'`传给 `this.scene.start/launch`，不要 `import` 尚未创建的文件，避免编译失败）。

**Step 3: 原子提交**

Run: `git add src/ui/scenes/BootScene.ts`

Run: `git commit -m "feat: P1-T3 - 实现 BootScene 占位场景"`

---

## P1-T4 实现 BattleScene

**Files:**
- Create: `src/ui/scenes/BattleScene.ts`

**Step 1: 实现功能**

继承 `Phaser.Scene`，`key: 'BattleScene'`；`create()` 中用 `this.cameras.main.setBackgroundColor('#1d1f2b')` 设置占位背景色，并 `console.log('[BattleScene] ready')` 便于冒烟脚本确认无报错。不添加任何战棋逻辑。

**Step 2: 验证**

Run: `npx tsc --noEmit`

Expected: 退出码 0。

**Step 3: 原子提交**

Run: `git add src/ui/scenes/BattleScene.ts`

Run: `git commit -m "feat: P1-T4 - 实现 BattleScene 空场景"`

---

## P1-T5 实现 UIScene

**Files:**
- Create: `src/ui/scenes/UIScene.ts`

**Step 1: 实现功能**

继承 `Phaser.Scene`，`key: 'UIScene'`；`create()` 中仅 `console.log('[UIScene] ready')`，不渲染任何 HUD 元素（非目标）。

**Step 2: 验证**

Run: `npx tsc --noEmit`

Expected: 退出码 0。

**Step 3: 原子提交**

Run: `git add src/ui/scenes/UIScene.ts`

Run: `git commit -m "feat: P1-T5 - 实现 UIScene 空场景"`

---

## P1-T6 实现 entrypoints/main.ts 组装 Phaser.Game

**Files:**
- Create: `src/entrypoints/main.ts`（替换 `.gitkeep`）

**Step 1: 实现功能**

从 `@ui/scenes/BootScene`、`@ui/scenes/BattleScene`、`@ui/scenes/UIScene` 导入三个 Scene。计算整数缩放倍率（逻辑分辨率 448x320，例如 `const zoom = Math.max(1, Math.floor(Math.min(window.innerWidth / 448, window.innerHeight / 320)))`）。构造 `Phaser.Game` 配置：
```ts
import BootScene from '@ui/scenes/BootScene'
import BattleScene from '@ui/scenes/BattleScene'
import UIScene from '@ui/scenes/UIScene'

const zoom = Math.max(1, Math.floor(Math.min(window.innerWidth / 448, window.innerHeight / 320)))

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game-root',
  width: 448,
  height: 320,
  pixelArt: true,
  roundPixels: true,
  antialias: false,
  scale: { mode: Phaser.Scale.FIT, zoom },
  scene: [BootScene, BattleScene, UIScene],
})

;(window as any).game = game
```
注意：将 `game` 挂到 `window.game` 上，供后续冒烟脚本检测。各 Scene 文件需补充 `export default class ...` 导出（回头档时需同步修改 T3/T4/T5 中的定义，若它们尚未导出则在本 task 一并补上）。

**Step 2: 验证**

Run: `npx tsc --noEmit`

Expected: 退出码 0。

**Step 3: 原子提交**

Run: `git add src/entrypoints/main.ts src/ui/scenes`

Run: `git commit -m "feat: P1-T6 - 组装 Phaser.Game 入口"`

---

## P1-T7 编写 esbuild 打包脚本并验证构建

**Files:**
- Create: `scripts/build.mjs`

**Step 1: 实现功能**

```js
import { build } from 'esbuild'

await build({
  entryPoints: ['src/entrypoints/main.ts'],
  outfile: 'dist/main.js',
  bundle: true,
  format: 'esm',
  target: 'es2022',
  sourcemap: true,
  tsconfig: 'tsconfig.json',
  logLevel: 'info',
})
```
如果沙箱全局 `node_modules` 不在项目目录下（本沙箱实际位于 `/vercel/sandbox/node_modules`），`import { build } from 'esbuild'` 若报 `Cannot find package 'esbuild'`，改为给出绝对路径：`import { build } from '/vercel/sandbox/node_modules/esbuild/lib/main.js'`，并在文件头部用 `// ponytail:` 注释说明原因与升级路径（未来若项目本地有了 `node_modules/esbuild` 则改回直接 `import`）。**已实测确认**：esbuild 通过 `tsconfig.json` 的 `baseUrl`+`paths` 能自动正确解析并打包 `@xxx/*` 别名导入，无需额外插件（用最小复现示例验证过：`@models/foo` 成功打包并在 `node` 下运行正确）。

**Step 2: 验证**

Run: `node scripts/build.mjs && test -s dist/main.js && echo BUILD_OK`

Expected: 输出包含 `BUILD_OK`，退出码 0，`dist/main.js` 非空。

**Step 3: 原子提交**

Run: `git add scripts/build.mjs`

Run: `git commit -m "feat: P1-T7 - 新增 esbuild 打包脚本"`

（`dist/` 已在 `.gitignore` 中排除，不要提交构建产物。）

---

## P1-T8 编写 headless Chromium 冒烟脚本

**Files:**
- Create: `scripts/smoke.mjs`

**Step 1: 实现功能**

使用 `playwright`（沙箱预装）启动 chromium，加载本地 `index.html`（用 `file://` 路径，或起一个临时静态服务器避免 module 跨域限制——优先用 `node:http` 起一个最小静态文件服务器，因为 `type="module"` 脚本在 `file://` 下会被浏览器 CORS 拦截）。流程：
1. 用 `node:http` 在 `127.0.0.1` 任意空闲端口起一个静态文件服务器，根目录为项目根目录。
2. 用 `playwright` 启动 chromium，监听 `page.on('console')` 与 `page.on('pageerror')` 收集错误。
3. `page.goto('http://127.0.0.1:<port>/index.html')`，等待 `page.waitForFunction(() => (window as any).game instanceof (window as any).Phaser.Game, { timeout: 5000 })`。
4. 如有任何 `pageerror` 或 `console` 类型为 `error` 的输出，或 `waitForFunction` 超时，则以非 0 退出码并打印错误详情；否则打印 `SMOKE_OK` 并以 0 退出，最后关闭浏览器与服务器。
若 `import { chromium } from 'playwright'` 报包未找到，同 P1-T7 思路改用绝对路径导入并注释说明。

**Step 2: 验证**

Run: `node scripts/build.mjs && node scripts/smoke.mjs`

Expected: 输出包含 `SMOKE_OK`，退出码 0。

**Step 3: 原子提交**

Run: `git add scripts/smoke.mjs`

Run: `git commit -m "feat: P1-T8 - 新增 headless 冒烟脚本"`

---

## P1-T9 串联 gate.sh 并验证全绿

**Files:**
- Create: `scripts/gate.sh`
- Create: `src/models/pathAliasProbe.ts`
- Create: `src/models/pathAliasProbe.test.ts`

**Step 1: 实现功能**

本 task 承担 M0 自身在 `idea.md` 里声明的一个验收点：证明路径别名在 tsc / esbuild / 测试运行器三处真正同步解析（已实测，不是假设）：
- `esbuild` 能通过 `tsconfig.json` 的 `baseUrl`+`paths` 自动解析别名（无需插件）——已确认可行（见 P1-T7）。
- Node 24 原生 `node --test`（无 loader）**无法**解析 `tsconfig.json` 的 `paths`，导入别名会报 `ERR_MODULE_NOT_FOUND`；沙箱预装的 `tsx`（`npx --no-install tsx --test`）可以正确解析——这也是 P1-T1 里 `package.json` 的 `test` 脚本已经改成 `npx --no-install tsx --test` 的原因。

因此本 task 用一个最小探针证明这条链路真的通：

`src/models/pathAliasProbe.ts`：
```ts
// ponytail: 这个文件只用于证明「@models/* 别名在 tsc/esbuild/tsx 三处都能解析」，
// 不是真正的游戏数据模型；M1 引入第一个真实 model 单测后应删除本文件与对应测试。
export const PATH_ALIAS_PROBE = true
```

`src/models/pathAliasProbe.test.ts`：
```ts
import test from 'node:test'
import assert from 'node:assert/strict'
import { PATH_ALIAS_PROBE } from '@models/pathAliasProbe'

test('M0: @models/* 路径别名可在测试运行器中解析', () => {
  assert.equal(PATH_ALIAS_PROBE, true)
})
```

`scripts/gate.sh`：
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo '==> typecheck'
npx tsc --noEmit

echo '==> test'
npx --no-install tsx --test

echo '==> build'
node scripts/build.mjs

echo '==> smoke'
node scripts/smoke.mjs

echo 'GATE_OK'
```
赋予可执行权限：`chmod +x scripts/gate.sh`。

**Step 2: 验证**

Run: `bash scripts/gate.sh`

Expected: 依次打印 `==> typecheck` `==> test` `==> build` `==> smoke` `GATE_OK`，整体退出码 0；`test` 步骤应显示 1 个测试通过（`pathAliasProbe`）。

**Step 3: 原子提交**

Run: `git add scripts/gate.sh src/models/pathAliasProbe.ts src/models/pathAliasProbe.test.ts`

Run: `git commit -m "feat: P1-T9 - 串联门禁脚本，新增路径别名探针测试并验证全绿"`

---

## P1-T10 补充仓库根 AGENTS.md

**Files:**
- Create: `AGENTS.md`

**Step 1: 实现功能**

内容要点（精简，不要搭建额外文档体系）：
- 分层规则：`entrypoints → ui → viewmodels → services → models`，依赖只能从左到右；`entrypoints` 可依赖所有层，其余层不得反向依赖上层。
- 分层职责边界（对齐设计蓝图 [E/20]，严守）：
  - `ui`：能渲染只读状态、播放演出、收集输入；禁止写规则、禁止直接改 `models`。
  - `viewmodels`：能组织表现状态、把 Command 派发给 `services`；禁止依赖 Phaser、禁止写战斗规则。
  - `services`：能做结算/寻路/AI/存档等纯逻辑；禁止引用 Phaser、禁止读 DOM。
  - `models`：只放纯数据结构与不变量；禁止含行为副作用。
- 路径别名表：`@ui/* @viewmodels/* @services/* @models/*` 均指向 `src/*`（`entrypoints` 不设别名——没有层需要反向 import 它）；修改别名需同步改 `tsconfig.json`（esbuild 自动跟随 `tsconfig.json` 的 `paths`，无需单独改）。
- 测试运行器固定用 `npx --no-install tsx --test`，不要用裸 `node --test`：已实测 Node 原生 `--test` 无法解析 `tsconfig.json` 的 `paths` 别名（`ERR_MODULE_NOT_FOUND`），`tsx` 可以。
- Phaser 仅通过 `index.html` CDN `<script>` 引入，不要 `npm install phaser`。
- 验证命令：`bash scripts/gate.sh`（含类型检查/测试/构建/冒烟，提交前必须全绿）。
- 沙箱默认无网络，不要尝试 `npm install`。

**Step 2: 验证**

Run: `test -f AGENTS.md && grep -q 'gate.sh' AGENTS.md && echo AGENTS_OK`

Expected: 输出 `AGENTS_OK`。

**Step 3: 原子提交**

Run: `git add AGENTS.md`

Run: `git commit -m "docs: P1-T10 - 补充仓库根 AGENTS.md"`

---

## Phase Audit

- Audit file: `audit-p1.md`
- Rule: 完成本 phase 全部 10 个 task 后，`executing-plans` 必须自动进入该文件的审计闭环。
- Flow:
  1. 先通读 `src/`、`scripts/`、`index.html`、`package.json`、`tsconfig.json`，逐一比对本计划的 Acceptance 与 `idea.md` 验收标准，记录发现的差异/遗漏（包括：别名是否三处一致、Phaser 是否真的只走 CDN、是否混入了 M1 范围内容）。
  2. 修复发现的问题（如有）。
  3. 重新跑 `bash scripts/gate.sh` 确认仍然全绿，并确认 `git log --oneline` 与 `todo.toml` 中的 10 个 task 一一对应。
