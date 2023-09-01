---
title: Nextcloud Restore Attempt
category: tech
tags:
- backup
- restore
toc: true
---

I have my own instance of Nextcloud running on docker at home and have been using [borgmatic](https://torsion.org/borgmatic/) to back up this service for a while now. Yesterday, I attempted my occasional disaster recovery routine and ran into some surprises. Below is a recap of what happened.

# Borgmatic Config
If you are not familiar with Borgmatic, it's a configuration-file driven wrapper for [BorgBackup](https://www.borgbackup.org/). Think of it as docker-compose with respect to docker. A snippet of my configuration:

```
$ cat /etc/borgmatic/config.yaml

location:
    # List of source directories to backup.
    source_directories:
        - /root
        - /home
        - /var/www/
        - /etc/borgmatic/
        - /etc/nginx/

    one_file_system: true

    # Paths of local or remote repositories to backup to.
    repositories:
        - /mnt/backup/home-server.borg

retention:
    # Retention policy for how many backups to keep.
    keep_daily: 4
    keep_weekly: 2
    keep_monthly: 1

consistency:
    # List of checks to run to validate your backups.
    checks:
        - name: repository
          frequency: 2 weeks
        - name: archives
          frequency: 2 weeks
storage:
    encryption_passphrase:
hooks:
    # Custom preparation scripts to run.
    before_backup:
        - ~/pre_backup.sh
    after_backup:
        - ~/post_backup.sh
```

Before backing up, `pre_backup.sh` is executed, preparing all the containers for backup state .i.e. spinning down the container, or putting it in maintenance mode. After backing up, `post_backup.sh` takes care of starting them again.

## Backup
Borgmatic is run daily through cron:
```
crontab -l
20 1 * * * /root/.local/bin/borgmatic --stats --verbosity 1 --syslog-verbosity 1
```

## Restore
Use borgmatic to mount the previous backup:
```
borgmatic mount --repository /mnt/backup/home-server.borg --mount-point /tmp/backup

ls /tmp/backup
home-server-2023-07-31T01:20:39.771648  home-server-2023-08-27T01:20:37.551086  home-server-2023-08-29T01:20:35.602216  home-server-2023-08-31T09:35:21.040004
home-server-2023-08-20T01:20:46.226830  home-server-2023-08-28T01:20:41.478482  home-server-2023-08-30T01:20:55.037651  home-server-2023-09-01T14:06:54.389790
```

# Nextcloud Scripts (Old)
The backup scripts for my Nextcloud instance are rudimentary:
```
$ cat /docker/nextcloud/pre_backup.sh
#!/bin/bash

echo 'Backing up nextcloud db'
/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --on
/usr/local/bin/docker-compose exec -T db mysqldump --single-transaction -u nextcloud -p nextcloud > nextcloud.bck

$ cat /docker/nextcloud/post_backup.sh
#!/bin/bash

/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --off
echo 'Backing up nextcloud db. Done'

$ cat /docker/nextcloud/restore.sh
#!/bin/bash

echo 'Restoring nextcloud db'
#/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --on
/usr/local/bin/docker-compose exec -T db mysql -u nextcloud -p nextcloud < nextcloud.bck
#/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --off
echo 'Restoring nextcloud db. Done'
``` 

# Surprises

When I attempted to restore, I got an error:
```
OCI runtime exec failed: exec failed: unable to start container process: exec: "mysqldump": executable file not found in $PATH: unknown
```
This is the content of `nextcloud.bck` dump that got generated from the script.

How did this happen? Starting in `11.0.1`, MariaDB docker image no longer ships `mysqldump`[<sup>1</sup>](#ref-1). Since I'm always using the latest version of MariaDB in my docker config, I missed this breaking change when I upgraded my docker images. This means all the previous backups were useless because the database dumps weren't valid.

To fix this issue, I had to update the script and replace `mysqldump` with `mariadb-dump`. Running `pre_backup.sh` now generates the correct database dump.

Continuing with restoring results in yet another failure:
```
OCI runtime exec failed: exec failed: unable to start container process: exec: "mysql": executable file not found in $PATH: unknown
```
This time, the `restore.sh` script fails because `mysql` is also no longer shipped in the MariaDB image. So I also need to replace `mysql` with `mariadb` command.

# Nextcloud Scripts (New)
```
$ cat /docker/nextcloud/pre_backup.sh
#!/bin/bash

echo 'Backing up nextcloud db'
/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --on
/usr/local/bin/docker-compose exec -T db mariadb-dump --single-transaction -u nextcloud -p nextcloud > nextcloud.bck

$ cat /docker/nextcloud/post_backup.sh
#!/bin/bash

/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --off
echo 'Backing up nextcloud db. Done'

$ cat /docker/nextcloud/restore.sh
#!/bin/bash

echo 'Restoring nextcloud db'
#/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --on
/usr/local/bin/docker-compose exec -T db mariadb -u nextcloud -p nextcloud < nextcloud.bck
#/usr/local/bin/docker-compose exec -T --user www-data app php occ maintenance:mode --off
echo 'Restoring nextcloud db. Done'
```

# Conclusion
Having a backup is essential, but it is also important to do a routine restore to make sure everything works as planned. This is a skill worth practicing.

----
1. {: #ref-1} [https://mariadb.com/kb/en/mysqldump/](https://mariadb.com/kb/en/mysqldump/)