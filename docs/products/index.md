---
title: 按型号
description: GEEKBMS 产品技术文档索引。清单来自 data/products.yaml。
prev: false
next: false
---

# 产品技术文档

闭源产品在脱敏后，可以在这里放规格书和应用说明。每个型号使用稳定路径 `/products/<id>/`，例如 [BMS-16S-60A](/products/bms-16s60a/) 与 [E04S05D](/products/e04s05d/)。

标「示例」的条目与官网上的虚构型号一致，不是已发布规格书。标「草稿」的条目用来占住稳定地址。E04S05D、E06S05D 的串数与均衡电流已按本周官网关键参数写入型号页（4S / 5 A 与 6S / 5 A），其余规格以后从型号仓库补齐。购买渠道见 [官网联系页](https://www.geekbms.com/contact/)。

<script setup>
import { data } from './products.data.js'

function statusLabel(status) {
  if (status === 'published') return ''
  if (status === 'draft') return '草稿'
  return '示例'
}
</script>

<section v-for="group in data.lines" :key="group.line">
  <h2>{{ group.label }}</h2>
  <ul>
    <li v-for="product in data.products.filter((item) => item.line === group.line)" :key="product.id">
      <a :href="'/products/' + product.id + '/'"><code>{{ product.name }}</code></a>
      — {{ product.summary }}
      <span v-if="statusLabel(product.status)">（{{ statusLabel(product.status) }}）</span>
    </li>
  </ul>
</section>

## 线级共用

[手持均衡仪通则](/products/handheld-balancer/) 给 E04S05D 与 E06S05D 共用，状态为草稿，不是订货型号。现行手持均衡仪订货型号是 **E04S05D** 与 **E06S05D**（A 系列已停用，不设文档页）。

## 维护（阶段 1）

飞书同步是人工的：改 `data/products.yaml`，并保证每个 `id` 都有 `docs/products/<id>/index.md`。本阶段不调用飞书 API。

对外请链到文档站，例如 <https://docs.geekbms.com/products/>，不要链到仓库里的源文件。
