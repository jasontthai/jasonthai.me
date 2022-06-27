---
title: "[Series] PART IV: Example Setup of Distributed Load Balancing
  Wallabag with Data Tier Clustering"
toc: true
image: "/assets/img/ha-cluster.png"
description: 'High Availability Series: Example Setup of Distributed Load Balancing
  Wallabag with Data Tier Clustering. How to set up a highly available Wallabag with
  docker-compose powered by HAProxy, Apache2 and Galera cluster.'
category: tech
tags:
  - high availibility
---

![HA Distributed Web Apps](/assets/img/ha-cluster.png)

# Introduction
>Wallabag is a self hostable application for saving web pages: Save and classify articles. Read them later. Freely
>[https://wallabag.org/en](https://wallabag.org/en)

This post will provide an example of setting up a highly available web application. We will cover set up Wallabag using Docker Compose and configure HAProxy to load balance the multiple webservers that run Wallabag.

# Prerequisite
You should have set up the Galera cluster and configured HAProxy as the load balancer for the DB nodes. As shown in the diagram, the webserver node is the same as the HAProxy node configured to communicate with Galera cluster.
Refer to all the previous posts of HA Series to set them up:

* [[High Availability Series] PART I: Set Up and Use SSL to Secure MariaDB on Debian Servers]({{ site.url }}{% post_url 2020-06-08-high-availability-series-part-i-set-up-and-secure-mariadb-on-debian-servers %})

* [[High Availability Series] PART II: Configure and Secure a 3-node Galera Cluster]({{ site.url }}{% post_url 2020-06-20-high-availability-series-part-ii-configure-and-secure-a-3-node-galera-cluster %})

* [[High Availability Series] PART III: High Availability Galera Cluster with HAProxy and Stunnel]({{ site.url }}{% post_url 2020-07-03-high-availability-series-part-iii-high-availability-galera-cluster-with-haproxy-and-stunnel %})

You should also have set up Apache2 as your web server, and installed Docker and Docker Compose:
```sh
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sh get-docker.sh

$ sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose

$ sudo apt install apache2
$ sudo a2enmod ssl proxy proxy_http
```

Note the IP of docker0 proto on the webserver node:
```sh
$ ip r | grep docker0
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
```
The value is usually `172.17.0.1`

# Configure the first webserver instance
## Install Wallabag 
Create the `docker-compose.yml` and add the following lines:
```sh
version: '2'
services:
  wallabag:
    image: wallabag/wallabag
    logging:
      driver: "json-file"
      options:
        max-file: "3"
        max-size: "10m"
    environment:
      - POPULATE_DATABASE=false
      - SYMFONY__ENV__DATABASE_DRIVER=pdo_mysql
      - SYMFONY__ENV__DATABASE_HOST=172.17.0.1
      - SYMFONY__ENV__DATABASE_PORT=3307
      - SYMFONY__ENV__DATABASE_NAME=wallabag
      - SYMFONY__ENV__DATABASE_USER=wallabag
      - SYMFONY__ENV__DATABASE_PASSWORD="SOME SECURE PASSWORD"
      - SYMFONY__ENV__DATABASE_CHARSET=utf8mb4
      - SYMFONY__ENV__MAILER_HOST=ENTER YOUR VALUE HERE
      - SYMFONY__ENV__MAILER_USER=ENTER YOUR VALUE HERE
      - SYMFONY__ENV__MAILER_PASSWORD=ENTER YOUR VALUE HERE
      - SYMFONY__ENV__FROM_EMAIL=ENTER YOUR VALUE HERE
      - SYMFONY__ENV__DOMAIN_NAME=ENTER YOUR VALUE HERE
      - SYMFONY__ENV__FOSUSER_REGISTRATION=false
    ports:
      - 8080:80
    volumes:
      - /opt/wallabag/images:/var/www/wallabag/web/assets/images
    restart: always
    network_mode: bridge
```
Explanation of a few options:
* **SYMFONYENVDATABASE_HOST=172.17.0.1** - The IP of docker0 proto we noted earlier. This tells docker to talk to the localhost mysql instance. Why not `127.0.0.1` ? Because docker communicates in its own subnet and `127.0.0.1` does not mean localhost.
* **SYMFONYENVDATABASE_PORT=3307** - As previously configured, `3307` is the port we expose through HAProxy to talk to our Galera cluster
* **network_mode: bridge** - Configure the network mode in order for docker to talk to local mysql on the webserver node.

Start the container:
```sh
$ docker-compose up -d
```

## Configure Apache reverse proxy to expose Wallabag to end users
The domain I use is [https://wallabag.jasonthai.me](http://wallabag.jasonthai.me), you can change this to your own one.

Create `/etc/apache2/sites-available/wallabag.jasonthai.me.conf` and add the following:
```sh
<VirtualHost *:80>
    ServerName wallabag.jasonthai.me
    Redirect permanent / https://wallabag.jasonthai.me/
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName wallabag.jasonthai.me
    ServerAlias wallabag.jasonthai.me

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/

    ErrorLog ${APACHE_LOG_DIR}/wallabag-error.log
    CustomLog ${APACHE_LOG_DIR}/wallabag-access.log combined
SSLEngine on
SSLCertificateFile /etc/letsencrypt/live/jasonthai.me/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/jasonthai.me/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
```
Note: I have already configured SSL/TLS certificates. You need to configure one yourself.

Enable the configuration and reload apache2:
```sh
$ sudo a2ensite /etc/apache2/sites-available/wallabag.jasonthai.me.conf
$ sudo systemctl reload apache2
```

# Configure the second and third webserver node
Do the same as the first node
# Configure HAProxy to load balance three webservers
ON your separate HAProxy node, Edit `/etc/haproxy/haproxy.cfg` and add the following (remember to replace with your actual domain):
```sh
frontend https-in
    # Only bind on 80 if you also want to listen for connections on 80
    bind *:443 ssl crt /etc/certs/jasonthai.me.pem
    bind :::443 ssl crt /etc/certs/jasonthai.me.pem
    option httplog
    mode http
		
    acl wallabag hdr(host) -i wallabag.jasonthai.me
    use_backend wallabag if wallabag

    default_backend no-match
		
backend wallabag
    mode http
    balance roundrobin
    option ssl-hello-chk
    option httpchk HEAD /login HTTP/1.1\r\nHost:wallabag.jasonthai.me
    http-check expect status 200

    http-request disable-l7-retry if METH_POST

    default-server ssl sni req.hdr(Host) check check-ssl verify none
    # Add an entry for each of your backend servers and their resolvable hostnames
    server webserver-01 IP-of-webserver-01:443
    server webserver-02 IP-of-webserver-02:443
    server webserver-03 IP-of-webserver-03:443
```
Note: I have already configured SSL/TLS certificates. You need to configure one yourself.

# Configure DNS for your Wallabag and IP
Depending on your DNS provider, you will need to configure this yourself. Point your Wallabag domain you configured to the IP address of HAProxy node we have just configured. You may also add another HAProxy node and use a GEO-based DNS to improve the performance and add some more redundancy.

# Conclusion
This post provides an example of setting up a highly available Wallabag using the technology we have convered so far in the high availability series. Future post will go into details of some failover mechanisms and good practices for HA systems.
# References
[[High Availability Series] PART I: Set Up and Use SSL to Secure MariaDB on Debian Servers]({{ site.url }}{% post_url 2020-06-08-high-availability-series-part-i-set-up-and-secure-mariadb-on-debian-servers %})

[[High Availability Series] PART II: Configure and Secure a 3-node Galera Cluster]({{ site.url }}{% post_url 2020-06-20-high-availability-series-part-ii-configure-and-secure-a-3-node-galera-cluster %})

[[High Availability Series] PART III: High Availability Galera Cluster with HAProxy and Stunnel]({{ site.url }}{% post_url 2020-07-03-high-availability-series-part-iii-high-availability-galera-cluster-with-haproxy-and-stunnel %})

[https://galeracluster.com/library/documentation/deployment-variants.html](https://galeracluster.com/library/documentation/deployment-variants.html)
