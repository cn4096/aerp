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

# ✅ 关键修复：必须在 FROM 之后显式声明这些变量，RUN 步骤才能读到值
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

# 将所有可执行文件复制到容器内
COPY --chown=user . .

# 动态查找并准备可执行文件
RUN <<EOF
#!/bin/sh
set -e

echo "Building for platform: $TARGETPLATFORM"
echo "=== 当前目录文件 ==="
ls -la

# 根据 TARGETPLATFORM 映射到实际的文件名
case "$TARGETPLATFORM" in
  "linux/amd64")
    FILE_PATTERN="erp-linux-amd64-x64"
    ;;
  "linux/arm64"|"linux/aarch64")
    FILE_PATTERN="erp-linux-arm64-arm64"  # ⚠️ 请确认你的实际文件名
    ;;
  *)
    echo "Unsupported platform: $TARGETPLATFORM"
    exit 1
    ;;
esac

# 检查文件是否存在
if [ ! -f "$FILE_PATTERN" ]; then
  echo "Error: Could not find binary: $FILE_PATTERN"
  exit 1
fi

echo "Found binary: $FILE_PATTERN"
cp "$FILE_PATTERN" erp-binary
chmod +x erp-binary
echo "Successfully prepared erp-binary for $TARGETPLATFORM"
EOF

# 声明服务端口
EXPOSE 8080

# 启动命令
CMD ["./erp-binary"]
