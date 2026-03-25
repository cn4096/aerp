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
  -p 8880:8080 \
  -v $(pwd)/erp_data:/home/user/app/data \
  ghcr.io/cn4096/aerp:latest
  
```
