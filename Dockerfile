# 基础镜像：Node.js 24 + Debian 12 Bookworm，预装 Node.js 避免 NodeSource 脚本问题
FROM node:24-bookworm-slim

# 步骤1：安装基础工具（curl, ca-certificates, git, build-essential）
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# 步骤2：设置工作目录
WORKDIR /root/telebox

# 步骤3：克隆项目
RUN git clone --depth 1 https://github.com/TeleBoxOrg/TeleBox.git .

# 步骤4：安装项目依赖
RUN npm ci --ignore-scripts && \
    # 重新编译原生模块以适配系统 GLIBC
    npm rebuild && \
    # 特别处理 better-sqlite3
    cd node_modules/better-sqlite3 && npm run build-release || true

# 步骤5：安装 PM2 进程管理器（全局安装）
RUN npm install -g pm2 && \
    pm2 install pm2-logrotate

# 创建必要目录
RUN mkdir -p /root/telebox/assets /root/telebox/data /root/telebox/plugins /root/telebox/logs /root/telebox/temp

# 数据持久化卷
VOLUME ["/root/telebox/assets", "/root/telebox/data", "/root/telebox/plugins", "/root/telebox/logs"]

# 环境变量
ENV NODE_ENV=production
ENV TB_PREFIX=. 。
ENV TB_SUDO_PREFIX=# $

# 启动命令
CMD ["pm2-runtime", "exec", "npm", "--", "start"]
