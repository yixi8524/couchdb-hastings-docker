# docker使用

## 初始化

拉取镜像

```bash
docker pull xaotuman/couchdb-hastings-3.1.1:1.1.0
```

启动容器

```bash
docker run -d -p 5984:5984 --name couchdb xaotuman/couchdb-hastings-3.1.1:1.1.0 sh -c "/rel/couchdb/bin/couchdb"
```

## 跑一遍测试
```bash
docker exec -w /rel/sample -t $(docker ps -q -f ancestor=xaotuman/couchdb-hastings-3.1.1:1.1.0) python loader.py
```
会有如下的输出：

```
{u'bookmark': u'g1AAAAB5eJzLYWBgYMpgTmEQTM4vTc5ISXIwNDLXMwBCwxyQVB4LkGRoAFL_gSArgykXyGUOCg12c4iI396beyoGj-ZEhqR6JF1uQY5uDiIx63edPeiXBQCgKiNY', u'rows': [{u'geometry': {u'type': u'MultiPolygon', u'coordinates': [[[[-5.661949, 54.554603], [-6.197885, 53.867565], [-6.95373,
……
```

## 使用方法

默认账户：admin，默认密码：adminpw

### 创建你的geojson数据库
```bash
curl -X PUT admin:adminpw@localhost:5984/shelters
```

### 导入一些地理数据
```bash
curl -X POST -H "Content-Type: application/json" -d '
{
  "geometry": {
    "type": "Point",
    "coordinates": [59.37131802330678, 18.16711393757631]
  },
  "properties": {
    "name": "Secret room",
    "address": "Underground"
  }
}
' admin:adminpw@localhost:5984/shelters
```

### 创建空间索引
```bash
curl -X POST -H "Content-Type: application/json" -d '
{
  "_id": "_design/SpatialView",
  "st_indexes" : {
    "shelter_positions": {
      "index" : "function(doc) { if (doc.geometry) { st_index(doc.geometry); } }"
    }
  }
}' admin:adminpw@localhost:5984/shelters
```

### 查询地理数据
```bash
curl -X GET admin:adminpw@localhost:5984/shelters/_design/SpatialView/_geo/shelter_positions?bbox=59.26,18.02,59.49,18.32
```

会返回以下的数据：

```json
{
    "bookmark": "g2wAAAABaANkABFjb3VjaGRiQDEyNy4wLjAuMWwAAAACbgQAAAAAgG4EAP____9qaAJtAAAAIDMxZjYzZjc2NTBjYmZmMzFiOWVmNWJmMzI4MDAwZjcwRj9zKYhdysN6ag",
    "rows": [
        {
            "id": "31f63f7650cbff31b9ef5bf328000f70",
            "rev": "1-2d5ed349b3dda7973751532a0f7cfb1e",
            "geometry": {
                "type": "Point",
                "coordinates": [59.37131802330678, 18.16711393757631]
            }
        }
    ]
}
```

