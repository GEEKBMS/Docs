import { existsSync, readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { parse } from 'yaml'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')

export const PRODUCT_LINES = [
  { line: 'bms', label: 'BMS 保护板' },
  { line: 'balancing', label: '主动均衡' },
  { line: 'handheld', label: '手持均衡仪' },
]

const LINE_IDS = new Set(PRODUCT_LINES.map((item) => item.line))
const ID_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/
const STATUSES = new Set(['sample', 'published'])

export function lineLabel(line) {
  return PRODUCT_LINES.find((item) => item.line === line)?.label ?? line
}

/**
 * Load and validate data/products.yaml.
 * When checkPages is true, every id must have docs/products/<id>/index.md.
 */
export function loadProducts({ checkPages = true } = {}) {
  const file = resolve(root, 'data/products.yaml')
  const doc = parse(readFileSync(file, 'utf8'))
  if (!doc || !Array.isArray(doc.products) || doc.products.length === 0) {
    throw new Error('data/products.yaml must contain a non-empty products array')
  }

  const seen = new Set()
  for (const product of doc.products) {
    const id = product?.id || '(missing id)'
    if (!LINE_IDS.has(product?.line)) {
      throw new Error(`${id}: line must be bms, balancing, or handheld`)
    }
    if (typeof product.id !== 'string' || !ID_RE.test(product.id)) {
      throw new Error(`${id}: id must be a lowercase slug (a-z, 0-9, hyphen)`)
    }
    if (seen.has(product.id)) {
      throw new Error(`${product.id}: duplicate id`)
    }
    seen.add(product.id)
    if (typeof product.name !== 'string' || !product.name.trim()) {
      throw new Error(`${product.id}: name is required`)
    }
    if (typeof product.summary !== 'string' || !product.summary.trim()) {
      throw new Error(`${product.id}: summary is required`)
    }
    if (product.status != null && !STATUSES.has(product.status)) {
      throw new Error(`${product.id}: status must be sample or published`)
    }
    if (checkPages) {
      const page = resolve(root, 'docs/products', product.id, 'index.md')
      if (!existsSync(page)) {
        throw new Error(`${product.id}: missing docs/products/${product.id}/index.md`)
      }
    }
  }

  return doc.products
}
