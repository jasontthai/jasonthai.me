---
title: "[High Availability Series] PART III: High Availability Galera Cluster with
  HAProxy and Stunnel"
image: "/assets/img/haproxy-galera.png"
description: 'High Availability Series: High Availability Galera Cluster with HAProxy
  and Stunnel'
toc: true
category: tech
---

# Introduction
{% include lazy-img.html src="/assets/img/haproxy-galera.png" alt="HA Galera Cluster" %}

> HAProxy is a free, very fast and reliable solution offering high availability, load balancing, and proxying for TCP and HTTP-based applications. It is particularly suited for very high traffic web sites and powers quite a number of the world's most visited ones. Over the years it has become the de-facto standard opensource load balancer, is now shipped with most mainstream Linux distributions, and is often deployed by default in cloud platforms
[https://www.haproxy.org](https://www.haproxy.org)

> Stunnel is a proxy designed to add TLS encryption functionality to existing clients and servers without any changes in the programs' code. Its architecture is optimized for security, portability, and scalability (including load-balancing), making it suitable for large deployments.
[https://www.stunnel.org](https://www.stunnel.org)

We will configure HAProxy as a load balancer to our Galera cluster.  This will help prevent having a single point of failure if any of our DB node is down. HAProxy will automatically route traffic to the other available nodes and keep connection to the cluster up.

Stunnel is not necessary if connection between HAProxy to the DB nodes is private. This may not be the case if our DB node is geographically separated or from different providers where private subnets are not possible. We will configure Stunnel to ensure there is a private and secure tunnel between HAProxy to each of the DB nodes.

# Prerequisite
Determine how to install HAProxy 2.1 for your Debian based servers by going to [https://haproxy.debian.net/](https://haproxy.debian.net/)

Install Stunnel on our Galera nodes and HAProxy node: 
```sh
$galera-01 sudo apt-get install -y stunnel4
```
# Configure Stunnel on the first Galera node:
Create `/etc/stunnel/mysql.conf` and add the following:
```sh
# Configure our secured MySQL server

pid = /run/stunnel.pid

# set to yes to allow logging to syslog
syslog = no

[mysql-server-galera-01]
cert = /etc/mysql/certs/client-cert.pem
key = /etc/mysql/certs/client-key.pem
accept  = 13306
connect = 3306
```
# Configure Stunnel on the second Galera node:
Create `/etc/stunnel/mysql.conf` and add the following:
```sh
# Configure our secured MySQL server

pid = /run/stunnel.pid

# set to yes to allow logging to syslog
syslog = no

[mysql-server-galera-02]
cert = /etc/mysql/certs/client-cert.pem
key = /etc/mysql/certs/client-key.pem
accept  = 23306
connect = 3306
```
# Configure Stunnel on the third Galera node:
Create `/etc/stunnel/mysql.conf` and add the following:
```sh
# Configure our secured MySQL server

pid = /run/stunnel.pid

# set to yes to allow logging to syslog
syslog = no

[mysql-server-galera-03]
cert = /etc/mysql/certs/client-cert.pem
key = /etc/mysql/certs/client-key.pem
accept  = 33306
connect = 3306
```
# Configure Stunnel on our HAProxy node:
From any of the DB nodes, create `stunnel.pem` file:
```sh
$galera-01 sudo cat /etc/mysql/certs/ca-cert.pem /etc/mysql/certs/client-cert.pem > /etc/mysql/certs/stunnel.pem
```

Copy `stunnel.pem` to `/etc/mysql/certs` on our HAProxy node.


Create `/etc/stunnel/mysql.conf` and add the following:
```sh
# Configure our secured MySQL server

pid = /run/stunnel.pid

# set to yes to allow logging to syslog
syslog = no

[mysql-client-galera-01]
client = yes
CAfile = /etc/mysql/certs/stunnel.pem
accept  = 127.0.0.1:13306
connect = IP-of-node1:23306
verify = 2
verifyChain = yes

[mysql-client-galera-02]
client = yes
CAfile = /etc/mysql/certs/stunnel.pem
accept  = 127.0.0.1:23306
connect = IP-of-node2:23306
verify = 2
verifyChain = yes

[mysql-client-galera-03]
client = yes
CAfile = /etc/mysql/certs/stunnel.pem
accept  = 127.0.0.1:33306
connect = IP-of-node3:33306
verify = 2
verifyChain = yes
```
Some explanations of the configurations:
* **client** - specify that we are configuring to connect as a client
* **CAfile** - specify the Cert Authority and the cert we will be using
* **accept** - accept connections on specified address
* **connect** - connect to a remote address
* **verify** - verify the peer certificate.
* **verifiyChain** - verify the peer certificate chain starting from the root CA

Restart Stunnel to apply the config:
```sh
$haproxy sudo systemctl restart stunnel4
```

Check that all the connections are up:
```sh
$haproxy-node sudo ss -tulpn | grep LISTEN
tcp     LISTEN   0        128            127.0.0.1:13306          0.0.0.0:*      users:(("stunnel4",pid=25228,fd=7))
tcp     LISTEN   0        128            127.0.0.1:23306          0.0.0.0:*      users:(("stunnel4",pid=25228,fd=8))
tcp     LISTEN   0        128            127.0.0.1:33306          0.0.0.0:*      users:(("stunnel4",pid=25228,fd=9))
```

# Configure HAProxy
On one of the DB node,  login to MYSQL Console and create a user haproxy@127.0.0.1:
```sh
$galera-01 sudo mysql
MariaDB [(none)]> create user 'haproxy'@'127.0.0.1' IDENTIFIED BY 'SOME-SECURE-PASSWORD';
```
This step is needed so HAProxy can do a health check to see whether our nodes are up and running.


Edit `/etc/haproxy/haproxy.cfg` and add the following:
```sh
frontend galera_cluster_frontend
    bind *:3307
    mode tcp
    option tcplog
    default_backend galera_cluster_backend

backend galera_cluster_backend
    mode tcp
    option tcpka
    option mysql-check user haproxy
    option dontlog-normal
    balance roundrobin
    server galera-01 127.0.0.1:13306 check weight 1
    server galera-02 127.0.0.1:23306 check weight 1
    server galera-03 127.0.0.1:33306 check weight 1

frontend stats
    bind *:8404
    stats enable
    stats uri /
    stats refresh 10s
```
Some explanations of options:
* **balance** – This defines the destination selection policy used to select a server to route the incoming connections to.
* **mode tcp** – Galera Cluster uses TCP type of connections.
* **option tcpka** – Enables the keepalive function to maintain TCP connections.
* **option mysql-check user haproxy** – Define backend database server check, to determine whether the node is currently operational.
* **server  "server-name" "IP_address" check weight 1** – Defines the nodes you want HAProxy to use in routing connections.


Restart HAProxy to apply the config:
```sh
$haproxy sudo systemctl restart haproxy
```
# Test Connection via HAProxy
Check that HAProxy has a bind on port 3307:
```sh
$haproxy sudo ss -tunelp | grep 3307
tcp     LISTEN   0        128              0.0.0.0:3307          0.0.0.0:*      users:(("haproxy",pid=18324,fd=5))
```

Try to connect from HAProxy to port 3307:
```sh
$haproxy sudo mysql -h 127.0.0.1 -P 3307 -u some_user -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 39834
Server version: 10.4.13-MariaDB-1:10.4.13+maria~buster mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

# Checking HAProxy's Stats Page
If you noticed, we have configured a stats page for HAProxy on port 8404 in our config file. You can check out the stats page by going to `http://IP-of-HAProxy-node:8404`

You will see something like this:
{% include lazy-img.html src="/assets/img/haproxy-stats.png" alt="HAProxy Stats" %}

# Conclusion:
We have configured a HAProxy node as a load balancer to our Galera cluster. Connection between HAProxy to the three nodes is secured by Stunnel. In the next post, we will go over setting up a full HA webservers that are powered by a HA Galera cluster.

# Resources:
[[High Availability Series] PART I: Set Up and Use SSL to Secure MariaDB on Debian Servers]({{ site.url }}{% post_url 2020-06-08-high-availability-series-part-i-set-up-and-secure-mariadb-on-debian-servers %})

[[High Availability Series] PART II: Configure and Secure a 3-node Galera Cluster]({{ site.url }}{% post_url 2020-06-20-high-availability-series-part-ii-configure-and-secure-a-3-node-galera-cluster %})

[https://computingforgeeks.com/galera-cluster-high-availability-with-haproxy-on-ubuntu-18-04-centos-7](https://computingforgeeks.com/galera-cluster-high-availability-with-haproxy-on-ubuntu-18-04-centos-7)
