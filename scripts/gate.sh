#!/usr/bin/env bash
# 裂隙远征 · 验证门 (gate)
# 原则：仅用 Notion AI Linux 沙盒预装工具，零新增依赖、不联网。
# 用法： bash scripts/gate.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[1/3] 类型检查  tsc --noEmit (allowJs + checkJs + JSDoc)"
npx --no-install tsc --noEmit
echo "      ✓ 类型检查通过"

echo "[2/3] 单元测试  node --test（地图/地形/单位/伤害/寻路）"
node --test test/rules.test.js
echo "      ✓ 单元测试通过"

echo "[3/3] 渲染冒烟  chromium --headless 截图（启动/解析报错 → 画布空白）"
OUT="$(mktemp -d)/smoke.png"
timeout 60 chromium --headless --no-sandbox --disable-gpu \
  --screenshot="$OUT" --window-size=1024,640 "file://$PWD/index.html" >/dev/null 2>&1 || true
SZ=$(stat -c%s "$OUT" 2>/dev/null || echo 0)
if [ "$SZ" -lt 20000 ]; then
  echo "      ✗ 截图异常偏小（${SZ}B），疑似启动失败"; exit 1
fi
echo "      ✓ 渲染冒烟通过（${SZ}B）"

echo "全部通过 ✅"
