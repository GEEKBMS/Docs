# GEEKBMS Docs

公司 **技术文档中心**（面向客户与工程师的产品 / 应用知识库）。源文件在本仓库，公开站点是 VitePress 静态站。

官网：[www.geekbms.com](https://www.geekbms.com/) · 设计导航登记：[Battery-PACK-Design-Hubs](https://github.com/GEEKBMS/Battery-PACK-Design-Hubs)

官网 `/docs/` 仍是手写索引。把它改成跳转到本文档站的工作在 `geekbms-web` 另开 PR，本仓库不改官网。

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

**飞书同步在阶段 1 是人工的。** 改 `data/products.yaml`，补上对应的 Markdown，然后走下面的发布流程。本仓库不调用飞书 API。

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

## 部署到 docs.geekbms.com

静态文件发到与 [geekbms-web](https://github.com/GEEKBMS/geekbms-web) 相同的阿里云主机，使用**单独的站点目录** `/var/www/geekbms-docs`（不是 `/var/www/geekbms`）。发布是原子的：新版本解压到 `releases/<时间>-<sha>/`，再把 `current` 符号链接切过去。nginx 的 `server_name` 是 `docs.geekbms.com`。

工作流：`.github/workflows/deploy.yml`（推送到 `main`，或手动 `workflow_dispatch`）。拉取请求只构建，不发布。

示例 nginx：

- 还没有证书时：[`deploy/nginx/docs.geekbms.com.http.conf`](deploy/nginx/docs.geekbms.com.http.conf)
- 证书已经在服务器上时：[`deploy/nginx/docs.geekbms.com.https.conf`](deploy/nginx/docs.geekbms.com.https.conf)

发布脚本只改 `/etc/nginx/conf.d/docs.geekbms.com.conf`，不动 www.geekbms.com 的配置。证书放在 `/etc/letsencrypt/`，脚本不删除证书。

- 已有 `fullchain.pem` 和 `privkey.pem`：安装 HTTPS 配置，跳过 certbot。
- 还没有证书：先用 HTTP 把 `/var/www/geekbms-docs/current` 发布出来，再申请一次（主机上没有 certbot 就用 apt 安装）：

  ```bash
  certbot certonly --non-interactive --agree-tos --email amzhy8@163.com \
    --webroot -w /var/www/geekbms-docs/current \
    --keep-until-expiring \
    -d docs.geekbms.com
  ```

  这是 webroot 模式，不会重写其他站点。成功后同一轮发布写入 HTTPS 配置并 reload。申请失败时站点留在 HTTP，已经发布的文件不会回滚。

**第一次切到 HTTPS：** 把包含这段逻辑的提交合并进 `main`（Deploy 会跟着跑），或合并之后对 `main` 手动跑 `workflow_dispatch`。同一次发布完成申请和切换，不用再登录服务器跑 certbot。

续期仍由服务器上的 certbot timer 负责。申请时登记了 `--deploy-hook`，只在这份证书续期成功后 reload nginx。

一次性准备：

1. **DNS**。给 `docs.geekbms.com` 加 A 记录，指向和 `www.geekbms.com` 相同的 IP。
2. **Secrets**。在本仓库的 GitHub Environment `production` 里放上下面三个，取值与 geekbms-web 的生产环境相同。不要把官网仓库里的其他密钥抄进来。
   - `ALIYUN_HOST`：服务器 IP 或主机名
   - `ALIYUN_USER`：SSH 用户
   - `ALIYUN_SSH_KEY`：私钥全文（含 BEGIN/END 行）
3. SSH 用户需要能无密码 `sudo -n` 执行发布脚本（写 `/var/www/geekbms-docs`、写 `/etc/nginx/conf.d/docs.geekbms.com.conf`、`apt-get install certbot`、`nginx -t` 和 reload）。用户本身是 root 也可以。主机上的 nginx 需要加载 `/etc/nginx/conf.d/*.conf`（发行版默认如此）。
4. 合并到 `main`，或合并后手动跑一次 Deploy。HTTP 已经在线时，这一轮会补上证书并切到 HTTPS。

## Gitee

当前以 GitHub 为源。Gitee 镜像可以以后再加。镜像加上之前，对外链接仍然用 https://docs.geekbms.com/ 。

## 许可证

文档默认 CC BY 4.0（见 `LICENSE`）。产品规格书若另有声明，以文件内页为准。

https://creativecommons.org/licenses/by/4.0/legalcode
