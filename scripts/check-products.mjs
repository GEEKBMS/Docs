import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { lineLabel, loadProducts } from './load-products.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const products = loadProducts({ checkPages: true })

let failed = false
for (const product of products) {
  const pagePath = resolve(root, 'docs/products', product.id, 'index.md')
  const body = readFileSync(pagePath, 'utf8')
  if (!body.includes(product.id) || !body.includes(product.name)) {
    failed = true
    console.error(`${product.id}: docs/products/${product.id}/index.md must mention the id and name`)
  }
  if (!body.includes(lineLabel(product.line))) {
    failed = true
    console.error(`${product.id}: page must mention the line label ${lineLabel(product.line)}`)
  }
}

if (failed) {
  process.exit(1)
}

console.log(`ok: ${products.length} products in data/products.yaml`)
