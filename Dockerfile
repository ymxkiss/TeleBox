# 基础镜像：Debian 12 (Bookworm)，稳定且轻量
FROM debian:12-slim

# 设置非交互模式，避免 apt 安装时的交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 步骤1：更新系统并安装基础工具（包含 curl ca-certificates gnupg sudo）
RUN apt-get update && \
    apt-get install -y \
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
    # 验证安装
    node --version && \
    npm --version && \
    # 清理 apt 缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 步骤3：克隆项目（设置工作目录为 /root/telebox）
WORKDIR /root/telebox
RUN git clone --depth 1 https://github.com/TeleBoxOrg/TeleBox.git .

# 步骤4：安装项目依赖
RUN npm ci --ignore-scripts && \
    # 重新编译原生模块以适配 Debian 12 的 GLIBC 2.36
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

# 暴露端口
# EXPOSE 3000

# 启动命令
# 注意：首次启动需要先执行 npm start 完成交互配置，再用 PM2 管理
CMD ["pm2-runtime", "exec", "npm", "--", "start"]
