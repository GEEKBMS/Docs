---
title: PACK 导航
description: 电池 PACK 开源设计中心的简介与导航，以及电芯 STEP 与 GLB 模型的下载入口。具体 PACK 资料在各自仓库。
---

# 电池 PACK 开源设计中心

这里只提供 **简介和导航**。完整设计资料（3D、BOM、丝印、规格书等）在对应的独立开源仓库中，不放在本文档站。

公开网址：<https://docs.geekbms.com/pack-design-hub/>

GitHub 登记源：[Battery-PACK-Design-Hubs](https://github.com/GEEKBMS/Battery-PACK-Design-Hubs)

## 项目列表

| 项目 | 仓库 | 说明 |
|---|---|---|
| Motorcycle Battery PACK | [motorcycle-battery-pack](https://github.com/GEEKBMS/motorcycle-battery-pack) | 摩托车电池 PACK 参考设计（当前为占位骨架） |

新增 PACK 时：先建独立仓库 → 更新 Battery-PACK-Design-Hubs 目录 → 再在本页增加导航行。

## 电芯模型 {#cell-models}

常用圆柱电芯的三维模型在独立仓库，不放在本文档站。

GitHub：[cell-models](https://github.com/GEEKBMS/cell-models)

当前包含 **18650 / 21700 / 26650 / 4680 / 32700 / 32140 / 40135** 七种规格。每种规格提供干净的 **STEP**（不含品牌文字或标签几何，便于装配和间隙检查）和带贴图的 **GLB**（用于可视化和渲染），以及预览 PNG。

这些是按公称外形做的简化外形参考，不是任何厂家 CAD、商标或公差图的副本。实际电芯因厂家和型号而异，定稿前请核对所用电芯的规格书。不用于制造、认证或安全关键用途。

克隆或下载需要 [Git LFS](https://git-lfs.com/)（命令 `git lfs`）。模型文件由 Git LFS 管理；未安装时，克隆得到的是指针文件，无法直接打开。

```bash
git lfs install
git clone https://github.com/GEEKBMS/cell-models.git
```

产品型号资料见 [按型号](/products/)。
