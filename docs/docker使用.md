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

## 手动测试

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

框内的数据

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

圆内的数据

```bash
curl -X GET "admin:adminpw@localhost:5984/shelters/_design/SpatialView/_geo/shelter_positions?lat=18&lon=59&radius=100000&relation=contains&format=geojson"
```

### 查看地理索引

```bash
curl -X GET admin:adminpw@localhost:5984/shelters/_design/SpatialView/_geo_info/shelter_positions
```

## 地理查询方法（翻译）

cloudant关于GeoSpatial的[介绍文档](https://cloud.ibm.com/docs/Cloudant?topic=Cloudant-using-cloudant-nosql-db-geospatial)以及[api文档](https://cloud.ibm.com/apidocs/cloudant#getgeo)。

### 格式

`type`

它必须存在并包含值`Feature`。

`geometry`

它必须包括两个字段：`type`和`coordinates`。这些字段指定以下列表中显示的定义：

- `type`字段指定以GeoJSON几何类型所必须的一个`Point`， `LineString`， `Polygon`， `MultiPoint`， `MultiLineString`，或`MultiPolygon`。
- `coordinates` 字段指定纬度和经度值的数组。

格式需要为[geojson](https://geojson.org/)

```json
{
    "type": "Feature",
    "geometry": {
        "type": "Point",
        "coordinates": [-71.13687953, 42.34690635]
    },
    "properties": {
        "compnos": "142035014",
        "domestic": false,
        "fromdate": 1412209800000,
        "main_crimecode": "MedAssist",
        "naturecode": "EDP",
        "reptdistrict": "D14",
        "shooting": false,
        "source": "boston"
    }
}
```

### 创建地理索引

参考以下的示例：

```json
{
    "_id": "_design/geodd",
    "st_indexes": {
        "geoidx": {
            "index": "function(doc) {if (doc.geometry && doc.geometry.coordinates) {st_index(doc.geometry);}}"
        }
    }
}
```

### 查找有关地理索引的信息

```bash
curl localhost:5984/crimes/_design/geodd/_geo_info/geoidx
```

`geo_index`在 JSON 响应部分中返回的数据包括以下字段：

| 字段        | 描述                                               |
| :---------- | :------------------------------------------------- |
| `doc_count` | 地理空间索引中的文档数。                           |
| `disk_size` | 存储在磁盘上的地理空间索引的大小（以字节为单位）。 |
| `data_size` | 地理空间索引的大小，以字节为单位。                 |

返回示例

```json
{
    "name": "_design/geodd/geoidx",
    "geo_index": {
        "doc_count": 269,
        "disk_size": 33416,
        "data_size": 26974
    }
}
```

### 查询地理索引

使用的基本 API 调用具有简单的格式，其中查询参数字段`<query-parameters>`包含三种不同类型的参数：

- 查询几何
- 几何关系
- 结果集

请参阅[api文档](https://cloud.ibm.com/apidocs/cloudant#getgeo)调用的示例格式：

```
/$DATABASE/_design/$DDOCS/_geo/$INDEX_NAME?$QUERY_PARAMS
```

### 查询几何

必须为地理搜索提供查询几何参数。下表定义了四种类型的查询几何：

| 范围      | 描述                                                         |
| :-------- | :----------------------------------------------------------- |
| `bbox`    | 为 lower-left和 upper-right 指定一个具有两个坐标的边界框。   |
| `ellipse` | 指定一个具有纬度`lat`、经度`lon`和两个半径的椭圆查询：`rangex`和`rangey`，均以米为单位。 |
| `radius`  | 使用纬度`lat`、经度`lon`和`radius`以米为单位的半径指定圆形查询。 |
| `<wkt>`   | 指定一个众所周知的文本 (WKT) 对象。`<wkt>`参数的有效值包括`Point`、`LineString`、`Polygon`、`MultiPoint`、`MultiLineString`、`MultiPolygon`、 `GeometryCollection`。 |

查看`bbox`查询示例：

```
?bbox=-11.05987446,12.28339928,-101.05987446,62.28339928
```

查看`ellipse`查询示例：

```
?lat=-11.05987446&lon=12.28339928&rangex=200&rangey=100
```

查看`radius`查询示例：

```
?lat=-11.05987446&lon=12.28339928&radius=100
```

查看`point`查询示例：

```
?g=point(-71.0537124 42.3681995)
```

查看`polygon`查询示例：

```
?g=polygon((-71.0537124 42.3681995,-71.054399 42.3675178,-71.0522962 42.3667409,-71.051631 42.3659324,-71.051631 42.3621431,-71.0502148 42.3618577,-71.0505152 42.3660275,-71.0511589 42.3670263,-71.0537124 42.3681995))
```

### 几何关系

处理地理空间关系并遵循几何关系的[DE-9IM 规范](https://en.wikipedia.org/wiki/DE-9IM)。该规范定义了两个地理空间对象相互关联的不同方式，如果它们确实相关的话。

例如，您可以指定一个描述住宅区的多边形对象。然后，您可以通过请求居住地*包含* 在多边形对象中的所有文档来查询文档数据库中居住在该地区的人员。

当您指定查询几何时，您可以在查询数据库中的文档时根据查询几何指定几何关系。具体来说，如果`Q`是查询几何，则`R` 当`Q`和之间的几何关系`R`返回true时，将GeoJSON文档视为结果。下表定义了几何关系：

| 关系                    | 描述                                                         |
| :---------------------- | :----------------------------------------------------------- |
| `Q contains R`          | 如果`R`的外部没有谎言点，则为真`Q`。`contains`返回完全相反的结果`within`。 |
| `Q contains_properly R` | 如果`R`与 的内部相交，`Q`但与 的边界（或外部）相交，则为真`Q`。 |
| `Q covered_by R`        | 如果`Q`完全在 内，则为真`R`。`covered_by`返回完全相反的结果`covers`。 |
| `Q covers R`            | 如果`R`完全在 内，则为真`Q`。`covers`返回完全相反的结果`covered_by`。 |
| `Q crosses R`           | 情况 1 - 如果内部相交，*并且*至少 的内部`Q`与 的外部相交，则为真`R`。应用于`multipoint/linestring`, `multipoint/multilinestring`, `multipoint/polygon`, `multipoint/multipolygon`, `linestring/polygon`, 和的几何对`linestring/multipolygon`。 |
|                         | 情况 2 - 如果`Q`和内部的交集`R`是一个点，则为真。适用于几何形状对`linestring/linestring`，`linestring/multilinestring`和`multilinestring/multilinestring`。 |
| `Q disjoint R`          | 真如果两个几何形状`Q`和`R`不相交。`disjoint`返回完全相反的结果`intersects`。 |
| `Q intersects R`        | 真如果两个几何形状`Q`和`R`相交。`intersects`返回完全相反的结果`disjoint`。 |
| `Q overlaps R`          | 情况 1 - 如果两个几何图形的内部与另一个几何图形的内部和外部相交，则为真。适用于几何形状对`polygon/polygon`，`multipoint/multipoint`和`multipolygon/multipolygon`。 |
|                         | 情况 2 - 如果几何的交集是 a ，则为 True `linestring`。应用于`linestring`and `linestring`、 and`multilinestring`和的几何对`multilinestring`。 |
| `Q touches R`           | 当且仅当两个几何体的公共点仅在两个几何体的边界处找到时为真。至少一个几何图形必须是`linestring`、多边形`multilinestring`、 或`multipolygon`。 |
| `Q within R`            | 如果`Q`完全在 内，则为真`R`。`within`返回完全相反的结果`contains`。 |

### 最近邻搜索

IBM Cloudant Geo 支持最近邻搜索，也称为 NN 搜索。如果提供，`nearest=true`搜索将通过对它们到查询几何中心的距离进行排序来返回所有结果。这种几何关系`nearest=true` 可以与前面描述的所有几何关系一起使用，也可以单独使用。

例如，一名警官可能会通过键入以下示例中的查询来搜索在特定位置附近发生的五起犯罪。

查看示例查询以查找针对特定位置的最近五项犯罪：

```
https://education.cloudant.com/crimes/_design/geodd/_geo/geoidx?g=POINT(-71.0537124 42.3681995)&nearest=true&limit=5
```

### 简单圆查询

这个简单的示例演示了如何查找被认为在给定地理圈内具有地理空间位置的文档。该函数可能有助于确定居住在已知洪泛区附近的保险客户。

要指定圆圈，请提供以下值：

- 纬度。
- 经度。
- 以米为单位指定的圆半径。

此查询将索引中每个文档的几何形状与指定圆的几何形状进行比较。比较是根据您在查询中请求的关系运行的。因此，要查找落入圆圈内的所有文档，请使用`contains`关系。

查看示例查询以查找在圆内具有地理空间位置的文档：

```
curl -X GET "https://education.cloudant.com/crimes/_design/geodd/_geo/geoidx?lat=42.3397&lon=-71.07959&radius=10&relation=contains&format=geojson"
```

请参阅对具有圆圈内地理空间位置的查询的示例响应：

```json
{
    "bookmark": "g2wAAAABaANkAB9kYmNvcmVAZGIyLmJpZ2JsdWUuY2xvdWRhbnQubmV0bAAAAAJuBAAAAADAbgQA_____2poAm0AAAAgNzlmMTRiNjRjNTc0NjE1ODRiMTUyMTIzZTM4YThlOGJGPv4LlS19_ztq",
    "features": [
        {
            "_id": "79f14b64c57461584b152123e38a8e8b",
            "geometry": {
                "coordinates": [
                    -71.07958956,
                    42.33967135
                ],
                "type": "Point"
            },
            "properties": [],
            "type": "Feature"
        }
    ],
    "type": "FeatureCollection"
}
```

### 多边形查询

一个更复杂的示例显示了在何处将多边形指定为感兴趣的几何对象。多边形是由一系列连接点定义的任何对象，其中没有任何连接（点之间的线）与任何其他连接相交。

例如，您可以提供一个多边形描述作为几何对象，然后请求查询返回该多边形包含的数据库中文档的详细信息。

查看示例查询以查找在多边形内具有地理空间位置的文档：

```
https://education.cloudant.com/crimes/_design/geodd/_geo/geoidx?g=POLYGON((-71.0537124 42.3681995,-71.054399 42.3675178,-71.0522962 42.3667409,-71.051631 42.3659324,-71.051631 42.3621431,-71.0502148 42.3618577,-71.0505152 42.3660275,-71.0511589 42.3670263,-71.0537124 42.3681995))&relation=contains&format=geojson
```

请参阅对在多边形内查找具有地理空间位置的文档的查询的示例响应：

```
{
    "bookmark": "g2wAAAABaANkAB9kYmNvcmVAZGIzLmJpZ2JsdWUuY2xvdWRhbnQubmV0bAAAAAJuBAAAAADAbgQA_____2poAm0AAAAgNzlmMTRiNjRjNTc0NjE1ODRiMTUyMTIzZTM5MjQ1MTZGP1vW7X5qnWhq",
    "features": [
        {
            "_id": "79f14b64c57461584b152123e38d6349",
            "geometry": {
                "coordinates": [
                    -71.05107956,
                    42.36510634
                ],
                "type": "Point"
            },
            "properties": [],
            "type": "Feature"
        },
        {
            "_id": "79f14b64c57461584b152123e3924516",
            "geometry": {
                "coordinates": [
                    -71.05204477,
                    42.36674199
                ],
                "type": "Point"
            },
            "properties": [],
            "type": "Feature"
        }
    ],
    "type": "FeatureCollection"
}
```
