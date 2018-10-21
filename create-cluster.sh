#!/bin/bash
# set -v on
# 暂时固定死名称, 后期使用参数
arr_name=(REDIS REDIS_1 REDIS_2 REDIS_3 REDIS_4 REDIS_5)
# docker stop REDIS REDIS_1 REDIS_2 REDIS_3 REDIS_4 REDIS_5
# docker rm REDIS REDIS_1 REDIS_2 REDIS_3 REDIS_4 REDIS_5
# docker run -v /docker/redis/conf/redis.conf:/usr/local/etc/redis/redis.conf \
# --name REDIS -P -d redis redis-server /usr/local/etc/redis/redis.conf

# 停止
echo 'stop container...'
docker stop ${arr_name[@]}
# 删除
echo 'rm container...'
docker rm ${arr_name[@]}
# 创建
echo 'create container...'
for name in ${arr_name[@]}
do
  docker run --name $name -P -d redis redis-server \
  --cluster-enabled yes \
  --cluster-config-file nodes.conf \
  --cluster-node-timeout 5000 \
  --appendonly yes
done

# 获取分配的端口号, 暂时没用
# docker ps -f name=REDIS* | awk '{print $10}'

# 获取容器的ip数组
OLD_IFS="$IFS"
IFS='\n'
arr_ip=`docker inspect ${arr_name[@]} | \
grep '"IPAddress":' | \
awk '{print $2}' | \
awk -F '"' '{print $2}' | \
uniq`
IFS="$OLD_IFS"

# ./redis-cli --cluster create \
# 172.17.0.1:32788 \
# 172.17.0.1:32789 \
# 172.17.0.1:32790 \
# 172.17.0.1:32791 \
# 172.17.0.1:32792 \
# 172.17.0.1:32793 \
# --cluster-replicas 1

echo $arr_ip
# 拼接后的ip
str_ip=''
for ip in ${arr_ip[@]}
do
  str_ip=$str_ip' '$ip':6379'
done

echo 'create cluster...'
./redis-cli --cluster create $str_ip --cluster-replicas 1
