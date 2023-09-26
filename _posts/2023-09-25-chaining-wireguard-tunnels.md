---
title: Chaining Wireguard Tunnels
description: Use Wireguard to route home network traffic to VPN
category: tech
toc: true
tags:
   - vpn
   - wireguard
---

I spent the last weekend attempting to chain two Wireguard tunnels: one that I use to connect to my home network and the other to forward my home network traffic to an external VPN of choice. This setup allows me to access local network and has all the benefits of using an external VPN while we are on the go.

[I am already using Wireguard]({% post_url 2020-05-01-how-to-setup-wireguard-pi-hole-on-debian-10-ubuntu-1804 %}) so the first tunnel has been set. However, setting up the second tunnel is a challenging feat. There are some articles<sup>[1](#ref-1),[2](#ref-2),[3](#ref-3)</sup> that provide valuable information for this setup. The notes below are my adaptation or workaround based on them.

## Set up external VPN tunnel
Download the generated Wireguard config by your VPN service of choice. I'm currently testing with [Mullvad](https://mullvad.net/). Also modify the `DNS` and add `FwMark` like below:

```
$ cat /etc/wireguard/vpn-client.conf

[Interface]
PrivateKey = XYZ123456ABC=                  # PrivateKey will be different              
Address = 10.68.172.129/32,fc00:bbbb:bbbb:bb01::5:ac80/128
DNS = 192.168.1.10                          # LAN address of the home server
FwMark = 51820                              # FwMark is important in this setup.

[Peer]
PublicKey = F+80gbmHVlOrU+es13S18oMEX2g=    # PublicKey will be different
AllowedIPs = 0.0.0.0/0,::0/0
Endpoint = 198.54.134.98:51820
```

Start the tunnel and verify we are connected:
```
$ wg-quick up vpn-client

$ curl https://am.i.mullvad.net/connected
You are connected to Mullvad ...
```

## Set up home network tunnel
This tunnel named `wg0` should already exist by following [this guide]({% post_url 2020-05-01-how-to-setup-wireguard-pi-hole-on-debian-10-ubuntu-1804 %}).

```
$ sudo wg

...
interface: wg0
  public key: <redacted>
  private key: (hidden)
  listening port: 51820
  fwmark: 0xca6c
...
```

The home tunnel came with a generated `/etc/systemd/system/wg-iptables.service` that interfered with this setup. We will need to remove it.

```
$ systemctl stop wg-iptables.service
$ systemctl disable wg-iptables.service
```

Edit the `/etc/wireguard/wg0.conf` to include new forwarding rules:
```
$ cat /etc/wireguard/wg0.conf

...
[Interface]
Address = 10.7.0.1/24
PrivateKey = <redacted>
ListenPort = 51820
FwMark = 51820 # Make sure this value is the same as defined in vpn-client.conf

# IMPORTANT: 
# replace enp2s0 with your actual network interface, e.g. eth0
# replace 192.168.1.0/24 with your LAN address subnet

# Forwarding...
PostUp  = iptables -A FORWARD -o enp2s0 ! -d 192.168.1.0/24 -j REJECT
PostUp  = iptables -A FORWARD -i %i -j ACCEPT
PostUp  = iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
PostUp  = iptables -A FORWARD -j REJECT
PreDown = iptables -D FORWARD -o enp2s0 ! -d 192.168.1.0/24 -j REJECT
PreDown = iptables -D FORWARD -i %i -j ACCEPT
PreDown = iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
PreDown = iptables -D FORWARD -j REJECT

# NAT...
PostUp  = iptables -t nat -A POSTROUTING -o enp2s0 -j MASQUERADE
PostUp  = iptables -t nat -A POSTROUTING -o vpn-client -j MASQUERADE
PreDown = iptables -t nat -D POSTROUTING -o enp2s0 -j MASQUERADE
PreDown = iptables -t nat -D POSTROUTING -o vpn-client -j MASQUERADE

# BEGIN_PEER
[Peer]
...
```

## Connect the dots
Spin up both tunnels if not already done so. Verify we are still connected to VPN.
```
$ wg-quick up vpn-client
$ wg-quick up wg0

$ curl https://am.i.mullvad.net/connected
You are connected to Mullvad ...
```

From **client**, connect to the home net work tunnel using the existing client conf and verify network traffic is routed through our VPN service. This can be done by checking for the IP on [https://whatismyipaddress.com](https://whatismyipaddress.com/) or the curl command above. Also check whether local services are still accessible.

----
## References
1. {: #ref-1} [https://www.reddit.com/r/WireGuard/comments/ekeprt/wireguard_to_wireguard_setup_im_sure_many_have/](https://www.reddit.com/r/WireGuard/comments/ekeprt/wireguard_to_wireguard_setup_im_sure_many_have/)  
2. {: #ref-2}[https://mgnik.wordpress.com/2019/03/05/raspberry-pi-as-a-vpn-gateway-using-wireguard/](https://mgnik.wordpress.com/2019/03/05/raspberry-pi-as-a-vpn-gateway-using-wireguard/)  
3. {: #ref-3}[https://archern9.github.io/posts/route-pivpn-traffic-via-mullvad/](https://archern9.github.io/posts/route-pivpn-traffic-via-mullvad/)  