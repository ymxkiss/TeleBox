# 基础镜像选择Ubuntu 22.04（稳定且常用）
FROM ubuntu:22.04

# 设置非交互模式，避免apt安装时的交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 步骤1：更新系统并安装基础工具
RUN apt update && \
    apt install -y curl git build-essential && \
    # 清理apt缓存，减小镜像体积
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 步骤2：安装Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    # 验证安装（可选，用于构建时检查）
    node --version && \
    npm --version && \
    # 清理apt缓存
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 步骤3：克隆项目（设置工作目录为/root/telebox）
WORKDIR /root/telebox
RUN git clone https://github.com/TeleBoxDev/TeleBox.git .

# 步骤4：安装项目依赖
RUN npm install

# 步骤6：安装PM2进程管理器
RUN npm install -g pm2 && \
    # 安装日志轮转插件
    pm2 install pm2-logrotate

# 暴露可能需要的端口（根据项目实际需求，这里仅作为示例）
# EXPOSE 3000

# 启动命令：使用pm2-runtime（适合容器环境的PM2运行模式）
# 注意：首次启动需要先执行`npm start`完成配置，再用PM2管理
CMD ["pm2-runtime", "start", "npm", "--name", "telebox", "start"]
