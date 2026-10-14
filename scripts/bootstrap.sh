#!/usr/bin/env bash
# 服务器端一次性初始化：把 landingpage 目录接进 Caddy
#
# 只做两件事：
#   1. 在 compose 的 caddy 服务里加一条 volume 挂载（幂等，已存在则跳过）
#   2. docker compose up -d caddy —— 重建容器以应用新挂载，
#      同时让 Caddy 重新读取 Caddyfile 并为新子域名申请证书
#
# 刻意不做的事：
#   - 不改 Caddyfile 里的既有内容（博客主站、umami 反代、HTTP→HTTPS 重定向块原样保留）
#   - 不重启 umami / db
#
# 前置条件：Caddyfile 里必须已经有 DEPLOY_SITE_HOST 的 site 块。
# 本脚本会检查这一条，不满足就中止——Caddyfile 是你和服务器共同维护的文件，
# 由脚本去改它迟早会和人工编辑打架。手工加 site 块的步骤见 deploy/README.md 第 3 步。
#
# 用法:
#   bash scripts/bootstrap.sh            # 执行
#   bash scripts/bootstrap.sh --dry-run  # 只打印将要做的改动，不落盘
#
# 幂等：重复执行安全。挂载已存在时跳过修改，但仍会执行 compose up（用于重启后重试）。
set -euo pipefail
cd "$(dirname "$0")/.."

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    -h|--help)    sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "未知参数: $arg（仅支持 --dry-run）" >&2; exit 2 ;;
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

SSH_ARGS=(-p "${DEPLOY_SSH_PORT}" -o StrictHostKeyChecking=accept-new)
if [[ -n "${DEPLOY_SSH_KEY:-}" ]]; then
  SSH_ARGS+=(-i "${DEPLOY_SSH_KEY}" -o IdentitiesOnly=yes)
fi

# 远端执行：读操作用 heredoc 传脚本，写操作统一走下面显式的 sftp/rsync
ssh_exec() {
  # shellcheck disable=SC2029
  ssh "${SSH_ARGS[@]}" "${DEPLOY_USER}@${DEPLOY_HOST}" "$@"
}

TARGET="${DEPLOY_USER}@${DEPLOY_HOST}"
COMPOSE="${DEPLOY_REMOTE_ROOT}/docker-compose.yml"
MOUNT_LINE="${DEPLOY_PATH}:${DEPLOY_CONTAINER_ROOT}:ro"
MOUNT_ANCHOR="/srv/blog:ro"   # 新挂载插在这一行之后

echo "目标: ${TARGET}:${DEPLOY_REMOTE_ROOT}"
echo ""

# --- 前置检查：Caddyfile 必须已有 site 块，否则 compose up 后站点仍会 404 ---
if ! ssh_exec "grep -qF '${DEPLOY_SITE_HOST}' '${DEPLOY_REMOTE_ROOT}/Caddyfile'"; then
  echo "错误: ${DEPLOY_REMOTE_ROOT}/Caddyfile 里没有 ${DEPLOY_SITE_HOST} 的 site 块" >&2
  echo "" >&2
  echo "请先手工按 deploy/README.md 第 3 步加上："
  echo ""
  echo "  ${DEPLOY_SITE_HOST} {"
  echo "      root * ${DEPLOY_CONTAINER_ROOT}"
  echo "      encode zstd gzip"
  echo "      file_server"
  echo "      header { Cache-Control \"no-cache\" }"
  echo "  }"
  echo "" >&2
  echo "加完再跑一次本脚本。" >&2
  exit 1
fi
echo "✓ Caddyfile 已有 ${DEPLOY_SITE_HOST} 的 site 块"

# --- 步骤 1: 建目录 ---
if ssh_exec "test -d '${DEPLOY_PATH}'"; then
  echo "✓ 目录已存在: ${DEPLOY_PATH}"
else
  echo "→ 创建目录: ${DEPLOY_PATH}"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    ssh_exec "mkdir -p '${DEPLOY_PATH}'"
  fi
fi

# --- 步骤 2: 加 volume 挂载（幂等）---
if ssh_exec "grep -qF '${MOUNT_LINE}' '${COMPOSE}'"; then
  echo "✓ 挂载已存在，跳过: ${MOUNT_LINE}"
else
  echo "→ 将在 ${MOUNT_ANCHOR} 之后插入: ${MOUNT_LINE}"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    BACKUP="${COMPOSE}.bak.$(date +%Y%m%d%H%M%S)"
    ssh_exec "cp '${COMPOSE}' '${BACKUP}' && echo '  已备份: ${BACKUP}' >&2"
    # 在博客挂载行之后插入新挂载，保留仓库既有的注释与缩进风格
    ssh_exec "awk -v mount='${MOUNT_LINE}' -v anchor='${MOUNT_ANCHOR}' '
      !done && index(\$0, anchor) {
        print
        print \"      # Browser Bridge 落地页：独立目录，与博客 public/ 隔离\"
        print \"      # 由 browser-bridge-landingpage 仓库 scripts/bootstrap.sh 生成\"
        print \"      - \" mount
        done = 1
        next
      }
      { print }
    ' '${COMPOSE}' > '${COMPOSE}.tmp' && mv '${COMPOSE}.tmp' '${COMPOSE}'"

    # 用 compose 自己校验 YAML 合法性 + 确认挂载真的进去了
    ssh_exec "cd '${DEPLOY_REMOTE_ROOT}' && docker compose --env-file .env config --quiet && grep -qF '${MOUNT_LINE}' docker-compose.yml" \
      || { echo "错误: 修改后的 compose 校验失败或挂载未生效，已保留备份 ${BACKUP}" >&2; exit 1; }
    echo "✓ 挂载已添加并通过 compose 校验"
  fi
fi

# --- 步骤 3: 重建 caddy 容器（应用新挂载 + 重新读取 Caddyfile）---
echo ""
echo "→ docker compose up -d caddy（博客会短暂中断几秒）"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] 未执行 compose up"
  echo ""
  echo "[dry-run] 完成后请依次确认："
  echo "  1) cd ${DEPLOY_REMOTE_ROOT} && docker compose logs caddy | grep -i certificate"
  echo "  2) dig +short ${DEPLOY_SITE_HOST} A"
  echo "  3) curl -sI https://${DEPLOY_SITE_HOST}/ | head -1"
  echo "  4) bash scripts/deploy.sh   # 推静态文件"
  exit 0
fi

ssh_exec "cd '${DEPLOY_REMOTE_ROOT}' && docker compose --env-file .env up -d caddy"

# --- 收尾校验 ---
echo ""
echo "→ 校验容器内是否已挂载 ${DEPLOY_CONTAINER_ROOT}"
if ssh_exec "cd '${DEPLOY_REMOTE_ROOT}' && docker compose --env-file .env exec -T caddy test -d '${DEPLOY_CONTAINER_ROOT}'"; then
  echo "✓ 容器内 ${DEPLOY_CONTAINER_ROOT} 已就绪"
else
  echo "✗ 容器内 ${DEPLOY_CONTAINER_ROOT} 不存在，检查上面的 compose 输出" >&2
  exit 1
fi

echo ""
echo "初始化完成。后续："
echo "  1) 看证书签发结果: cd ${DEPLOY_REMOTE_ROOT} && docker compose logs caddy | grep -i certificate"
echo "  2) 推静态文件:     bash scripts/deploy.sh"
echo "  3) 验证上线:       curl -sI https://${DEPLOY_SITE_HOST}/ | head -1"
echo ""
echo "若证书没签下来（日志报超时），等几分钟再执行："
echo "  cd ${DEPLOY_REMOTE_ROOT} && docker compose restart caddy"
