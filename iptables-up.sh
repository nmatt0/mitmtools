#!/bin/bash
IFACE="enp0s3"
sudo iptables -t nat --flush
sudo iptables -t nat -A PREROUTING -i ${IFACE} -p tcp --dport 443 -j REDIRECT --to-ports 8081
