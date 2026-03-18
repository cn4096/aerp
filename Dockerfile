# 使用 Alpine 作为基础镜像
FROM alpine:latest

# 安装必要的运行时依赖
# ca-certificates: 用于验证 SSL 证书
# libc6-compat: 提供一些兼容性库，对某些应用（尤其是 Go 应用）可能是必要的
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

# 复制文件到容器内，并自动赋予非 root 用户权限
COPY --chown=user . $HOME/app

# 赋予二进制文件可执行权限
RUN chmod +x $HOME/app/erp-linux-amd64-x64

# 声明服务端口
EXPOSE 8080

# 启动命令
CMD ["./erp-linux-amd64-x64"]
