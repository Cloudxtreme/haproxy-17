# HAProxy Dockerfile

## Usage

### Cluster startup

Open a Terminal in the directory of the provided `docker-compose.yml` config
file.

Start 3 web servers, 3 Redis masters and 3 Redis sentinels monitoring the first
Redis master:

```sh
docker-compose -p haproxy scale web=3 redis=3 sentinel=3
```

Start the HAProxy instances for the web servers and Redis nodes:

```sh
docker-compose -p haproxy up -d
```

### Redis master proxy

Retrieve the ip and port of the first Redis master:

```sh
REDIS_MASTER=$(docker exec haproxy_sentinel_1 redis-cli -p 26379 \
  sentinel get-master-addr-by-name redis-master)
```

Make the second and third master slaves of the first:

```sh
docker exec haproxy_redis_2 redis-cli slaveof $REDIS_MASTER
docker exec haproxy_redis_3 redis-cli slaveof $REDIS_MASTER
```

Create a `redis-cli` command alias pointing to the Redis master proxy:

```sh
alias redis-cli='docker run --rm -it --link haproxy_redis_master_proxy_1:redis'\
' blueimp/redis:3.0 redis-cli -h redis'
```

Display info about the current Redis master:

```sh
redis-cli info
```

Force a failover of the current Redis master:

```sh
docker exec haproxy_sentinel_1 redis-cli -p 26379 sentinel failover redis-master
```

Display info about the new Redis master:

```sh
redis-cli info
```

### Web load balancer

Open a browser with the URL of your docker host:

```sh
open http://$(docker-machine ip)
```

Reload a couple of times and watch the web server logs to see the load balancing
in action:

```
docker-compose -p haproxy logs web
```

## License
Released under the [MIT license](http://www.opensource.org/licenses/MIT).

## Author
[Sebastian Tschan](https://blueimp.net/)
