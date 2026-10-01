# GEEKBMS Docs

公司 **技术文档中心**（面向客户与工程师的产品 / 应用知识库）。源文件在本仓库，公开站点是 VitePress 静态站。

官网：[www.geekbms.com](https://www.geekbms.com/) · 设计导航登记：[Battery-PACK-Design-Hubs](https://github.com/GEEKBMS/Battery-PACK-Design-Hubs)

## 公开网址

| 页面 | 网址 |
|---|---|
| 首页 | https://docs.geekbms.com/ |
| 按型号 | https://docs.geekbms.com/products/ |
| 型号详情 | https://docs.geekbms.com/products/<id>/ |
| 开始阅读 | https://docs.geekbms.com/getting-started/ |
| PACK 导航 | https://docs.geekbms.com/pack-design-hub/ |

`<id>` 与 `data/products.yaml` 里的 `id` 一致，例如 [BMS-16S-60A](https://docs.geekbms.com/products/bms-16s60a/)。路径定下来之后不要改，资料更新写在同一页。

对外说明请链到上表里的文档站地址，不要链到 GitHub / Gitee 上的 Markdown 源文件。

## 内容结构

### a. 电池 PACK 开源设计中心

[PACK 导航](https://docs.geekbms.com/pack-design-hub/)（源文件 `docs/pack-design-hub/`）

- 只做 **简介与导航**
- 具体型号资料在各自 PACK 仓库（例如 [motorcycle-battery-pack](https://github.com/GEEKBMS/motorcycle-battery-pack)）
- 与 GitHub 登记源 [Battery-PACK-Design-Hubs](https://github.com/GEEKBMS/Battery-PACK-Design-Hubs) 保持一致

### b. 产品技术文档

[按型号](https://docs.geekbms.com/products/)（源文件 `docs/products/`）

- 闭源产品脱敏后可公开的规格书、应用说明等
- 型号清单是 `data/products.yaml`（`line`: `bms` | `balancing` | `handheld`，以及 `id`、`name`、`summary`）
- 每个型号一页：`docs/products/<id>/index.md`，对应 `/products/<id>/`
- 阶段 1 的条目是示例，与官网上的虚构型号一致，不是已发布规格书

**飞书同步在阶段 1 是人工的。** 改 `data/products.yaml`，补上对应的 Markdown。本仓库不调用飞书 API。

## 本地预览

需要 Node.js 22 或更新版本。

```bash
npm ci
npm run dev
```

开发服务器默认是 <http://localhost:5173/>。

```bash
npm run build    # 校验 products.yaml，并 vitepress build
npm run preview  # 预览 docs/.vitepress/dist
```

## Gitee

当前以 GitHub 为源。Gitee 镜像可以以后再加。对外链接请用 https://docs.geekbms.com/ 。

## 许可证

文档默认 CC BY 4.0（见 `LICENSE`）。产品规格书若另有声明，以文件内页为准。

https://creativecommons.org/licenses/by/4.0/legalcode

站点发布与运维说明在私有仓库 GEEKBMS/geekbms-web（企业门户）内部文档中维护。
