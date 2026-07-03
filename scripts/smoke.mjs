import http from 'node:http'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { chromium } from 'playwright'

const root = process.cwd()
const mime = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.map': 'application/json',
  '.css': 'text/css',
}

// ponytail: 生产用 index.html 里的 CDN 引入 Phaser；但沙箱无网，故 smoke 用
// Playwright route 拦截 CDN 请求，用本地 vendor 的同版本 Phaser 回填，保持
// “生产 CDN / 测试本地”策略；index.html 无需为测试改动。
// 注意：vendor/phaser.min.js 是不纳入 git 的本地测试夹具（见 .gitignore），
// 缺失时从 Notion 存档的 phaser.js.zip 取回；缺失会导致下方 route 回填失败。
const PHASER_VENDOR = path.join(root, 'vendor/phaser.min.js')

const server = http.createServer(async (req, res) => {
  try {
    const urlPath = req.url === '/' ? '/index.html' : req.url
    const filePath = path.join(root, decodeURIComponent(urlPath.split('?')[0]))
    const data = await readFile(filePath)
    const ext = path.extname(filePath)
    res.writeHead(200, { 'Content-Type': mime[ext] ?? 'application/octet-stream' })
    res.end(data)
  } catch {
    res.writeHead(404)
    res.end('not found')
  }
})

await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
const port = server.address().port

const errors = []
const browser = await chromium.launch({
  executablePath: '/usr/local/bin/chromium',
  args: ['--no-sandbox'],
})
const page = await browser.newPage()

// 拦截 CDN 的 Phaser 请求，回填本地 vendor 副本
await page.route('**/cdn.jsdelivr.net/**', async (route) => {
  try {
    const body = await readFile(PHASER_VENDOR)
    await route.fulfill({ status: 200, contentType: 'text/javascript', body })
  } catch (err) {
    errors.push(`vendor phaser fulfil failed: ${err.message}`)
    await route.abort()
  }
})

page.on('console', (msg) => {
  if (msg.type() === 'error') errors.push(`console.error: ${msg.text()}`)
})
page.on('pageerror', (err) => {
  errors.push(`pageerror: ${err.message}`)
})

try {
  await page.goto(`http://127.0.0.1:${port}/index.html`)
  await page.waitForFunction(() => window.game instanceof window.Phaser.Game, {
    timeout: 8000,
  })
} catch (err) {
  errors.push(`waitForFunction failed: ${err.message}`)
}

await browser.close()
server.close()

if (errors.length > 0) {
  console.error('SMOKE_FAILED')
  for (const e of errors) console.error(e)
  process.exit(1)
}

console.log('SMOKE_OK')
