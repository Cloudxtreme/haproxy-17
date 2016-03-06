# HAProxy Dockerfile

## HTTP and HTTPS load balancing

### Hostname setup
Add `dev.test` as hostname for your docker machine:

```sh
printf '%s\t%s\n' $(docker-machine ip) dev.test |
  sudo tee -a /etc/hosts
```

### SSL setup
Generate SSL files for the web servers:

```sh
mkdir ssl

openssl req -nodes -x509 -newkey rsa:2048 \
  -subj '/C=/ST=/L=/O=/OU=/CN=dev.test' \
  -keyout ssl/default.key \
  -out ssl/default.crt

openssl dhparam -out ssl/dhparam.pem 2048
```

### Web server cluster startup
Start three web servers and their load balancer:

```sh
docker-compose scale web=3
docker-compose up -d web_haproxy
```

### Load balancing test
Open a browser with the URL of the hostname set up before:

```sh
open http://dev.test
```

Follow the logs to see the load balancing in action:

```
docker-compose logs
```

Please note that the HTTPS load balancing makes use of Source IP affinity to
reuse SSL sessions.

## Redis High Availability

### Redis nodes startup
Start three Redis masters and three Redis sentinels monitoring the first Redis
master:

```sh
docker-compose -p haproxy scale redis=3 sentinel=3
```

### Redis master/slave setup
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

### Redis master proxy startup
Start HAProxy as Redis master proxy:

```sh
docker-compose -p haproxy up -d redis_haproxy
```

### Redis CLI alias
Create a `redis-cli` command alias pointing to the Redis master proxy:

```sh
alias redis-cli='docker run --rm -it --link haproxy_redis_haproxy_1:redis'\
' blueimp/redis:3.0 redis-cli -h redis'
```

### Redis failover test
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

## License
Released under the [MIT license](http://www.opensource.org/licenses/MIT).

## Author
[Sebastian Tschan](https://blueimp.net/)
