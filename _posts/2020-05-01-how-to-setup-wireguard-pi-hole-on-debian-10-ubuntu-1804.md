---
title: How to Setup Wireguard + Pi-hole on Debian 10 / Ubuntu 18.04
image: "/assets/img/openvpn-pihole.png"
description: How to Setup an Ad-free VPN with  Wireguard + Pi-hole on Debian 10 /
  Ubuntu 18.04
toc: true
category: tech
---

> WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec, while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general purpose VPN for running on embedded interfaces and super computers alike, fit for many different circumstances. Initially released for the Linux kernel, it is now cross-platform (Windows, macOS, BSD, iOS, Android) and widely deployable. It is currently under heavy development, but already it might be regarded as the most secure, easiest to use, and simplest VPN solution in the industry.
[https://www.wireguard.com](https://www.wireguard.com/)

## Introduction
Follow up for my post [How to host OpenVPN and Pi-hole on Ubuntu 18.04 VPS]({{ site.url }}{% post_url 2019-08-25-how-to-host-openvpn-and-pi-hole-on-ubuntu-1804-vps %}). This is a guide to set up wireguard + pi-hole for your own private ad blocking VPN.

## Installation

### Wireguard Setup
Run these scripts:
```shell
wget https://git.io/wireguard -O wireguard-install.sh && bash wireguard-install.sh
```

Follow this setup:
```shell
Welcome to this WireGuard road warrior installer!

I need to ask you a few questions before starting setup.
You can use the default options and just press enter if you are ok with them.

What IPv4 address should the WireGuard server use?
     1) Your IPv4 address should show up here
     2) other local IP
IPv4 address [1]: 1

What port do you want WireGuard listening to?
Port [51820]: 51820

Tell me a name for the first client.
Client name [client]: client

Which DNS do you want to use for this client?
   1) Current system resolvers
   2) 1.1.1.1
   3) Google
   4) OpenDNS
   5) NTT
   6) AdGuard
DNS [1]: 2

We are ready to set up your WireGuard server now.

Press any key to continue...
```

### Start Wireguard
Wireguard should start automatically after you ran the script. If not you can check by
```shell
systemctl status wg-quick@wg0.service
```

Restart Wireguard services:
```shell
systemctl restart wg-quick@wg0.service
```

### Pi-hole Setup
Note down  Wireguard's IP:
```shell
ip a show dev wg0
10.7.0.1/24 // note this address
```

Note down your default  gateway IP address:
```shell
ip r | grep default
default via XXX.XXX.XXX.XXX dev eth0 onlink // not this address
```

Run this script:
```shell
curl -sSL https://install.pi-hole.net | bash
```

Follow the instruction to set up pi-hole:

* Installing dependencies
{% include lazy-img.html src="/assets/img/pihole-wireguard-1.png" alt="step 1" %}

* The following step is important, make sure to select `wg0` as the interface
{% include lazy-img.html src="/assets/img/pihole-wireguard-2.png" alt="step 2" %}

* Choose the DNS provider Pi-hole will use. 
{% include lazy-img.html src="/assets/img/pihole-wireguard-3.png" alt="step 3" %}

* Choose the protocols available to you
{% include lazy-img.html src="/assets/img/pihole-wireguard-4.png" alt="step 4" %}

* This following step is important, make sure to choose `no` so we can assign our internal address which is `10.7.0.1`.
{% include lazy-img.html src="/assets/img/pihole-wireguard-5.png" alt="step 5" %}

* Enter `10.7.0.1/24`. This is the static address VPN will use to talk to Pi-hole
{% include lazy-img.html src="/assets/img/pihole-wireguard-6.png" alt="step 6" %}

* Enter the ipv4-gateway you noted down
{% include lazy-img.html src="/assets/img/pihole-wireguard-7.png" alt="step 7" %}

* There are a few more steps but I just choose the default settings.

### Test DNS settings
Run this script
```shell
host google.com 10.7.0.1

# Output from host google.com 10.7.0.1
google.com has address 172.217.0.46
google.com has IPv6 address 2607:f8b0:4005:80b::200e
google.com mail is handled by 10 aspmx.l.google.com.
google.com mail is handled by 20 alt1.aspmx.l.google.com.
google.com mail is handled by 30 alt2.aspmx.l.google.com.
google.com mail is handled by 40 alt3.aspmx.l.google.com.
google.com mail is handled by 50 alt4.aspmx.l.google.com.
```
Our Wireguard + Pi-hole still see google.com's public IPs properly

This time run
```shell
host pagead2.googlesyndication.com

# Output from host pagead2.googlesyndication.com
pagead2.googlesyndication.com has address 0.0.0.0
pagead2.googlesyndication.com has IPv6 address ::
pagead2.googlesyndication.com is an alias for pagead46.l.doubleclick.net.
```
Pi-hole blocked `pagead2.googlesyndication.com` as the domain is in its blacklist.


### Generate Wireguard Client Config File
	Run `bash wireguard-install.sh`

### Test From Browser
After connecting to your VPN using Wireguard client. Go to this address [http://pagead2.googlesyndication.com](http://pagead2.googlesyndication.com), if everything works correctly you will see this:
{% include lazy-img.html src="/assets/img/google-syndication.png" alt="google syndication" %}

### Pi-hole Statistics
You can go to `http://pi.hole/admin` once you are connected to the VPN and see some of Pi-hole's stats. The result is mind-boggling. Almost half of my traffic is to serve ads.
{% include lazy-img.html src="/assets/img/pi-hole-stats.png" alt="Pi-hole stats" %}

## Conclusion
Pi-hole is a good solution to fight against ads on the internet. You should give it a try. That said not all ads are bad. Some creators are reliant on ads as their source of income. If you have someone you support, consider whitelisting the ads for the good cause.

## References
* [https://github.com/Nyr/wireguard-install](https://github.com/Nyr/wireguard-install)
* [https://pi-hole.net/](https://pi-hole.net/)