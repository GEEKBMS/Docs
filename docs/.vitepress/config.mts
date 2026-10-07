import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitepress'
import { loadProducts, PRODUCT_LINES } from '../../scripts/load-products.mjs'

const products = loadProducts()

function productItems(line: string) {
  return products
    .filter((product) => product.line === line)
    .map((product) => ({
      text: product.name,
      link: `/products/${product.id}/`,
    }))
}

export default defineConfig({
  title: 'GEEKBMS Docs',
  description: 'GEEKBMS 技术文档中心：按型号查阅产品资料，并从 PACK 设计导航进入开源参考设计。',
  lang: 'zh-CN',
  base: '/',
  cleanUrls: true,
  titleTemplate: ':title · GEEKBMS Docs',
  sitemap: {
    hostname: 'https://docs.geekbms.com',
  },
  head: [
    ['meta', { name: 'theme-color', content: '#F97316' }],
  ],
  vite: {
    server: {
      fs: {
        allow: [fileURLToPath(new URL('../..', import.meta.url))],
      },
    },
  },
  themeConfig: {
    siteTitle: 'GEEKBMS Docs',
    nav: [
      { text: '开始阅读', link: '/getting-started/' },
      { text: '按型号', link: '/products/' },
      { text: 'PACK 导航', link: '/pack-design-hub/' },
      { text: '官网', link: 'https://www.geekbms.com/' },
    ],
    sidebar: [
      {
        text: '文档',
        items: [
          { text: '开始阅读', link: '/getting-started/' },
          {
            text: '按型号',
            link: '/products/',
            items: PRODUCT_LINES.map((group) => ({
              text: group.label,
              collapsed: false,
              items: productItems(group.line),
            })),
          },
          { text: 'PACK 导航', link: '/pack-design-hub/' },
          { text: '电芯模型', link: '/pack-design-hub/#cell-models' },
        ],
      },
    ],
    outline: {
      label: '本页目录',
      level: [2, 3],
    },
    docFooter: {
      prev: '上一页',
      next: '下一页',
    },
    darkModeSwitchLabel: '外观',
    lightModeSwitchTitle: '切换到浅色模式',
    darkModeSwitchTitle: '切换到深色模式',
    sidebarMenuLabel: '菜单',
    returnToTopLabel: '回到顶部',
    skipToContentLabel: '跳到正文',
    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: '搜索',
            buttonAriaLabel: '搜索',
          },
          modal: {
            noResultsText: '没有找到结果',
            resetButtonTitle: '清除查询条件',
            footer: {
              selectText: '选择',
              navigateText: '切换',
              closeText: '关闭',
            },
          },
        },
      },
    },
    footer: {
      message: '文档默认采用 CC BY 4.0 许可。产品规格书若另有声明，以该页说明为准。',
      copyright: 'Copyright © 2026 成都极客电巢科技有限公司 / GEEKBMS',
    },
    editLink: {
      pattern: 'https://github.com/GEEKBMS/Docs/edit/main/docs/:path',
      text: '在 GitHub 上编辑此页',
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/GEEKBMS/Docs' },
    ],
  },
})
