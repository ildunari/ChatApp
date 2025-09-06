import { build } from 'esbuild'
import { fileURLToPath } from 'url'
import { dirname, resolve } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const watch = process.argv.includes('--watch')

const entry = resolve(__dirname, '../src/main.js')
// Output directly into the app bundle resources location
const out = resolve(__dirname, '../../ChatApp/WebCanvas/dist/app.bundle.js')

await build({
  entryPoints: [entry],
  outfile: out,
  bundle: true,
  format: 'iife',
  target: ['es2020'],
  platform: 'browser',
  minify: false,
  sourcemap: true,
  define: { 'process.env.NODE_ENV': '"production"' },
  logLevel: 'info',
  watch: watch ? {
    onRebuild(error) {
      if (error) console.error('❌ Rebuild failed:', error)
      else console.log('✅ Rebuilt')
    }
  } : false
})

console.log('\nBuilt →', out)

