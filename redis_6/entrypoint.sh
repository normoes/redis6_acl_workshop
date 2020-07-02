#!/bin/sh

# authentication
if [ -n "$REDIS_PASSWORD" ]; then
  REDIS_AUTH="--requirepass $REDIS_PASSWORD"
fi

# master authentication
if [ -n "$REDIS_MASTER_PASSWORD" ]; then
  REDIS_MASTER_AUTH="--masterauth $REDIS_MASTER_PASSWORD"
fi

REDIS_SERVER="redis-server $@ $REDIS_AUTH $REDIS_MASTER_AUTH --timeout 300 --tcp-keepalive 60 --loglevel notice --databases 16 --     maxclients 2048 --maxmemory 512mb --maxmemory-policy volatile-lru"

set -- $REDIS_SERVER

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # from the official redis base image
  find . \! -user redis -exec chown redis '{}' +
  # gosu is already used in official redis base image
  exec su-exec redis $@
fi

exec $@
