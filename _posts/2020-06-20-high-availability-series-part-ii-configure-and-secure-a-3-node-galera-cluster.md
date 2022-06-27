---
title: "[Series] PART II: Configure and Secure a 3-node Galera Cluster"
description: 'High Availability Series: How to configure and secure a 3-node Galera
  cluster'
category: tech
toc: true
image: "/assets/img/galera_small.png"
tags:
  - high availibility
---

# Introduction
Second part of the series covers how to set up and secure a multi master Galera cluster consisting of 3 mariadb servers. A multi master cluster allow reads and writes from any of the nodes. Changes are replicated synchronously to the other nodes. 

We will go over how to set it up and secure the communication between the three nodes. There are 3 different vectors that we can secure through SSL: traffic between the database server and client, replication traffic within Galera Cluster, and the State Snapshot Transfer (SST). We will go over all three.

# Initial Configuration:
On every node of the cluster, add the following lines in `/etc/hosts`:
```sh
IP-of-node1 galera-01
IP-of-node2 galera-02
IP-of-node3 galera-03
```

Optional: Setting up the firewall to only allow cluster traffic communication between the three nodes with ufw. 
Galera requires a number of ports for connectivity between its nodes. Below is the list:
```
3306 is the default port for MySQL client connections and State Snapshot Transfer using mysqldump for backups.
4567 is reserved for Galera Cluster replication traffic. Multicast replication uses both TCP and UDP transport on this port.
4568 is the port for Incremental State Transfer.
4444 is used for all other State Snapshot Transfer.
```
Example of ufw configuration on node1:
```sh
$galera-01 sudo ufw allow from IP-of-node2 to any port 3306 proto tcp
$galera-01 sudo ufw allow from IP-of-node2 to any port 4444 proto tcp
$galera-01 sudo ufw allow from IP-of-node2 to any port 4567 proto tcp
$galera-01 sudo ufw allow from IP-of-node2 to any port 4568 proto tcp
$galera-01 sudo ufw allow from IP-of-node2 to any port 4567 proto udp

$galera-01 sudo ufw allow from IP-of-node3 to any port 3306 proto tcp
$galera-01 sudo ufw allow from IP-of-node3 to any port 4444 proto tcp
$galera-01 sudo ufw allow from IP-of-node3 to any port 4567 proto tcp
$galera-01 sudo ufw allow from IP-of-node3 to any port 4568 proto tcp
$galera-01 sudo ufw allow from IP-of-node3 to any port 4567 proto udp

$galera-01 sudo ufw reload
```
# Configure the first node:
Following the the first part of the series, we have covered securing the traffic between the server and the client. Now we are ready to initialize the first node of the cluster.

Create `/etc/mysql/mariadb.conf.d/galera.cnf` and add the following lines:
```sh
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# Configuration to secure traffic replication
wsrep_provider_options="socket.ssl_key=/etc/mysql/certs/server-key.pem;socket.ssl_cert=/etc/mysql/certs/server-cert.pem;socket.ssl_ca=/etc/mysql/certs/ca-cert.pem"

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://galera-01,galera-02,galera-03"

# Galera Synchronization Configuration
wsrep_sst_auth=xtra:replace-your-verify-secure-replication-password-here
wsrep_sst_method=mariabackup

# Galera Node Configuration
wsrep_node_address=galera-01
wsrep_node_name=galera-db-01

# Configuration to secure the SST connection
[sst]
encrypt=3
tcert=/etc/mysql/certs/server-cert.pem
tkey=/etc/mysql/certs/server-key.pem
```

Inititialize Galera cluster:
```sh
$galera-01 sudo systemctl stop mariadb
$galera-01 sudo galera_new_cluster
$galera-01 sudo systemctl status mariadb 
```

# Configure the second node:
Following part I of the series, we have created all the necessary certs in node 1 of the cluster. We do not have to create the certs again, simply copy the certs from the first node to the second node and place them in `/etc/mysql/certs`

Create `/etc/mysql/mariadb.conf.d/galera.cnf` and add the following lines:
```sh
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# Configuration to secure traffic replication
wsrep_provider_options="socket.ssl_key=/etc/mysql/certs/server-key.pem;socket.ssl_cert=/etc/mysql/certs/server-cert.pem;socket.ssl_ca=/etc/mysql/certs/ca-cert.pem"

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://galera-01,galera-02,galera-03"

# Galera Synchronization Configuration
wsrep_sst_auth=xtra:replace-your-verify-secure-replication-password-here
wsrep_sst_method=mariabackup

# Galera Node Configuration
wsrep_node_address=galera-02
wsrep_node_name=galera-db-02

# Configuration to secure the SST connection
[sst]
encrypt=3
tcert=/etc/mysql/certs/server-cert.pem
tkey=/etc/mysql/certs/server-key.pem
```

Restart Mariadb
```sh
$galera-02 sudo systemctl restart mariadb
```
# Configure the third node:
Again copy the certs from the first node to the third node and place them in `/etc/mysql/certs`

Create `/etc/mysql/mariadb.conf.d/galera.cnf` and add the following lines:
```sh
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# Configuration to secure traffic replication
wsrep_provider_options="socket.ssl_key=/etc/mysql/certs/server-key.pem;socket.ssl_cert=/etc/mysql/certs/server-cert.pem;socket.ssl_ca=/etc/mysql/certs/ca-cert.pem"

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://galera-01,galera-02,galera-03"

# Galera Synchronization Configuration
wsrep_sst_auth=xtra:replace-your-verify-secure-replication-password-here
wsrep_sst_method=mariabackup

# Galera Node Configuration
wsrep_node_address=galera-03
wsrep_node_name=galera-db-03

# Configuration to secure the SST connection
[sst]
encrypt=3
tcert=/etc/mysql/certs/server-cert.pem
tkey=/etc/mysql/certs/server-key.pem
```

Restart Mariadb
```sh
$galera-03 sudo systemctl restart mariadb
```

# Verify MariaDB Galera Cluster Settings
Login to MySQL console from a node in the cluster as root user.

```sh
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 122994
Server version: 10.4.13-MariaDB-1:10.4.13+maria~buster mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

Check the cluster size:
```sh
MariaDB [(none)]> SHOW STATUS LIKE 'wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
1 row in set (0.001 sec)
```

To view all status related to cluster:
```sh
MariaDB [(none)]> SHOW GLOBAL STATUS LIKE 'wsrep_%';
```
# Verify Cluster Replication
On node1:
```sh
$galera-01 sudo mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 118912
Server version: 10.4.13-MariaDB-1:10.4.13+maria~buster mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database test1;
Query OK, 1 row affected (0.033 sec)

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test1              |
+--------------------+
4 rows in set (0.410 sec)
```

On node 2 or 3:
```sh
$galera-03 sudo mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 124058
Server version: 10.4.13-MariaDB-1:10.4.13+maria~buster mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test1              |
+--------------------+
4 rows in set (0.954 sec)
```
# Verify Secure Connection Between Nodes
Check mysql logs to see connection is indeed through SSL:
```sh
$galera-01 sudo cat /var/log/mysql/error.log | grep ssl
2020-06-20 11:24:04 0 [Note] WSREP: initializing ssl context
2020-06-20 11:24:04 0 [Note] WSREP: (38f78cdc-ac66, 'ssl://0.0.0.0:4567') listening at ssl://0.0.0.0:4567
2020-06-20 11:24:04 0 [Note] WSREP: (38f78cdc-ac66, 'ssl://0.0.0.0:4567') multicast: , ttl: 1
2020-06-20 11:24:04 0 [Note] WSREP: SSL handshake successful, remote endpoint ssl://XXX:4567 local endpoint ssl://XXX:46756 cipher: TLS_AES_256_GCM_SHA384 compression: none
2020-06-20 11:24:04 0 [Note] WSREP: SSL handshake successful, remote endpoint ssl://XXX:4567 local endpoint ssl://XXX:57914 cipher: TLS_AES_256_GCM_SHA384 compression: none
2020-06-20 11:24:04 0 [Note] WSREP: SSL handshake successful, remote endpoint ssl://XXX:4567 local endpoint ssl://XXX:59148 cipher: TLS_AES_256_GCM_SHA384 compression: none
```
# Conclusion
This post guides us how to set up and secure a 3-node Galera cluster. Next post will cover setting up proxy to connect a client to multiple Mariadb nodes securely using stunnel and configure load balancer with HAProxy.

# Resources
[[High Availability Series] PART I: Set Up and Use SSL to Secure MariaDB on Debian Servers]({{ site.url }}{% post_url 2020-06-08-high-availability-series-part-i-set-up-and-secure-mariadb-on-debian-servers %})

[https://galeracluster.com/library/documentation/ssl-config.html](https://galeracluster.com/library/documentation/ssl-config.html)

[https://galeracluster.com/library/documentation/firewall-settings.html](https://galeracluster.com/library/documentation/firewall-settings.html)

[https://mariadb.com/kb/en/getting-started-with-mariadb-galera-cluster](https://mariadb.com/kb/en/getting-started-with-mariadb-galera-cluster)
