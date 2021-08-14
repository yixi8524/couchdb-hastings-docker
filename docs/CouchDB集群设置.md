# CouchDB集群设置

参考链接：https://docs.couchdb.org/en/latest/setup/cluster.html

## 0、运行Couchdb

启动docker-compose

```bash
docker-compose -f docker-compose-couch.yaml up -d 2>&1
```

删除docker-compose

```bash
docker-compose -f docker-compose-couch.yaml down --volumes --remove-orphans
```

进入docker操作的步骤。以下的根目录都在`/rel/couchdb`。

```bash
docker exec -it $(docker ps -q -f name=couchdb0) /bin/bash
```

注意：他们的都在同一个网络下，即为docker-compose-couch.yaml配置的网络

## 1 端口和防火墙

由于我的防火墙是关着的，并且都在同一台机子上测试，并且都是通过docker网桥，所以此处略过。

## 2 配置和测试与 Erlang 的通信

### 2.1 使 CouchDB 使用正确的 IP|FQDN 和开放端口

在文件`etc/vm.args`限定节点的名称，另一个docker同理

```
-name couchdb@couchdb0.fabric_test
```

再加入以下的信息，表示erl通信之间的端口在9100到9200之间。

```
-kernel inet_dist_listen_min 9100
-kernel inet_dist_listen_max 9200
```

### 2.2 确认节点间的连通性

测试一下两个之间的erl连通性。

couchdb0

```bash
erl -name bus@couchdb0.fabric_test -setcookie 'brumbrum' -kernel inet_dist_listen_min 9100 -kernel inet_dist_listen_max 9200
```

couchdb1

```bash
erl -name car@couchdb1.fabric_test -setcookie 'brumbrum' -kernel inet_dist_listen_min 9100 -kernel inet_dist_listen_max 9200
```

然后两者都进入了erlang的shell界面，在couchdb0的shell里面输入下面的命令

```erlang
net_kernel:connect_node('car@couchdb1.fabric_test').
```

返回`true`即可。

## 3 准备加入集群的 CouchDB 节点

通过下面的命令设置uuid和secret。

```bash
curl http://<server-IP|FQDN>:5984/_uuids?count=2

# CouchDB will respond with something like:
#   {"uuids":["60c9e8234dfba3e2fdab04bf92001142","60c9e8234dfba3e2fdab04bf92001cc2"]}
# Copy the provided UUIDs into your clipboard or a text editor for later use.
# Use the first UUID as the cluster UUID.
# Use the second UUID as the cluster shared http secret.

# Now, bind the clustered interface to all IP addresses availble on this machine
curl -X PUT http://<server-IP|FQDN>:5984/_node/_local/_config/chttpd/bind_address -d '"0.0.0.0"'

# If not using the setup wizard / API endpoint, the following 2 steps are required:
# Set the UUID of the node to the first UUID you previously obtained:
curl -X PUT http://<server-IP|FQDN>:5984/_node/_local/_config/couchdb/uuid -d '"FIRST-UUID-GOES-HERE"'

# Finally, set the shared http secret for cookie creation to the second UUID:
curl -X PUT http://<server-IP|FQDN>:5984/_node/_local/_config/couch_httpd_auth/secret -d '"SECOND-UUID-GOES-HERE"'
```

或者修改local.ini

```bash
curl http://localhost:5984/_uuids?count=2
# 返回 {"uuids":["9ff639bbb8d44f27a8187ca25d000261","9ff639bbb8d44f27a8187ca25d001076"]}
sed -i  '/\[couchdb\]/auuid = 9ff639bbb8d44f27a8187ca25d000261' /rel/couchdb/etc/local.ini 
sed -i '/\[couch_httpd_auth\]/a\\nsecret = 9ff639bbb8d44f27a8187ca25d001076' /rel/couchdb/etc/local.ini
```

## 4 集群设置api

之前的设置都可以不做，直接运行我的docker-compose就行了，都写好了。

```bash
# 启用集群，由于我们local.ini创建了用户，所以会自动启用。
curl -X POST -H "Content-Type: application/json" http://admin:adminpw@localhost:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"adminpw", "node_count":"3"}'

curl -X POST -H "Content-Type: application/json" http://admin:adminpw@localhost:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"adminpw", "port": 5984, "node_count": "3", "remote_node": "couchdb1.fabric_test", "remote_current_user": "admin", "remote_current_password": "adminpw" }'

curl -X POST -H "Content-Type: application/json" http://admin:adminpw@localhost:5984/_cluster_setup  -d '{"action": "add_node", "host":"couchdb1.fabric_test", "port": 5984, "username": "admin", "password":"adminpw"}'

curl -X POST -H "Content-Type: application/json" http://admin:adminpw@localhost:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"adminpw", "port": 5984, "node_count": "3", "remote_node": "couchdb2.fabric_test", "remote_current_user": "admin", "remote_current_password": "adminpw" }'

curl -X POST -H "Content-Type: application/json" http://admin:adminpw@localhost:5984/_cluster_setup  -d '{"action": "add_node", "host":"couchdb2.fabric_test", "port": 5984, "username": "admin", "password":"adminpw"}'

curl -X POST -H "Content-Type: application/json" http://admin:adminpw@localhost:5984/_cluster_setup -d '{"action": "finish_cluster","username": "admin", "password":"adminpw"}'

curl http://admin:adminpw@localhost:5984/_membership
```

然后测试一下

```
docker exec -w /rel/sample -t $(docker ps -q -f name=couchdb0) python loader.py
```



