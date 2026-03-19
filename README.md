## Docker启动

+ 测试：`docker run --rm --network host ghcr.io/cn4096/aerp:latest`   `端口`：8080

+ 数据保存到本地并运行：
  ```
  ## 数据保存在当前目录/erp_data 访问端口:8880
  docker run -itd \
  --name my-erp-app \
  -p 8880:8080 \
  -v $(pwd)/erp_data:/home/user/app/data \
  ghcr.io/cn4096/aerp:latest
  ```
