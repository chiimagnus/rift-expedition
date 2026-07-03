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

// Phaser 由 index.html 直接从本地 vendor/phaser.min.js 引入（vendor-only，不走 CDN）。
// 下方静态服务器直接托管 vendor/ 等仓库文件，冒烟测试无需任何请求拦截/回填。
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
