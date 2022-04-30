---
title: Connect to Localhost MySQL from Docker Container
description: How to connect to localhost mysql from docker container.
category: tech
image: "/assets/img/homepage-docker-logo.png"
toc: true
---

## Make sure MySQL accepts connection
Look for the appropriate `[mysqld]` config .e.g. `/etc/mysql/mariadb.conf.d/50-server.cnf`

Update these following options:
```
#skip-networking
bind-address            = *
```

## Whitelist firewall for docker0 bridge
```
sudo ufw allow in on docker0 to any port 3306
sudo ufw reload
```

Note the IP of docker0 proto on the webserver node:
```sh
$ ip r | grep docker0
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
```
The value is usually `172.17.0.1`

## Example of Wallabag docker-compose.yml

```
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
      #SYMFONY__ENV__DATABASE_HOST value is IP of docker0. 
      - SYMFONY__ENV__DATABASE_HOST=172.17.0.1
      - SYMFONY__ENV__DATABASE_PORT=3306
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
      - 8070:80
    volumes:
      - /opt/wallabag/images:/var/www/wallabag/web/assets/images
    restart: always
    # Make sure network_mode is bridge to connect to localhost via bridge.
    network_mode: bridge
```
