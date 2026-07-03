#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo '==> typecheck'
npx tsc --noEmit

echo '==> test'
npx --no-install tsx --test 'src/**/*.test.ts'

echo '==> build'
node scripts/build.mjs

echo '==> smoke'
node scripts/smoke.mjs

echo 'GATE_OK'
