---
title: Set Up Nginx + Varnish for High Traffic Websites
description: How to set up Nginx + Varnish for high traffic websites
image: "/assets/img/NginxVarnish.png"
category: tech
toc: true
---

{% include lazy-img.html src="/assets/img/NginxVarnish.png" alt="Nginx + Varnish" %}
# Introduction
>nginx [engine x] is an HTTP and reverse proxy server, a mail proxy server, and a generic TCP/UDP proxy server
>[https://nginx.org](https://nginx.org)

>Varnish Cache is a web application accelerator also known as a caching HTTP reverse proxy. You install it in front of any server that speaks HTTP and configure it to cache the contents. Varnish Cache is really, really fast. It typically speeds up delivery with a factor of 300 - 1000x, depending on your architecture.
>[https://varnish-cache.org](https://varnish-cache.org)

This guide will go over how to utilize the two components to power a high traffic website. We will take [https://jasonthai.me](https://jasonthai.me) as an the website we want to set up for high traffic caching.

# Prerequisites
Install nginx and varnish:
```sh
$ sudo apt update
$ sudo apt install varnish nginx -y
```

Check the ports used by nginx and varnish:
```sh
$ sudo netstat -tulpn | grep nginx
tcp        0      0 0.0.0.0:80          0.0.0.0:*       LISTEN      764635/nginx: maste
tcp        0      0 0.0.0.0:443         0.0.0.0:*       LISTEN      764635/nginx: maste
tcp6       0      0 :::80               :::*            LISTEN      764635/nginx: maste
tcp6       0      0 :::443              :::*            LISTEN      764635/nginx: maste

$ sudo netstat -tulpn | grep varnish
tcp        0      0 0.0.0.0:6081        0.0.0.0:*       LISTEN      715/varnishd
tcp        0      0 127.0.0.1:6082      0.0.0.0:*       LISTEN      715/varnishd
tcp6       0      0 :::6081             :::*            LISTEN      715/varnishd
tcp6       0      0 ::1:6082            :::*            LISTEN      715/varnishd
```

By default, varnish will be configured to talk to port `8080` as its default backend. Verify by checking `/etc/varnish/default.vcl`:
```sh
$ cat /etc/varnish/default.vcl
...
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
...
```
# Configure Nginx
Create `/etc/nginx/sites-available/your-website.com.conf` and add the following:
```sh
server {
    listen 80;
    listen [::]:80;
    server_name your-website.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name your-website.com;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/your-website.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-website.com/privkey.pem;

    ssl_protocols TLSv1.2;
    ssl_ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS;
    ssl_prefer_server_ciphers   on;

    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin";
    add_header X-XSS-Protection " 1; mode=block";

    location / {
      proxy_pass http://127.0.0.1:6081;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header HTTPS "on";

      access_log /var/log/nginx/your-website-access.log;
      error_log  /var/log/nginx/your-website-error.log notice;
    }
}

server {
    listen 8080;
    listen [::]:8080
    server_name your-website.com
    root /var/www/website;
    index index.html index.htm index.php
}
```
Explanation of the above configuration:
We created 3 server blocks that listen to port 80, 443 and 8080 respectively: 
* The first block redirect HTTP traffic to our HTTPS backend
* The second block direct HTTPS traffic to our Varnish cache which is listening on port `6081`. This is also known as reverse proxy where we are directing traffic from port 443 to port 6081. We also added a few headers to increase security. Note: in order to use port 443, you should have configured SSL/TLS. The above configuration assumes you have set one up using letsencrypt.
* The third block listens on port `8080`, which is called by Varnish to look up and cache our website's contents.

Enable our website configuration:
```sh
$ sudo ln -s /etc/nginx/sites-available/your-website.com.conf /etc/nginx/sites-enabled/
```

Restart nginx and varnish:
```sh
$ sudo systemctl restart nginx
$ sudo systemctl restart varnish
```

# Testing
## Cache Test
Use curl to test whether varnish is active:
```sh
$ curl -I https://your-website.com
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sat, 25 Jul 2020 17:41:01 GMT
Content-Type: text/html
Content-Length: 24349
Connection: keep-alive
Last-Modified: Sun, 19 Jul 2020 17:07:26 GMT
Vary: Accept-Encoding
X-Varnish: 184865969 184770543
Age: 6878
Via: 1.1 varnish (Varnish/6.2)
ETag: W/"5f1d-5aace6ca3b1d1-gzip"
Accept-Ranges: bytes
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin
X-XSS-Protection:  1; mode=block
```

Notice the following headers:
```sh
X-Varnish: 184865969 184770543
Age: 6878
Via: 1.1 varnish (Varnish/6.2)
```
It shows the website is being returned by Varnish cache.

## Load Test
The result of a load test with 2000 concurrent users on [https://jasonthai.me](https://jasonthai.me) can be found at [https://bit.ly/3jyxAeq](https://bit.ly/3jyxAeq)

Result of 1000 concurrent clients:
{% include lazy-img.html src="/assets/img/1000-concurrent.png" alt="1000 concurrent users" %}

Result of 2000 concurrent clients:
{% include lazy-img.html src="/assets/img/2000-concurrent.png" alt="2000 concurrent users" %}

# What's Next?
Varnish supports multiple configurations including cache purging, cache skipping and TTL for cached contents. More resources can be found on their website.

# References
[https://varnish-cache.org/docs/index.html](https://varnish-cache.org/docs/index.html)

[https://www.linode.com/docs/websites/varnish/getting-started-with-varnish-cache](https://www.linode.com/docs/websites/varnish/getting-started-with-varnish-cache)
