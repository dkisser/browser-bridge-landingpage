#!/usr/bin/env bash
# 本地一键部署：把静态站 rsync 推送到 Caddy 所在服务器的落地页目录
#
# 用法:
#   bash scripts/deploy.sh              # 前置检查 + 部署
#   bash scripts/deploy.sh --dry-run    # 前置检查 + rsync 预览（-n --itemize-changes），不实际传输
#   bash scripts/deploy.sh --skip-check # 跳过前置检查（首次部署、或服务器配置刚手工改完还没生效时）
#
# 部署参数从项目根 .env 读取（模板见 .env.example）。
# 本脚本只负责传输静态文件；服务器端的 Caddyfile / docker-compose.yml 改动
# 是一次性的手工操作，步骤见 deploy/README.md，权威副本维护在 paul_blog 仓库。
set -euo pipefail
cd "$(dirname "$0")/.."

DRY_RUN=0
SKIP_CHECK=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --skip-check)  SKIP_CHECK=1 ;;
    -h|--help)     sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "未知参数: $arg（支持 --dry-run / --skip-check）" >&2; exit 2 ;;
  esac
done

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
else
  echo "错误: 未找到 .env，请从 .env.example 复制一份并填入真实值" >&2
  exit 1
fi

: "${DEPLOY_HOST:?缺少 DEPLOY_HOST（见 .env.example）}"
: "${DEPLOY_USER:?缺少 DEPLOY_USER（见 .env.example）}"
: "${DEPLOY_PATH:?缺少 DEPLOY_PATH（见 .env.example）}"
: "${DEPLOY_SITE_HOST:?缺少 DEPLOY_SITE_HOST（见 .env.example）}"
: "${DEPLOY_CONTAINER_ROOT:?缺少 DEPLOY_CONTAINER_ROOT（见 .env.example）}"
: "${DEPLOY_REMOTE_ROOT:?缺少 DEPLOY_REMOTE_ROOT（见 .env.example）}"
DEPLOY_SSH_PORT="${DEPLOY_SSH_PORT:-22}"

# ---------------------------------------------------------------------------
# rsync 排除列表：仓库根目录里除了站点本身，还有 git 元数据和运维文件，
# 这些绝不能混进 Web 根目录（.env 里有服务器地址、用户名和私钥路径）。
# / 前缀把这些排除锚定在传输根，避免误伤 assets/ 下的同名文件。
# 注意：rsync 的 --delete 不会删除接收端被 --exclude 排除的文件，这是有意为之。
# ---------------------------------------------------------------------------
RSYNC_EXCLUDES=(
  --exclude='/.git/'
  --exclude='/.gitignore'
  --exclude='/.env'
  --exclude='/.env.*'
  --exclude='/README.md'
  --exclude='/AGENTS.md'
  --exclude='/CONTEXT.md'
  --exclude='/docs/'
  --exclude='/deploy/'
  --exclude='/scripts/'
  --exclude='.DS_Store'
)

SSH_ARGS=(-p "${DEPLOY_SSH_PORT}" -o StrictHostKeyChecking=accept-new)
if [[ -n "${DEPLOY_SSH_KEY:-}" ]]; then
  SSH_ARGS+=(-i "${DEPLOY_SSH_KEY}" -o IdentitiesOnly=yes)
fi

ssh_exec() {
  # 调用方传的是一整条已本地引用的命令串（含单引号包裹的路径），不做客户端二次展开。
  # shellcheck disable=SC2029
  ssh "${SSH_ARGS[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" "$@"
}

# ---------------------------------------------------------------------------
# 前置检查：一次 SSH 连接跑完所有检查，避免多次往返。
# 检查项对应 paul_blog 的既有部署约定：
#   1. rsync 目标目录必须已存在（Caddy 要挂载它）
#   2. Caddyfile 必须有该子域名的 site 块
#   3. Caddyfile 必须把容器内根指向 DEPLOY_CONTAINER_ROOT
#   4. compose 的 mount 源路径必须等于 DEPLOY_PATH
#      （AGENTS.md:135 的硬约束：rsync 目标 == Caddy 挂载源）
# ---------------------------------------------------------------------------
preflight() {
  local report
  report="$(ssh_exec "cd '${DEPLOY_REMOTE_ROOT}' && {
      test -d '${DEPLOY_PATH}' && echo ok:dir        || echo fail:dir
      grep -qF '${DEPLOY_SITE_HOST}' Caddyfile       && echo ok:site       || echo fail:site
      grep -qF '${DEPLOY_CONTAINER_ROOT}' Caddyfile  && echo ok:root       || echo fail:root
      grep -qF '${DEPLOY_PATH}' docker-compose.yml    && echo ok:mount      || echo fail:mount
    }")" || {
    echo "错误: 无法 SSH 到 ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_SSH_PORT}" >&2
    return 1
  }

  local failures=()
  grep -qx 'ok:dir'   <<<"$report" || failures+=("服务器目录不存在：${DEPLOY_PATH}（见 deploy/README.md 第 2 步）")
  grep -qx 'ok:site'  <<<"$report" || failures+=("${DEPLOY_REMOTE_ROOT}/Caddyfile 里没有 ${DEPLOY_SITE_HOST} 这个 site 块")
  grep -qx 'ok:root'  <<<"$report" || failures+=("${DEPLOY_REMOTE_ROOT}/Caddyfile 里没有 ${DEPLOY_CONTAINER_ROOT}（容器内根目录）")
  grep -qx 'ok:mount' <<<"$report" || failures+=("${DEPLOY_REMOTE_ROOT}/docker-compose.yml 里没有挂载 ${DEPLOY_PATH}（rsync 目标必须等于 Caddy 挂载源）")

  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "前置检查未通过：" >&2
    printf '  ✗ %s\n' "${failures[@]}" >&2
    echo "" >&2
    echo "服务器端配置是手工维护的一次性操作，步骤见 deploy/README.md。" >&2
    echo "确认已完成后再跑一次，或用 --skip-check 强制跳过。" >&2
    return 1
  fi
  echo "[check] 通过：目录 / site 块 / 容器根 / 挂载 均已就绪"
}

if [[ "$SKIP_CHECK" -eq 0 ]]; then
  echo "[check] 连接 ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_SSH_PORT} 检查服务器配置…"
  preflight
else
  echo "[check] 已跳过（--skip-check）"
fi

RSYNC_ARGS=(-az --delete "${RSYNC_EXCLUDES[@]}" -e "ssh ${SSH_ARGS[*]}")
if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_ARGS+=(-n --itemize-changes)
  echo "[dry-run] 仅预览，不实际传输"
fi

echo "rsync ./ -> ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH} (端口 ${DEPLOY_SSH_PORT})"
rsync "${RSYNC_ARGS[@]}" ./ "${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] 完成（未做任何远端变更）"
else
  echo "部署完成：https://${DEPLOY_SITE_HOST}"
fi
