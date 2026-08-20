# TeleBox Docker Deployment
# Telegram UserBot Framework
# Base: Node.js 24 + Debian Trixie

FROM node:24-slim

# 安装编译原生模块所需的系统依赖
# sharp, canvas, better-sqlite3 需要 build-essential 和 python3
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python3 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 克隆 TeleBox 项目
RUN git clone --depth 1 https://github.com/TeleBoxOrg/TeleBox.git .

# 安装项目依赖（包含原生模块）
RUN npm ci

# 重新编译原生模块以适配当前系统的 GLIBC 版本
# better-sqlite3@13+ 需要 GLIBC 2.38+, Debian 12 提供 2.36
RUN npm rebuild

# 安装 PM2 用于生产环境进程管理
RUN npm install -g pm2 && pm2 install pm2-logrotate

# 创建数据目录
RUN mkdir -p /app/data /app/assets /app/plugins /app/logs

# 持久化卷
VOLUME ["/app/data", "/app/assets", "/app/plugins", "/app/logs"]

# 环境变量
ENV NODE_ENV=production

# 暴露端口（如需要 HTTP API）
# EXPOSE 3000

# 启动命令
CMD ["npm", "start"]
