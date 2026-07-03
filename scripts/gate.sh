#!/usr/bin/env bash
set -euo pipefail

npm run compile
npm test
npm run build
npm run smoke
