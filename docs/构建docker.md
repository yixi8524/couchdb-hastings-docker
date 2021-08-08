# 构建docker

## 文件结构

dockerfile
├── CsMapDev-14.01.zip	需要的库CsMap，也可以在dockerfile通过wget方式下载，仓库中没有这个文件，需要自行[下载](https://trac.osgeo.org/csmap/browser/branches/14.01/CsMapDev?rev=2854&format=zip*)。
├── Dockerfile	构建Docker的文件
├── hastings-fixer.sh	构建hasting和easton所需做的配置
└── sample	测试运行的脚本和数据
    ├── data
    │   ├── countries.json
    │   ├── readme.txt
    │   └── ski_areas.json
    ├── loader.py
    └── loader_ski_areas.py

## 构建

```bash
# 构建
docker image build -t xaotuman/couchdb-hastings-3.1.1:1.0.1 .
# 运行
docker run -d -p 5984:5984 --name couchdb xaotuman/couchdb-hastings-3.1.1:1.0.1
# 测试
docker exec -w /rel/sample -t $(docker ps -q -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.0.1) python loader.py
```

其他命令

```bash
# 进入容器
docker exec -it $(docker ps -q -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.0.0) /bin/bash
# 查看日志
docker logs -f $(docker ps -aq -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.0.0)
# 杀死容器
docker kill $(docker ps -q -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.0.0)
# 删除容器
docker rm $(docker ps -aq -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.0.0)
```

## 压缩

导出容器再导入成镜像，会失去构建信息，但是镜像会变小

```bash
docker export $(docker ps -aq -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.0.1) | 
docker import - xaotuman/couchdb-hastings-3.1.1:1.1.0
```

由于CMD和端口输出都丢失了，需要自己指定运行

```bash
docker run -d -p 5984:5984 --name couchdb xaotuman/couchdb-hastings-3.1.1:1.1.0 sh -c "/rel/couchdb/bin/couchdb"
```

## 上传

```bash
# 登录
docker login
# 上传
docker push xaotuman/couchdb-hastings-3.1.1:1.0.0
```

