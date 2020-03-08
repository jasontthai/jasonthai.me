---
title: Deploy Nextcloud With Docker Compose in Ubuntu 18.04
description: How to deploy Nextcloud with Docker Compose in Ubuntu 18.04
category: tech
toc: true
image: "/assets/img/NextcloudLogo.png"
---

In one of the previous posts, I mentioned using [Nextcloud](https://nextcloud.com/) as a self-hosted cloud platform. This post goes into details how I set up my instance.

## Install Docker and Docker-Compose
To install docker, run:
```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

To install docker-compose, run:
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
## docker-compose.yml
Create this `docker-compose.yml` with following contents:
```yaml
version: '3'

services:
  db:
    image: mariadb
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    restart: always
    volumes:
      - /opt/nextcloud-db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=ENTER MYSQL PASSWORD
      - MYSQL_PASSWORD=ENTER MYSQL PASSWORD
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
  redis:
    image: redis:alpine
    restart: always
  app:
    image: nextcloud:apache
    ports:
      - 8080:80
    environment:
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis
    volumes:
      - /opt/nextcloud-data:/var/www/html
    restart: always
  cron:
    image: nextcloud:apache
    restart: always
    volumes:
      - /opt/nextcloud-data:/var/www/html
    entrypoint: /cron.sh
    depends_on:
      - db
      - redis
```

Run `docker-compose -f docker-compose.yml up -d` to start all necessary containers.

## Setting Up

Browse to `http://localhost:8080` and you'll see a set up page like this:

{% include lazy-img.html src="/assets/img/nextcloud-setup.png" alt="Setup" %}

Fill in the fills as the following:
* Database user: nextcloud
* Database password: Enter your password in `docker-compose.yml` file
* Database name: nextcloud
* Database host: db

After setting up nextcloud, you will see something like:

{% include lazy-img.html src="/assets/img/nextcloud.jpeg" alt="Nextcloud" %}

## Modify Overwrite Protocal
Modify `/opt/nextcloud-data/config/config.php` and add:
```conf
'overwriteprotocol' => 'https',
```

## Modify Upload Max Filesize
By default, Nextcloud only allows uploading file up to 2MB which is not very useful. We can modify the max filesize by adding `/opt/nextcloud-data/.htaccess` with following:
```conf
<IfModule mod_php7.c>
...
php_value upload_max_filesize 16G
php_value post_max_size 16G
</IfModule>
```