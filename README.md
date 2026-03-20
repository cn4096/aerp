

# Aico 仓库 (aiwarehouse)

一个轻量级的 Go WebDAV 文件服务器，内置 OTA 固件管理，支持管理员认证、Guest 隔离目录、自动清理等功能。单个二进制文件，无需安装数据库。

---

## 目录

- [功能概览](#功能概览)
- [快速开始](#快速开始)
- [目录结构](#目录结构)
- [管理员设置](#管理员设置)
- [WebDAV 使用](#webdav-使用)
- [OTA 固件管理](#ota-固件管理)
- [API 接口](#api-接口)
- [构建说明](#构建说明)

---

## 功能概览

| 功能 | 说明 |
|------|------|
| **WebDAV 协议** | 支持文件上传、下载、浏览、重命名、删除、创建目录 |
| **网页文件管理** | 响应式界面，支持拖放上传、文件预览（Markdown/代码） |
| **管理员认证** | 首次登录设置密码，Cookie 长期有效（1024 天） |
| **Guest 隔离** | 可开启 guest/guest 账号，限定在 `storage/guest/` 目录 |
| **OTA 管理** | 多 APP 固件版本管理，固定下载地址，SQLite 存储 |
| **自动清理** | 可配置 N 天自动删除旧文件（默认关闭） |
| **系统信息** | 查看 CPU、内存、磁盘、网络接口实时信息 |
| **网站名称** | 管理员可在线修改页面标题 |

---

## 快速开始

### Docker启动

+ 测试：`docker run --rm --network host ghcr.io/cn4096/aerp:latest`   `端口`：8080

+ 数据保存到本地并运行：
  
```
 ## 删除旧的容器，更新镜像
 docker stop claw_host-app ; docker rm claw_host-app

 ## 下载/更新镜像
 docker pull ghcr.io/cn4096/claw_host:latest

 ## 数据保存在当前目录/claw_host_data 访问端口:8880
 docker run -itd \
  --name claw_host-app \
  -p 8880:7860 \
  -v $(pwd)/claw_host_data:/home/user/app/data \
  ghcr.io/cn4096/claw_host:latest
  
```



### 1. 构建

```bash
# 克隆或解压源码后执行
go mod tidy
CGO_ENABLED=0 go build -o aiwarehouse .
```

或使用构建脚本（同时生成 Linux 和 Windows 版本）：

```bash
bash build.sh
```

### 2. 运行

```bash
./aiwarehouse
```

服务器启动后监听 `http://0.0.0.0:7860`。

### 3. 首次登录

1. 浏览器访问 `http://localhost:7860/`
2. 点击右上角 **管理员** 图标
3. 弹窗提示"首次登录，请设置管理密码"，输入密码后点击【设置密码并登录】
4. 密码保存在 `./data/conf/conf.json`，服务重启后不失效

> 也可直接访问 `http://localhost:7860/admin` 进入管理设置页面完成初始化。

---

## 目录结构

程序运行后自动创建以下目录：

```
data/
├── conf/
│   └── conf.json          # 配置文件（密码、设置等）
├── storage/               # WebDAV 文件存储根目录
│   └── guest/             # Guest 用户隔离目录
├── ota/                   # OTA 固件文件存储
│   └── <APP_ID>/          # 每个 APP 独立子目录
└── db/
    └── ota.db             # OTA 元数据 SQLite 数据库
```

### conf.json 结构

```json
{
  "admin_password_hash": "...",
  "session_token": "...",
  "site_name": "自定义网站名称",
  "webdav_enabled": true,
  "webdav_auth_required": false,
  "guest_upload": false,
  "auto_delete_days": 0
}
```

---

## 管理员设置

访问 `http://HOST/admin` 进入管理设置页面。

### 功能设置项

| 设置项 | 默认值 | 说明 |
|--------|--------|------|
| 网站名称 | 小龙虾仓库 | 显示在页面标题和页眉，留空恢复默认 |
| 启用 WebDAV | 开 | 关闭后 WebDAV 客户端无法连接 |
| WebDAV 写操作需要认证 | 关 | 开启后上传/删除需要 Basic Auth |
| 允许 Guest 上传 | 关 | 开启后允许 guest/guest 账号访问 |
| 自动删除文件（天） | 0 | 0 = 不删除；填 14 = 自动删除 14 天前的文件 |

### Guest 隔离模式

当同时开启 **WebDAV 写操作需要认证** 和 **允许 Guest 上传** 时：

- `admin` 账号（管理员密码）：可访问全部 `storage/` 目录
- `guest` 账号（密码固定为 `guest`）：仅能读写 `storage/guest/` 目录

### 修改密码

在管理设置页面【修改管理密码】卡片中操作，需要输入原密码验证。

### 登录状态

- 登录后 Cookie 有效期 **1024 天**
- Session Token 持久化保存在 `conf.json`，服务重启后不失效
- 主动点退出后 Token 失效，所有设备同步登出

---

## WebDAV 使用

### curl 命令行

```bash
# 无密码上传（未开启 WebDAV 认证时）
curl -T myfile.txt http://HOST/myfile.txt

# 有密码上传（开启 WebDAV 认证时）
curl -u admin:密码 -T myfile.txt http://HOST/myfile.txt

# 上传到指定目录（目录需提前创建）
curl -u admin:密码 -T firmware.bin http://HOST/releases/firmware.bin

# 创建目录
curl -u admin:密码 -X MKCOL http://HOST/releases/

# 删除文件
curl -u admin:密码 -X DELETE http://HOST/myfile.txt

# 下载文件（无需认证）
curl -O http://HOST/myfile.txt
wget http://HOST/myfile.txt
```

### 客户端挂载

| 系统 | 操作 |
|------|------|
| **Windows** | 文件资源管理器 → 此电脑 → 映射网络驱动器 → 输入 `http://HOST/` |
| **macOS** | Finder → 前往 → 连接服务器 → 输入 `http://HOST/` |
| **Linux** | `sudo mount -t davfs http://HOST/ /mnt/dav` |

> Windows 映射 WebDAV 需确保 WebClient 服务已启动，且建议开启 WebDAV 认证后使用。

---

## OTA 固件管理

访问 `http://HOST/ota/`（需管理员登录）。

### 概念说明

| 字段 | 说明 |
|------|------|
| **应用名称** | 显示用途，可中英文，例如：`我的设备固件` |
| **APP_ID** | 下载路径用，仅限 `^[A-Za-z0-9_]+$`，例如：`MyDevice` |
| **版本号** | 自由格式，例如：`v1.2.3`，上传时自动推算下一版本号 |

### 下载地址格式

```
# 最新版本（wget 直接保存原文件名）
wget http://HOST/ota/download/<APP_ID>/latest/<原文件名>

# 最新版本（不含文件名，浏览器/curl 兼容）
curl -OJ http://HOST/ota/download/<APP_ID>/latest

# 指定版本 ID（版本 ID 从 OTA 管理页面查看）
wget http://HOST/ota/download/<APP_ID>/42/firmware_v1.0.bin
```

> 末尾的文件名是**装饰性路径段**，服务端忽略它，实际保存的文件名始终以上传时的原始文件名为准（通过 `Content-Disposition` 响应头）。不带文件名的旧链接永久兼容。

### 上传固件

**网页上传：**
1. 进入 `http://HOST/ota/`
2. 点击右上角【+ 上传固件】
3. 填写应用名称、APP_ID、版本号，选择文件，点击上传

**curl 上传（不支持，请使用网页）**

### 版本管理

- 每次上传同名 APP_ID 的文件，系统保存到独立路径，不覆盖历史版本
- 版本列表页展示所有历史版本，可单独下载或删除
- 删除操作同时删除磁盘文件和数据库记录，不可恢复

### 多 APP 支持

不同的 APP_ID 完全独立管理，互不干扰。固件文件存储路径：

```
data/ota/
├── MyDevice/
│   ├── 20260301_120000_firmware_v1.0.bin
│   └── 20260315_093000_firmware_v1.1.bin
└── AnotherApp/
    └── 20260310_150000_app_v2.0.apk
```

---

## API 接口

### 公开接口（无需认证）

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/` | 文件浏览页面 |
| `GET` | `/download/<path>` | 强制下载文件 |
| `GET` | `/ota/download/<APP_ID>/latest` | 下载最新固件 |
| `GET` | `/ota/download/<APP_ID>/latest/<filename>` | 下载最新固件（wget 友好） |
| `GET` | `/ota/download/<APP_ID>/<id>` | 下载指定版本固件 |
| `GET` | `/ota/download/<APP_ID>/<id>/<filename>` | 下载指定版本固件（wget 友好） |
| `GET` | `/sysinfo` | 系统信息 JSON |
| `GET` | `/api/config` | 公开配置项（webdav_enabled 等） |

### 需要管理员 Session

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/admin/login` | 登录，Body: `{"password":"..."}` |
| `POST` | `/admin/logout` | 登出 |
| `GET` | `/admin/check` | 检查登录状态 |
| `GET/POST` | `/admin/settings` | 读取 / 保存设置 |
| `POST` | `/admin/change-password` | 修改密码 |
| `GET` | `/admin` | 管理设置页面 |
| `GET` | `/ota/` | OTA 管理页面 |
| `POST` | `/ota/upload` | 上传固件 |
| `POST` | `/ota/delete/<id>` | 删除固件记录 |
| `POST` | `/delete/<path>` | 删除文件/目录 |
| `POST` | `/upload/<path>` | 网页上传文件 |

### WebDAV 写操作（视配置决定是否需要 Basic Auth）

| 方法 | 说明 |
|------|------|
| `PUT` | 上传文件 |
| `DELETE` | 删除文件 |
| `MKCOL` | 创建目录 |
| `MOVE` | 重命名 / 移动 |
| `COPY` | 复制 |
| `PROPFIND` | 列出目录 |

---

## 构建说明

### 依赖

| 包 | 版本 | 用途 |
|----|------|------|
| `golang.org/x/net` | v0.28.0 | WebDAV 协议实现 |
| `modernc.org/sqlite` | v1.39.1 | 纯 Go SQLite 驱动（无需 CGO） |

### 编译要求

- Go 1.19 及以上
- `CGO_ENABLED=0`（无需 C 编译器）

### 构建命令

```bash
# 下载依赖
go mod tidy

# Linux amd64
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -ldflags "-s -w -X main.Version=v1.0.0" -o aiwarehouse_linux_amd64 .

# Windows amd64
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 \
  go build -ldflags "-s -w -X main.Version=v1.0.0" -o aiwarehouse-windows-amd64-x64.exe .

# macOS arm64 (Apple Silicon)
CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 \
  go build -ldflags "-s -w -X main.Version=v1.0.0" -o aiwarehouse_darwin_arm64 .
```

### 使用构建脚本

```bash
bash build.sh [版本号]
# 例: bash build.sh v1.2.0
```

---

## 注意事项

- **密码安全**：管理密码以 SHA-256 哈希存储，不可逆
- **Guest 密码固定**：guest 账号密码硬编码为 `guest`，仅适合内网受信环境
- **服务重启**：Session Token 持久化，重启服务不影响已登录的浏览器
- **数据备份**：重要文件请定期备份 `./data/` 目录
- **端口修改**：如需更改端口，修改 `main.go` 中的 `Port` 常量后重新编译
- **Windows 磁盘信息**：系统信息页面在 Windows 上可正常显示磁盘使用率（通过 `kernel32.dll` 读取）；在 Linux/macOS 上通过 `df -k` 命令读取

---

## 许可

MIT License

