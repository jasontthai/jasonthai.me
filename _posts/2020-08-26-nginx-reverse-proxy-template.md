---
title: Nginx Reverse Proxy Template
description: Nginx reverse proxy template
image: "/assets/img/nginx.png"
category: tech
---

My go to template for using reverse proxy in Nginx (replace `domain.tld` with actual domain and  port `3000` with the port number): 

```conf
server {
    listen 80;
    listen [::]:80;

    server_name domain.tld;

    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name domain.tld;

    ssl_certificate /etc/letsencrypt/live/domain.tld/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/domain.tld/privkey.pem;

    ssl_protocols TLSv1.2;
    ssl_ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS;
    ssl_prefer_server_ciphers   on;

    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Content-Type-Options nosniff;

    location / {
      proxy_pass http://127.0.0.1:3000;
      proxy_set_header Host $http_host;
      proxy_set_header X-Forwarded-Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header HTTPS "on";

      access_log /var/log/nginx/domain.tld-access.log;
      error_log  /var/log/nginx/domain.tld-error.log notice;
    }
}
```
