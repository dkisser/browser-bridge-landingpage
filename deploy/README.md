# 服务器部署指南（browser-bridge 落地页）

与博客 `dkisser.cn` 共用同一台服务器、同一个 Caddy 容器，但**独立的域名和独立的目录**，
日常部署互不影响。

## 架构

```
公网
 └─ 80/443 → Caddy ── dkisser.cn              → /srv/blog       （静态博客，paul_blog 仓库推送）
                 ├ stats.dkisser.cn          → umami:3000     （统计采集端点，其余 404）
                 └ browser-bridge.dkisser.cn → /srv/landingpage（本站，本仓库推送）

宿主机对应关系：
  /home/paul/blog/public      → /srv/blog        （paul_blog 仓库的 DEPLOY_PATH）
  /home/paul/landingpage      → /srv/landingpage （本仓库的 DEPLOY_PATH）
```

## 一、一次性初始化

> 只有换服务器或重建环境时才需要重做一遍。
> 脚本：`scripts/bootstrap.sh`，参数从根目录 `.env` 读取。

### 1. 配置 DNS（必须手工，阿里云控制台）

`dkisser.cn` 的 NS 是 `dns11/dns12.hichina.com`，添加：

| 类型 | 主机记录 | 记录值 | TTL |
|---|---|---|---|
| A | `browser-bridge` | `114.215.198.209` | 默认 |

```bash
dig +short browser-bridge.dkisser.cn A   # 应返回 114.215.198.209
```

### 2. 加 Caddyfile 的 site 块（必须手工）

编辑服务器上的 `/home/paul/blog/Caddyfile`，追加到文件末尾：

```caddyfile
# (c) Browser Bridge 落地页：独立目录，与博客互不影响
browser-bridge.dkisser.cn {
	root * /srv/landingpage
	encode zstd gzip
	file_server
	# 该站的资源文件名不带内容哈希，给长缓存会导致改完样式用户仍看到旧版，
	# 因此统一 no-cache（每次校验，而非直接禁用缓存）
	header {
		Cache-Control "no-cache"
	}
}
```

**为什么这步是手工的**：Caddyfile 是你平时也在维护的共享文件，`bootstrap.sh` 只检查它是否
已就位，不会去改它——脚本改共享配置迟早会和人工编辑打架。权威副本同步到 `paul_blog`
仓库的 `deploy/Caddyfile`。

> 顺带一提：服务器那份 Caddyfile 目前还缺仓库里的 `(a0)` HTTP→HTTPS 重定向块，
> 所以三个域名现在走的是 Caddy 默认的 308，而仓库里写的是 301。这是既有的分叉，
> 与本次落地页无关，本次不动它。

### 3. 跑 bootstrap

```bash
cp .env.example .env      # 首次，填好真实值
bash scripts/bootstrap.sh --dry-run   # 先看它打算做什么
bash scripts/bootstrap.sh
```

它做三件事，幂等、可重复执行：

1. `mkdir -p /home/paul/landingpage`（已存在则跳过）
2. 在 compose 的 caddy 服务里、博客挂载之后插入 `/home/paul/landingpage:/srv/landingpage:ro`
   （已存在则跳过；改前自动备份成 `docker-compose.yml.bak.<时间戳>`，改后用
   `docker compose config` 校验 YAML 合法性）
3. `docker compose up -d caddy` —— **这一步是关键**：`./Caddyfile` 是 `:ro` 挂进容器的，
   改完文件不会自动生效，必须重建容器 Caddy 才会重读配置并申请证书
4. 校验容器内 `/srv/landingpage` 是否真的出现了

它**不会**碰 Caddyfile 的既有内容，也不会重启 umami / db。博客会中断几秒。

### 4. 推文件并验证

```bash
bash scripts/deploy.sh
curl -sI https://browser-bridge.dkisser.cn/ | head -1   # 期望 200
```

## 二、日常部署

```bash
bash scripts/deploy.sh
```

`deploy.sh` 先做前置检查，任一不满足就中止并打印该补什么：

| 检查项 | 为什么 |
|---|---|
| `DEPLOY_PATH` 目录存在 | Caddy 要挂载它 |
| Caddyfile 有该子域 site 块 | 否则站点 404 |
| site 块的 `root` 指向 `DEPLOY_CONTAINER_ROOT` | 否则 Caddy 指向错误路径 |
| compose 挂了 `DEPLOY_PATH` | **rsync 目标必须等于 Caddy 挂载源**，这是 paul_blog 的既有硬约束 |

这个检查拦的是"rsync 推成功了、脚本说部署完成、站点其实 404"——没有它，这种情况是静默的。

### 常用参数

| 参数 | 适用脚本 | 作用 |
|---|---|---|
| `--dry-run` / `-n` | 两个 | 预览，不落盘 |
| `--skip-check` | `deploy.sh` | 跳过前置检查 |

## 三、排错

**证书没签下来**

```bash
cd /home/paul/blog && docker compose logs caddy | grep -i certificate
```

备案已通过（浙ICP备2026075269号），首次签发偶发失败是常见的，等几分钟再
`docker compose restart caddy` 重试。

> 日志里可能有一批历史 `tls-alpn challenge ... server_name:""` 错误，横跨数周、`server_name`
> 为空，跟本子域无关，可以忽略。

**改了 Caddyfile 但没生效**

`./Caddyfile` 是 `:ro` bind mount 进容器的。**改文件不会让运行中的 Caddy 重读配置**，
必须 `docker compose restart caddy` 或 `docker compose up -d caddy`。

**相对路径 404**

本站全部资源用相对路径（`assets/...`、`styles.css`、`app.js`），没有 `<base>` 标签。
所以子域名必须是域名的**根**（`browser-bridge.dkisser.cn/`），不能挂在子路径下——
挂子路径的话相对路径基准会跑到主站去。
