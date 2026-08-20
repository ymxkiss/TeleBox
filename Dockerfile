# TeleBox Docker Deployment
# Telegram UserBot Framework
# Base: Debian 12 (Bookworm) + Node.js 24
# Fix: Remove ARM64 prebuilt binaries that require GLIBC 2.38+

FROM debian:12-slim

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 步骤1：安装基础工具和编译依赖
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    sudo \
    build-essential \
    git \
    python3 \
    cmake \
    make \
    gcc \
    g++ \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# 步骤2：安装 Node.js 24.x
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    node --version && \
    npm --version

# 步骤3：设置工作目录
WORKDIR /app

# 步骤4：克隆 TeleBox 项目
RUN git clone --depth 1 https://github.com/TeleBoxOrg/TeleBox.git .

# 步骤5：安装依赖（跳过预编译脚本）
RUN npm ci --ignore-scripts --no-optional

# 步骤6：删除 ARM64 预编译二进制（需要 GLIBC 2.38+，系统只有 2.36）
RUN rm -rf node_modules/better-sqlite3/prebuilds

# 步骤7：从源码重新编译所有原生模块
RUN npm rebuild && \
    cd node_modules/better-sqlite3 && \
    npm run build-release || \
    node-gyp rebuild || \
    echo "Compilation attempted"

# 步骤8：安装 PM2
RUN npm install -g pm2 && \
    pm2 install pm2-logrotate

# 创建数据目录
RUN mkdir -p /app/data /app/assets /app/plugins /app/logs

# 持久化卷
VOLUME ["/app","/app/data", "/app/assets", "/app/plugins", "/app/logs"]

# 环境变量
ENV NODE_ENV=production

# 启动命令
CMD ["npm", "start"]
