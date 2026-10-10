FROM node:24-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        build-essential \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# 按安装文档克隆项目；容器启动时可初始化空的宿主机挂载目录。
RUN git clone --depth 1 --branch main https://github.com/TeleBoxOrg/TeleBox.git /opt/telebox \
    && test -f /opt/telebox/package.json

WORKDIR /app

CMD ["sh", "-ec", "if [ ! -f /app/package.json ]; then cp -a /opt/telebox/. /app/; fi; if [ ! -f /app/package.json ]; then echo 'ERROR: /app/package.json is missing; check the bind mount and rebuild this image.' >&2; exit 1; fi; if [ ! -d /app/node_modules ]; then npm install; fi; exec npm start"]
