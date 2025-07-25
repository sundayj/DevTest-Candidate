#!/bin/sh
set -e

apt-get update
apt-get install -y redis-server

# Configure Redis to run on port 6380
sed -ri "s/^port .*/port 6380/" /etc/redis/redis.conf

service redis-server start
