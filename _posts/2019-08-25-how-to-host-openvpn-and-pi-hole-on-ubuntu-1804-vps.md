---
title: How to host OpenVPN and Pi-hole on Ubuntu 18.04 VPS
image: "/assets/img/openvpn-pihole.png"
description: how to host OpenVPN and Pi-hole on Ubuntu 18.04 VPS
toc: true
category: tech
---

## Introduction
I have been playing around with setting up my own [OpenVPN server](https://openvpn.net) lately and also found out [Pi-hole](https://pi-hole.net).  OpenVPN provides a way to set up a VPN that I can self manage and Pi-hole is a network wide ad blocking system. The two combined services provide a good way to make your web browsing experience more secure and ad-free. 

[I followed the guide on Pi-hole to set up a VPN server](https://docs.pi-hole.net/guides/vpn/setup-openvpn-server/) but I found out that some information is missing depending on the type of VPS you have such as whether your VPS is a NAT VPS or not. Below is the documented steps of all my findings.

## Installation

### OpenVPN Setup
Run these scripts:
```shell
wget https://git.io/vpn -O openvpn-install.sh
chmod 755 openvpn-install.sh
./openvpn-install.sh
```

Follow this setup:
```shell
Welcome to this quick OpenVPN "road warrior" installer

I need to ask you a few questions before starting the setup
You can leave the default options and just press enter if you are ok with them

First I need to know the IPv4 address of the network interface you want OpenVPN
listening to.
IP address: 10.8.0.1 // Jason's notes: if you are behind NAT, just put your  ipv4 IP address

Which protocol do you want for OpenVPN connections?
   1) UDP (recommended)
   2) TCP
Protocol [1-2]: 1

What port do you want OpenVPN listening to?
Port: 1194

Which DNS do you want to use with the VPN?
   1) Current system resolvers
   2) Google
   3) OpenDNS
   4) NTT
   5) Hurricane Electric
   6) Verisign
DNS [1-6]: 1

Finally, tell me your name for the client certificate
Please, use one word only, no special characters
Client name: pihole

Okay, that was all I needed. We are ready to set up your OpenVPN server now
Press any key to continue...
```

### Start OpenVPN
I had to modify the existing OpenVPN service in `/lib/systemd/system/openvpn.service` with the following:

```shell
# This service is actually a systemd target,
# but we are using a service since targets cannot be reloaded.

[Unit]
Description=OpenVPN service
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecReload=/bin/true
WorkingDirectory=/etc/openvpn/server

[Install]
WantedBy=multi-user.target
```

Also modify OpenVPN server's configuration in `/etc/openvpn/server/server.conf`:
remove all the existing `push "dhcp-option DNS x.x.x.x` and add `push "dhcp-optioni DNS 10.8.0.1"`

Restart OpenVPN services:
```shell
systemctl daemon-reload
systemctl restart openvpn // Jason's notes: just restarting openvpn does not change the configuration for OpenVPN server.
systemctl restart openvpn-server@server.service
```

Notes: if you are behind a NAT, you will also need to do the following:
```shell
ip r | grep default

# Output from ip r | grep default
default via x.x.x.x dev eth0 onlink
```
Note the value after `dev` in this case it is `eth0`
Run  this:
```shell
iptables -t nat -A POSTROUTING  -s 10.8.0.0/24 -o <value you got from above> -j MASQUERADE

# Example:
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

### Pi-hole Setup
Run this script:
```shell
curl -sSL https://install.pi-hole.net | bash
```

Follow the instruction to set up pi-hole:

* Installing dependencies
{% include lazy-img.html src="/assets/img/pihole-step-1.png" alt="step 1" %}

* Some instruction
{% include lazy-img.html src="/assets/img/pihole-step-2.png" alt="step 2" %}

* Some information
{% include lazy-img.html src="/assets/img/pihole-step-3.png" alt="step 3" %}

* This informs we need a **static IP address** in order the the whole thing to work
{% include lazy-img.html src="/assets/img/pihole-step-4.png" alt="step 4" %}

* The following step is important, make sure to select `tun0` as the interface
{% include lazy-img.html src="/assets/img/pihole-step-5.png" alt="step 5" %}

* Choose the DNS provider Pi-hole will use. This is interesting. Essentially we will set up pi-hole as a DNS OpenVPN server will use, and within Pi-hole it will use the DNS setting below to make outbound requests.
{% include lazy-img.html src="/assets/img/pihole-step-6.png" alt="step 6" %}

* Choose the protocols available to you
{% include lazy-img.html src="/assets/img/pihole-step-7.png" alt="step 7" %}

* This following step is important, make sure to choose `no` so we can assign our internal address which is `10.8.0.1`.
{% include lazy-img.html src="/assets/img/pihole-step-8.png" alt="step 8" %}

* Enter `10.8.0.1/24`. This is the static address VPN will use to talk to Pi-hole
{% include lazy-img.html src="/assets/img/pihole-step-9.png" alt="step 9" %}

* Enter the ipv4-gateway. I just leave this as is.
{% include lazy-img.html src="/assets/img/pihole-step-10.png" alt="step 10" %}

* There are a few more steps but I just choose the default settings.

### Test DNS settings
Run this script
```shell
host google.com 10.8.0.1

# Output from host google.com 10.8.0.1
google.com has address 172.217.0.46
google.com has IPv6 address 2607:f8b0:4005:80b::200e
google.com mail is handled by 10 aspmx.l.google.com.
google.com mail is handled by 20 alt1.aspmx.l.google.com.
google.com mail is handled by 30 alt2.aspmx.l.google.com.
google.com mail is handled by 40 alt3.aspmx.l.google.com.
google.com mail is handled by 50 alt4.aspmx.l.google.com.
```
Our OpenVPN + Pi-hole still see google.com's public IPs properly

This time run
```shell
host pagead2.googlesyndication.com

# Output from host pagead2.googlesyndication.com
pagead2.googlesyndication.com has address 0.0.0.0
pagead2.googlesyndication.com has IPv6 address ::
pagead2.googlesyndication.com is an alias for pagead46.l.doubleclick.net.
```
Pi-hole blocked `pagead2.googlesyndication.com` as the domain is in its blacklist.

### Firewall Setup
[I followed Pi-hole's setup](https://docs.pi-hole.net/guides/vpn/firewall/)

### Generate OpenVPN Client Config File
Run `./openvpn-install.sh`

### Test From Browser
After connecting to your VPN using OpenVPN client. Go to this address [http://pagead2.googlesyndication.com](http://pagead2.googlesyndication.com), if everything works correctly you will see this:
{% include lazy-img.html src="/assets/img/google-syndication.png" alt="google syndication" %}

### Pi-hole Statistics
You can go to `http://pi.hole/admin` once you are connected to the VPN and see some of Pi-hole's stats. The result is mind-boggling. Almost half of my traffic is to serve ads.
{% include lazy-img.html src="/assets/img/pi-hole-stats.png" alt="Pi-hole stats" %}

## Conclusion
Pi-hole is a good solution to fight against ads on the internet. You should give it a try. That said not all ads are bad. Some creators are reliant on ads as their source of income. If you have someone you support, consider whitelisting the ads for the good cause.

## References
* [https://docs.pi-hole.net/guides/vpn/overview/](https://docs.pi-hole.net/guides/vpn/overview/)
* [https://www.digitalocean.com/community/tutorials/how-to-block-advertisements-at-the-dns-level-using-pi-hole-and-openvpn-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-block-advertisements-at-the-dns-level-using-pi-hole-and-openvpn-on-ubuntu-16-04)
* [https://wiki.openvz.org/VPN_via_the_TUN/TAP_device](https://wiki.openvz.org/VPN_via_the_TUN/TAP_device)