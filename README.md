## claw_host网盘 Docker启动
+ 测试：`docker run --rm --network host ghcr.io/cn4096/claw_host:latest`   `端口`：7860

+ 数据保存到本地并运行：

```
 ## 下载/更新镜像
 docker pull ghcr.io/cn4096/claw_host:latest

 ## 查看上次的路径 -v 映射的路径，本地数据在那个位置.
 docker inspect claw_host-app

 ## 停止并删除容器
 docker stop claw_host-app
 docker rm claw_host-app
  
 ## 重开容器,核心点 映射的路径 -v 要和上次一致
 cd /opt/claw_host/

 ## 数据保存在当前目录/claw_host_data 访问端口:8880
 docker run -itd \
  --name claw_host-app \
  --restart=always \
  -p 8880:7860 \
  -v $(pwd)/claw_host_data:/home/user/app/data \
  ghcr.io/cn4096/claw_host:latest
```

## aerp.ERP Docker启动

+ 测试：`docker run --rm --network host ghcr.io/cn4096/aerp:latest`   `端口`：8080

+ 数据保存到本地并运行：
  
```
 ## 删除旧的容器，更新镜像
 docker stop my-erp-app ; docker rm my-erp-app

 ## 下载/更新镜像
 docker pull ghcr.io/cn4096/aerp:latest

 ## 数据保存在当前目录/erp_data 访问端口:8880
 docker run -itd \
  --name my-erp-app \
  --restart=always \
  -p 8880:8080 \
  -v $(pwd)/erp_data:/home/user/app/data \
  ghcr.io/cn4096/aerp:latest
  
```

## uptime Docker启动

+ 测试：`docker run --rm --network host ghcr.io/cn4096/uptime-monitor:latest`   `端口`：3001

+ 数据保存到本地并运行：
  
```
 ## 删除旧的容器，更新镜像
 docker stop uptime-monitor ; docker rm uptime-monitor

 ## 下载/更新镜像
 docker pull ghcr.io/cn4096/uptime-monitor:latest

 ## 数据保存在当前目录/data 访问端口:3001
 docker run -itd \
  --name uptime-monitor \
  --restart=always \
  -p 3001:3001 \
  -v $(pwd)/uptime-monitor:/data \
  ghcr.io/cn4096/uptime-monitor:latest
  
```
### 命令行参数

| 参数 | 默认 | 说明 |
|---|---|---|
| `-addr` | 空 | 监听地址；留空则用「设置 → 服务端口」上次保存的值（都没有时为 `:3001`） |
| `-data` | `uptime.db` | SQLite 数据库文件 |
| `-password` | 空 | 启动时设置/重置管理口令；留空不启用登录 |
| `-version` | | 显示版本后退出 |

### uptime 重置管理口令（命令行）

忘记口令或无法登录时，可在服务所在机器上直接修改数据库，不需要先进网页：

```bash
./uptime-monitor pass 'new-password-123'      # 指定新口令（至少 8 位）
./uptime-monitor -data /data/uptime.db pass   # 不填则随机生成 12 位并显示
```

改完需重启服务才会生效（运行中的进程使用的是内存里的旧口令）。Docker 部署：

```bash
docker exec uptime-monitor /uptime-monitor -data /data/uptime.db pass
```

