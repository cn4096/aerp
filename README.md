# Uptime Monitor

一个用 Go 编写的服务可用性监控程序（类似 Uptime Kuma 的精简版）。纯 Go、**cgo=0**，单文件二进制，内置网页管理界面，数据存 SQLite。

## 特性

- **10 种监控类型**
  | 类型 | 说明 |
  |---|---|
  | `http` | HTTP(s) 请求，按状态码判断（默认 2xx 正常） |
  | `keyword` | HTTP(s) 关键词：响应中必须出现（或必须不出现）指定文字 |
  | `json_query` | HTTP(s) JSON 查询：按路径取值并与期望值比较 |
  | `tcp` | TCP 端口连通性 |
  | `websocket` | WebSocket 握手（检查是否返回 `101 Switching Protocols`） |
  | `ping` | ICMP Ping（无权限时自动退回 TCP 探测） |
  | `dns` | DNS 记录查询（A / AAAA / CNAME / MX / TXT / NS / SRV） |
  | `push` | 被动推送：外部脚本/设备按地址上报心跳 |
  | `steam` | Steam / 起源引擎游戏服务器（A2S_INFO 查询人数、地图） |
  | `docker` | Docker 容器状态（含健康检查） |
- **检查时间**：固定周期，或 **a-b 秒之间随机**（避免同一时刻集中请求）。
- **失败重试**：可配置重试次数与重试间隔，重试成功仍记为正常。
- **状态反转**：把「正常」判为「故障」。
- **可用率统计**：24 小时 / 7 天 / 30 天，含心跳柱状图与平均延迟。
- **延迟分档配色**：心跳柱按响应延迟分 5 档，从绿（快）到红（慢）；**阈值按监控类型分别设定**（如 Ping 是 20/50/100/200 ms，HTTP 是 200/500/1000/3000 ms），不同类型的快慢标准互不影响。监控详情页会显示当前类型的图例。
- **状态变化事件**、**徽标（SVG）**、**SSE 实时推送**。
- **可选登录**：PBKDF2 口令 + 会话 Cookie + CSRF 校验。
- **网页界面**：基于 `dashboard-ui` 设计系统，响应式、暗黑模式、无 CDN、无构建步骤。

## 快速开始

```bash
# 1. 拉取依赖（首次）
go mod download

# 2. 编译（纯 Go，无 cgo）
CGO_ENABLED=0 go build -o uptime-monitor .

# 3. 运行
./uptime-monitor -addr :3001 -data uptime.db
```

打开 <http://localhost:3001> 即可。默认不启用登录，可直接使用；在「设置」里设置管理口令后访问需登录。

### 命令行参数

| 参数 | 默认 | 说明 |
|---|---|---|
| `-addr` | 空 | 监听地址；留空则用「设置 → 服务端口」上次保存的值（都没有时为 `:3001`） |
| `-data` | `uptime.db` | SQLite 数据库文件 |
| `-password` | 空 | 启动时设置/重置管理口令；留空不启用登录 |
| `-version` | | 显示版本后退出 |

### 交叉编译示例
```bash# Linux arm64（如旧手机、路由器、ARM 服务器）
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o uptime-monitor-arm64 .

# Linux armv7
CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build -o uptime-monitor-armv7 .

# Windows amd64
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o uptime-monitor.exe .
```

`CGO_ENABLED=0` 全程可用：SQLite 使用纯 Go 驱动 `modernc.org/sqlite`。

### Docker（最小镜像）

`Dockerfile` 用多阶段构建，运行镜像是 `scratch`：**只有静态二进制 + CA 证书，约 11 MB**（时区库用 `-tags timetzdata` 内嵌进二进制，不额外带 `/usr/share/zoneinfo`）。
数据库默认在容器内的 **`/data/uptime.db`**。

```bash
docker build -t uptime-monitor .
docker run -d --name uptime-monitor \
  -p 3001:3001 \
  -v uptime-data:/data \
  uptime-monitor
```

或直接用 compose（含注释说明）：

```bash
docker compose up -d --build
```

几点说明：

- **数据持久化**：数据库固定落在 `/data`。用**命名卷**（`-v uptime-data:/data`）最省事——命名卷会继承镜像里 `/data` 的属主。
  若改用**绑定挂载**（`-v ./data:/data`），容器以非 root（uid `65532`）运行，需要先 `mkdir -p ./data && sudo chown -R 65532:65532 ./data`；也可以加 `--user 0:0` 以 root 运行。
- **HTTPS 监控**：镜像内已带 CA 证书，可直接监控 https 站点。
- **时区**：默认 `TZ=Asia/Shanghai`，用 `-e TZ=UTC` 可改。
- **Docker 容器监控**：需要把宿主机的 `/var/run/docker.sock` 挂进容器（`-v /var/run/docker.sock:/var/run/docker.sock:ro`）。注意这等于给容器很高权限，请自行评估。
- **镜像里没有 shell / curl**（scratch），`docker exec` 无法执行命令，属正常现象。

## 监控类型配置

在网页「监控 → 添加监控」里选择类型后，按需填写：

- **HTTP / 关键词 / JSON 查询**：URL、方法、请求头（每行 `名称: 值`）、请求体、接受的状态码（如 `200-299, 301`）、基础认证、忽略 TLS。
  - 关键词：`关键词` + 可选「反转」（不出现才算正常）。
  - JSON 查询：`JSON 路径`（如 `data.items[0].id`，支持 `$` 前缀）+ `期望值`。期望值可写 `42`、`ok`，或运算符形式 `>100`、`<=50`、`!=error`；留空只校验路径存在。
- **TCP / Steam**：主机 + 端口。
- **Ping**：主机 / 域名（容器内无 ICMP 权限时自动退回 TCP 探测 443/80）。
- **WebSocket**：`ws://` 或 `wss://` 地址。
- **DNS**：域名、记录类型、DNS 服务器（留空用系统 `/etc/resolv.conf`）、期望包含的值（可选）。
- **Docker**：容器名/ID、Docker 地址（默认 `unix:///var/run/docker.sock`，也支持 `tcp://host:2375`）。
- **Push**：保存后自动生成令牌，地址形如 `http://<host>/api/push/<令牌>`。

### 检查时间

- 勾选「使用 a-b 之间的随机时间」后，每次检查的间隔在 `随机最小 ~ 随机最大` 秒之间随机取值。
- 不勾选则使用固定「检查间隔」。

### Push 用法

```bash
# 上报正常
curl -fsS http://localhost:3001/api/push/<令牌>

# 主动上报故障（带说明）
curl -fsS "http://localhost:3001/api/push/<令牌>?status=down&msg=磁盘已满"
```

超过「两倍检查间隔 + 30 秒」未收到推送即判定为故障。

### 服务端口

「设置 → 服务端口」可以直接改监听端口：输入端口点「确定」后，弹窗里选

- **立即生效**：在当前进程切换监听（旧地址停止接受新连接，已建立的连接不受影响），页面地址随之改变，界面会给出新地址的跳转入口；
- **保存**：只写入配置，重启程序后生效。

两种方式都会先校验端口（1–65535）并试绑一次，端口被占用或权限不足会直接报错且不写入配置。
优先级：命令行 `-addr` > 界面保存的端口 > 默认 `:3001`。

### 徽标

```
http://localhost:3001/api/badge/<监控项ID>.svg
http://localhost:3001/api/badge/<监控项ID>.svg?hours=168
```

## 导入 / 导出（JSON）

「设置 → 导入 / 导出」可以把全部监控项导出成 JSON 备份，或从 JSON 导入；「监控」页顶栏也有一个「导出」快捷按钮。

- **导出**：`GET /api/export`，下载 `uptime-monitors-<时间>.json`。包含每个监控项的全部配置与 Push 令牌，**不包含管理口令**。
- **导入**：`POST /api/import?mode=merge|replace`
  - `merge`（默认）：追加到现有监控项之后；若 Push 令牌与已有监控项重复，会自动换发新令牌。
  - `replace`：先删除全部现有监控项及其历史，再导入（界面上会二次确认）。
- 兼容三种文件写法：本程序导出的对象、裸数组 `[{…}]`、单个监控项对象。
- 导入时逐项校验：越界数值会被夹到合理范围，非法项跳过并在结果里说明，不会整批失败。
- 上限：单文件 5 MiB、一次最多 1000 个监控项（超出返回 413）。

导出文件示例：

```json
{
  "app": "uptime-monitor",
  "version": 1,
  "exported_at": "2026-10-14T22:33:55+08:00",
  "monitors": [
    {
      "name": "官网",
      "type": "http",
      "active": true,
      "interval": 60,
      "retry_interval": 5,
      "random_interval": true,
      "random_min": 30,
      "random_max": 120,
      "timeout": 10,
      "max_retries": 0,
      "upside_down": false,
      "description": "",
      "config": { "url": "https://example.com/", "accepted_statuses": ["200-299"] }
    }
  ]
}
```

命令行用法：

```bash
curl -s http://localhost:3001/api/export > backup.json
curl -s -X POST "http://localhost:3001/api/import?mode=merge" \
     -H 'Content-Type: application/json' --data-binary @backup.json
```

> 启用登录后，导入属于修改类请求，需要带上会话 Cookie 与 `X-CSRF-Token`（网页界面会自动处理）。

## API 概览

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/session` | 会话状态（页面启动时调用） |
| POST | `/api/login` `/api/logout` | 登录 / 退出 |
| GET | `/api/overview` | 概览统计 |
| GET/POST | `/api/monitors` | 列表 / 新建 |
| GET/PUT/DELETE | `/api/monitors/{id}` | 详情 / 更新 / 删除 |
| POST | `/api/monitors/{id}/pause` `/resume` `/check` | 暂停 / 启用 / 立即检查 |
| GET | `/api/monitors/{id}/heartbeats?hours=24` | 心跳记录 |
| GET | `/api/events` `/api/logs` `/api/info` | 事件 / 日志 / 信息 |
| GET | `/api/export` | 导出全部监控项为 JSON |
| POST | `/api/import?mode=merge\|replace` | 从 JSON 导入监控项 |
| GET | `/api/stream` | SSE 实时心跳 |
| GET/POST | `/api/push/{token}` | 外部推送（公开） |
| GET | `/api/badge/{id}.svg` | 可用率徽标（公开） |

修改类请求在启用登录后需要携带 `X-CSRF-Token`（页面会自动处理）。

## 目录结构

```
main.go                     程序入口、命令行参数、优雅退出
internal/model/             监控项、心跳、配置等数据结构
internal/store/             SQLite 持久化（modernc.org/sqlite）
internal/check/             各类型检查器（http/tcp/ws/ping/dns/steam/docker…）
internal/scheduler/         按周期 / 随机时间调度检查、重试、心跳落库
internal/web/               HTTP 服务、API、鉴权、静态界面
internal/web/static/        网页界面（dashboard-ui 设计系统）
```

## 开发

```bash
go test ./...          # 运行单元测试
go vet ./...           # 静态检查
gofmt -l .             # 格式检查
```

端到端界面测试（无头浏览器，覆盖登录、10 种监控类型的新建/编辑/删除、抽屉层级、Push、手机端、暗黑模式等，共 51 项断言）：

```bash
# 终端 1
CGO_ENABLED=0 go build -o /tmp/uptime-monitor . && /tmp/uptime-monitor -addr 127.0.0.1:3001 -data /tmp/uptime-e2e.db
# 终端 2
BASE=http://127.0.0.1:3001 NODE_PATH="$(npm root -g)" node test/e2e/e2e.js
```

详见 `test/e2e/README.md`。

## 安全与稳定性

本程序会**按你配置的目标发起对外请求**（HTTP/TCP/Ping/DNS/WebSocket/Docker…），因此：

- **务必设置管理口令**（`-password` 或「设置」页），或只监听 `127.0.0.1`，或放在带认证的反向代理之后。
  未设口令又对外监听时，任何人不仅能看/改监控项，还能借本机访问内网、把 `json_query` / 错误信息当作内网内容读取的通道。
  启动时会检测到这种组合并打印醒目提示。

已内置的资源与安全上限（无需配置）：

| 项 | 上限 |
|---|---|
| 请求体 | 1 MiB（超出返回 413） |
| 单次检查超时 | 1–300 秒 |
| 失败重试 | ≤ 10 次，重试间隔 ≤ 1 小时 |
| 检查间隔 / 随机区间 | 1 秒 – 7 天 |
| 心跳查询 `limit` / `hours` | ≤ 2000 条 / 90 天 |
| 事件查询 `limit` | ≤ 1000 |
| 并发 SSE 连接 | 100（超出返回 503） |
| 登录失败 | 同 IP 5 分钟内 5 次后锁定（返回 429） |
| 心跳保留 | 90 天（每 6 小时清理） |

长期运行观察：进程每 10 分钟打印一行
`资源: goroutine=… heapInuse=…MB sys=…MB gc=…`，goroutine 稳定波动、heapInuse 能回落即为正常。

> 已做压测与泄漏验证：持续负载后 goroutine / FD 完全回落到基线，RSS 平稳（详见 `test/e2e/` 与提交说明）。

## 延迟分档配色

心跳柱的颜色按**本次检查的响应延迟**分 5 档，绿 → 红表示快 → 慢：

| 档 | 颜色 | 含义 |
|---|---|---|
| 1 | 绿 `#22c55e` | 很快 |
| 2 | 黄绿 `#84cc16` | 较快 |
| 3 | 黄 `#eab308` | 一般 |
| 4 | 橙 `#f97316` | 偏慢 |
| 5 | 红 `#ef4444` | 很慢 |
| — | 深红 `#b91c1c` | 故障（status=down） |
| — | 灰 `#cbd5e1` | 无数据 |

**阈值按监控类型分别设定**（单位毫秒），不同类型的「快 / 慢」标准不同：

| 类型 | 档 1 | 档 2 | 档 3 | 档 4 | 档 5 |
|---|---|---|---|---|---|
| `ping` | ≤20 | ≤50 | ≤100 | ≤200 | >200 |
| `http` / `keyword` / `json_query` | ≤200 | ≤500 | ≤1000 | ≤3000 | >3000 |
| `tcp` | ≤50 | ≤150 | ≤400 | ≤1000 | >1000 |
| `websocket` | ≤100 | ≤300 | ≤800 | ≤2000 | >2000 |
| `dns` | ≤30 | ≤80 | ≤200 | ≤500 | >500 |
| `steam` | ≤50 | ≤150 | ≤400 | ≤1000 | >1000 |
| `docker` | ≤20 | ≤60 | ≤150 | ≤400 | >400 |

所以同样是 300 ms：对 `ping` 已经是第 5 档（红），对 `http` 只是第 2 档（黄绿）。
监控详情页会按该监控项的类型显示对应图例。阈值定义在 `internal/web/static/app.js` 的 `PING_TIERS`。

## 数据库

单文件 SQLite（WAL 模式）。默认保留最近 90 天心跳，程序每 6 小时清理一次。备份直接复制该文件即可。
