import { loadProducts, PRODUCT_LINES } from '../../scripts/load-products.mjs'

export default {
  watch: ['../../data/products.yaml'],
  load() {
    return {
      products: loadProducts(),
      lines: PRODUCT_LINES,
    }
  },
}
