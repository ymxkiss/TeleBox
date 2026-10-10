# syntax=docker/dockerfile:1
# ============================================================================
# TeleBox 一键部署镜像
# 依据 https://github.com/TeleBoxOrg/TeleBox-Scripts 官方文档制作
#
# 镜像内完成: 拉取 TeleBox-Scripts(安装脚本仓库) -> 拉取 TeleBox 主体
#             (Classic / Next 二选一) -> npm install
# 工作目录: /app
#
# 构建:
#   Classic(默认): docker build -t telebox .
#   Next:         docker build --build-arg TELEBOX_EDITION=next -t telebox-next .
#
# 首次运行(交互式登录, 按提示填 api_id / api_hash, 成功后 Ctrl+C):
#   Classic:
#     mkdir -p data/plugins data/assets data/logs
#     docker run -it --name telebox \
#       -v $(pwd)/data/plugins:/app/telebox/plugins \
#       -v $(pwd)/data/assets:/app/telebox/assets \
#       -v $(pwd)/data/logs:/app/telebox/logs \
#       -v $(pwd)/data/config.json:/app/telebox/config.json \
#       telebox
#   Next: 把上面路径里的 telebox 换成 telebox-next, 镜像换成 telebox-next
#         (Next 会话保存在 assets/session.db, 无需挂载 config.json)
#
# 后台常驻:
#   docker run -d --name telebox --restart unless-stopped \
#     -v $(pwd)/data/plugins:/app/telebox/plugins \
#     -v $(pwd)/data/assets:/app/telebox/assets \
#     -v $(pwd)/data/logs:/app/telebox/logs \
#     -v $(pwd)/data/config.json:/app/telebox/config.json \
#     telebox
#   查看日志: docker logs -f telebox
# ============================================================================

ARG DEBIAN_TAG=12-slim
FROM debian:${DEBIAN_TAG}

LABEL org.opencontainers.image.title="TeleBox" \
      org.opencontainers.image.description="TeleBox Telegram Userbot (Classic/Next) 一键部署镜像" \
      org.opencontainers.image.source="https://github.com/TeleBoxOrg/TeleBox-Scripts"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Shanghai

# classic | next
ARG TELEBOX_EDITION=classic
ARG TELEBOX_SCRIPTS_REPO=https://github.com/TeleBoxOrg/TeleBox-Scripts.git
ARG NODE_MAJOR=24

# ---- 系统依赖 + Node.js ----
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg git \
        build-essential python3 tzdata; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone; \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    node -v && npm -v; \
    apt-get purge -y --auto-remove gnupg || true; \
    rm -rf /var/lib/apt/lists/*; \
    npm cache clean --force || true

WORKDIR /app

# ---- 拉取 TeleBox-Scripts(安装脚本仓库)到 /app ----
RUN set -eux; \
    git clone --depth 1 "${TELEBOX_SCRIPTS_REPO}" /tmp/telebox-scripts; \
    cp -a /tmp/telebox-scripts/. /app/; \
    rm -rf /tmp/telebox-scripts /app/.git

# ---- 拉取 TeleBox 主体并安装依赖 ----
# classic -> /app/telebox, next -> /app/telebox-next
RUN set -eux; \
    case "${TELEBOX_EDITION}" in \
        classic) TB_REPO="https://github.com/TeleBoxOrg/TeleBox.git" ;; \
        next)    TB_REPO="https://github.com/TeleBoxOrg/TeleBox-Next.git" ;; \
        *) echo "ERROR: TELEBOX_EDITION must be 'classic' or 'next'"; exit 1 ;; \
    esac; \
    TB_DIR="$(basename "${TB_REPO}" .git | tr 'A-Z' 'a-z')"; \
    echo "Cloning ${TB_REPO} -> /app/${TB_DIR}"; \
    git clone --depth 1 "${TB_REPO}" "/app/${TB_DIR}"; \
    cd "/app/${TB_DIR}"; \
    npm install; \
    npm cache clean --force || true; \
    mkdir -p plugins assets temp logs; \
    [ -f .env-sample ] && [ ! -f .env ] && cp .env-sample .env || true; \
    echo "${TB_DIR}" > /app/.telebox-dir; \
    rm -rf "/app/${TB_DIR}/.git"

# ---- 入口脚本: 进入对应版本目录后 npm start ----
RUN cat > /usr/local/bin/entrypoint.sh <<'EOS' \
 && chmod +x /usr/local/bin/entrypoint.sh
#!/bin/sh
set -e
TB_DIR="$(cat /app/.telebox-dir 2>/dev/null || echo telebox)"
cd "/app/${TB_DIR}"
exec npm start
EOS

# 可映射到本机的目录:
#   plugins - 用户插件(.tpm 安装到这里)
#   assets  - 运行时数据; Next 的会话(session.db)也在此
#   logs    - 日志
# Classic 的配置与会话在项目根目录 config.json, 需单独以文件形式挂载:
#   -v ./config.json:/app/telebox/config.json
VOLUME ["/app/telebox/plugins", "/app/telebox/assets", "/app/telebox/logs", \
        "/app/telebox-next/plugins", "/app/telebox-next/assets", "/app/telebox-next/logs"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
