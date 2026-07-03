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
