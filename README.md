# Redis6 ACL support

This is a small workshop/hands-on session with regard to Redis6 ACL (Access Control List).

The use case is to have support for readonly redis - Applications and services should have readonly access to redis.

# Redis5

Readonly with Redis5 is achieved with "master" "slave" redis instances.

Have a look at `redis_5/docker-compose.yml`.

```
cd redis_5
# Start redis (6379, 6380).
docker-compose up -d
# Access a container to get access to both redis instances.
docker exec -it redis_5_redis_1 ash
# Connect to the "master" redis.
redis-cli
# Authenticate (password is 'main'), set some values.
$ auth main
$ set plain 12
$ keys * or scan 0
$ flushall
$ set plain 12
$ set secret password
$ scan 0
$ get secret
# Quit and connect to "slave" redis.
$ quit
redis-cli -h redis1 -p 6380
# Authenticate (password is 'second'), get some values.
$ auth second
# Can list ALL keys.
$ keys *
# Can read ALL values.
$ get secret
# Cannot write.
$ set price 55
  (error) READONLY You can't write against a read only replica.
$ flushall
  (error) READONLY You can't write against a read only replica.
# Quit, exit and clean up.
$ quit
exit
docker-compose rm -sf
cd ../
```

With this setup a readonly user cannot tamper with the data, but can read everything.

Requires 2 Redis instances.

# Redis6

Redis6 has ACL support.
Readonly with Redis6 is achieved by creating users with specific ACL rules that restrict commands, command categories and the keyspace.

Have a look at `redis_6/docker-compose.yml`.

```
cd redis_6
# Start redi (6379).
docker-compose up -d
# Access the container to get access to the redis instance.
docker exec -it redis_6_redis_1 ash
# Connect to redis.
redis-cli
# Authenticate (password is 'main'), set some values.
$ auth default main
  equivalent to 'auth main' with 'default' user
# Show some ACL commands.
$ acl help
  shows subcommands
  list users 'acl users'
  show user details 'acl list'
  whoami 'acl whoami'
  etc.
# Use keys according to proper naming scheme (important for restricing keyspace later).
$ set public:users:u1:username tom
$ set secret:users:u1:password tomspasswd
# Create the read only user 'read_all'.
# Is only allowed to use the 'get' command, allowed to read ALL keys (entire keyspace).
$ acl setuser read_all on >password -@all nocommands +get ~*
# Authenticate as 'read_all'.
$ auth read_all password
# 'read_all' is resticted to 'get'.
$ acl whoami
  not allowed
$  keys *
  (error) NOPERM this user has no permissions to run the 'keys' command or its subcommand
$  flushall
  (error) NOPERM this user has no permissions to run the 'flushall' command or its subcommand
# 'read_all' can read ALL keys.
$  get public:users:u1:username
$  get secret:users:u1:password
# 'read_all' cannot write.
$  set public:users:u1:username tim
  (error) NOPERM this user has no permissions to run the 'set' command or its subcommand
```
With this setup a readonly user cannot tamper with the data, but can read everything.
However, the readonly user also is restricted to the use of the `get` command only.

Requires 1 Redis instances.

```
# Authenticate as 'default'. 
$ auth default main
# Create the read only user 'read_public'.
# Is only allowed to use the 'get' command, allowed to read keys with the 'public:*' namespace.
$ acl setuser read_public on >password -@all nocommands +get ~public:*
# Authenticate as 'read_public'.
$ auth read_public password
# 'read_public' is resticted to 'get'.
$ keys *
  (error) NOPERM this user has no permissions to run the 'keys' command or its subcommand
$ flushall
  (error) NOPERM this user has no permissions to run the 'flushall' command or its subcommand
# 'read_public' cannot read ALL keys, restricted to the 'public:*' namespace.
$  get public:users:u1:username
$  get secret:users:u1:password
   (error) NOPERM this user has no permissions to access one of the keys used as arguments
# 'read_public' cannot write.
$  set public:users:u1:username tim
  (error) NOPERM this user has no permissions to run the 'set' command or its subcommand
# Quit, exit and clean up.
$ quit
exit
docker-compose rm -sf
cd ../
```

With this setup, in addition to the points mentioned above, the readonly user also is restrrited to a specific keyspace/key namespace.


A proper key can look like this:

`secret:users:u1:password`

|`namespace` or `label`|`object_type`|`id`|`name`    |
|----------------------|-------------|----|----------|
|`secret`              |`users`      |`u1`|`password`|

```
set secret:users:u1:password secret_password
```

