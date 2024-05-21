#!/bin/sh

set -e

whoami

ls /app

# setting an address for loopback
ifconfig lo 127.0.0.1
ifconfig

# adding a default route
ip route add default dev lo src 127.0.0.1
route -n

# iptables rules to route traffic to transparent proxy
update-alternatives --set iptables /usr/sbin/iptables-legacy
iptables -A OUTPUT -t nat -p tcp --dport 1:65535 ! -d 127.0.0.1  -j DNAT --to-destination 127.0.0.1:1200
iptables -L -t nat

# generate identity key
/app/keygen --secret /app/id.sec --public /app/id.pub

# your custom setup goes here

# starting supervisord
cat /etc/supervisord.conf
/app/supervisord
