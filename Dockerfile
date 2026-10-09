# syntax=docker/dockerfile:1
# node:24-bookworm-slim is based on Debian 12 (Bookworm) slim.
FROM node:24-bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3 \
    make \
    g++ \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch main https://github.com/TeleBoxOrg/TeleBox.git /opt/telebox
WORKDIR /opt/telebox
RUN npm ci --include=dev --no-audit --no-fund

FROM node:24-bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    libcairo2 \
    libpango-1.0-0 \
    libjpeg62-turbo \
    libgif7 \
    librsvg2-2 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && install -d -o node -g node /state

COPY --from=build --chown=node:node /opt/telebox /opt/telebox
WORKDIR /opt/telebox
VOLUME ["/state"]
USER node

# 创建数据目录
# RUN mkdir -p /opt/telebox/data /opt/telebox/assets /opt/telebox/plugins /opt/telebox/logs

# 持久化卷
# VOLUME ["/opt/telebox","/opt/telebox/data", "/opt/telebox/assets", "/opt/telebox/plugins", "/opt/telebox/logs"]

# Keep mutable configuration and runtime data on /state without requiring a
# separate entrypoint file. First-time Telegram login is performed in the terminal.
ENTRYPOINT ["/bin/sh", "-c", "set -eu; app=/opt/telebox; state=/state; mkdir -p \"$state\"; for path in config.json .env plugins assets temp my_session .plugin-cache pmcaptcha_userdata; do case \"$path\" in config.json|.env) ;; *) mkdir -p \"$state/$path\" ;; esac; rm -rf \"$app/$path\"; ln -s \"$state/$path\" \"$app/$path\"; done; cd \"$app\"; exec \"$@\"", "--"]
CMD ["npm", "start"]
