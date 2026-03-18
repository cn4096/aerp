# syntax=docker/dockerfile:1

# 使用 Alpine 作为基础镜像
FROM alpine:latest

# 安装必要的运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    libc6-compat \
    && rm -rf /var/cache/apk/*

# 创建非 root 用户
RUN adduser -D -u 1000 user
USER user

# 设置工作目录
ENV HOME=/home/user
WORKDIR $HOME/app

# 将所有可执行文件复制到容器内
COPY --chown=user . .

# --- 关键部分：动态查找并准备可执行文件 ---
# 根据 TARGETOS 和 TARGETARCH 环境变量，找到匹配的文件名
# 例如，在构建 linux/amd64 时，$TARGETPLATFORM = "linux/amd64"
# 我们用 sed 将 "linux/amd64" 转换成 "linux-amd64-x64" 的格式
RUN \
    # 构建目标文件名
    target_file=$(ls erp-${TARGETOS}-${TARGETARCH}* | head -n 1) && \
    echo "Selected file for ${TARGETPLATFORM}: $target_file" && \
    # 将其重命名为一个通用名称，方便 CMD 执行
    mv "$target_file" erp-binary && \
    # 赋予可执行权限
    chmod +x erp-binary

# 声明服务端口
EXPOSE 8080

# 启动命令，统一指向重命名后的文件
CMD ["./erp-binary"]
