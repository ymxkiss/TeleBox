# TeleBox Docker Deployment
# Telegram UserBot Framework
# Base: Debian 12 (Bookworm) + Node.js 24

FROM debian:12-slim

# 设置非交互模式，避免 apt 安装时的交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 步骤1：更新系统并安装基础工具
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    sudo \
    build-essential \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# 步骤2：安装 Node.js 24.x
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    node --version && \
    npm --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 步骤3：设置工作目录
WORKDIR /app

# 步骤4：克隆 TeleBox 项目
RUN git clone --depth 1 https://github.com/TeleBoxOrg/TeleBox.git .

# 步骤5：安装项目依赖
RUN npm ci --ignore-scripts && \
    # 重新编译原生模块以适配 Debian 12 的 GLIBC 2.36
    npm rebuild && \
    cd node_modules/better-sqlite3 && npm run build-release || true

# 步骤6：复制项目文件（确保完整）
RUN cp -r . /app 2>/dev/null || true

# 步骤7：安装 PM2 进程管理器
RUN npm install -g pm2 && \
    pm2 install pm2-logrotate

# 创建数据目录
RUN mkdir -p /app/data /app/assets /app/plugins /app/logs

# 持久化卷
VOLUME ["/app/data", "/app/assets", "/app/plugins", "/app/logs"]

# 环境变量
ENV NODE_ENV=production

# 启动命令
CMD ["npm", "start"]
