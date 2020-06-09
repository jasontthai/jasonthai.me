---
title: "[High Availability Series] PART I: Set Up and Use SSL to Secure MariaDB on
  Debian Servers"
description: 'High Availability Series: How to set up and use SSL to secure MariaDB
  on Debian servers.'
category: tech
toc: true
image: "/assets/img/galera_small.png"
---

# Introduction
First part of the series covers how to set up and secure MariaDB.
> MariaDB is a community-developed, commercially supported fork of the MySQL relational database management system, intended to remain free and open-source software under the GNU General Public License
[https://en.wikipedia.org/wiki/MariaDB](https://en.wikipedia.org/wiki/MariaDB)

The series will guide through how to set up a Galera cluster with 3 nodes, secure connection between them, and finally set up HAProxy as a load balancer to the webservers where each webserver talks to a particular MariaDB instance on the same server. This purpose is to have a highly available and endurable system which is expected to run continuously without failure for a long time. This only covers horizontal scaling of different nodes. Vertical scaling may be covered in the future.

# Set up MariaDB
Install MariaDB packages:
```sh
$galera-01 sudo apt-get install mariadb-server mariadb-backup
```

Run the security script:
```sh
$galera-01 sudo mysql_secure_installation
```

{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] Y
New password:
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] Y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```
{% endcapture %}{% include details.html %} 
# Set up SSL for MariaDB
## Create CA Certificate
Make a directory named certs in /etc/mysql/ directory using the mkdir command:
```sh
$galera-01 cd /etc/mysql
$galera-01 sudo mkdir certs
$galera-01 cd certs
```

Note: Common Name value used for the server and client certificates/keys must each differ from the Common Name value used for the CA certificate. To avoid any issues, set it as follows:
* CA common Name : MariaDB admin
* Server common Name: MariaDB server
* Client common Name: MariaDB client

Type the following command to create a new CA key:
```sh
$galera-01 sudo openssl genrsa 2048 > ca-key.pem
```
OR
```sh
$galera-01 sudo openssl genrsa 4096 > ca-key.pem
```

{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
Generating RSA private key, 2048 bit long modulus (2 primes)
.......+++++
..............................................................+++++
e is 65537 (0x010001)
```
{% endcapture %}{% include details.html %} 

Type the following command to generate the certificate using that key:
```sh
$galera-01 sudo openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem
```

{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:MariaDB admin
Email Address []:
```
{% endcapture %}{% include details.html %} 

Now there should be two files as follows:
```sh
$galera-01 ls /etc/mysql/certs
ca-cert.pem – Certificate file for the Certificate Authority (CA).
ca-key.pem – Key file for the Certificate Authority (CA).
```
Let's use both files to generate the server and client certificates.
## Create the server SSL certificate
To create the server key, run:
```sh
$galera-01 sudo openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server-key.pem -out server-req.pem
```

{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
Generating a RSA private key
.........................................................................................................................................+++++
...........................................................+++++
writing new private key to 'server-key.pem'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:MariaDB server
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```
{% endcapture %}{% include details.html %} 

Next process the server RSA key, enter:
```sh
$galera-01 sudo openssl rsa -in server-key.pem -out server-key.pem
```

{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
writing RSA key
```
{% endcapture %}{% include details.html %} 



Finally sign the server certificate, run:
```sh
$galera-01 sudo openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
```

{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
Signature ok
subject=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = MariaDB server
Getting CA Private Key
```
{% endcapture %}{% include details.html %} 

Now you should have these two additional files:
```sh
/etc/mysql/certs/server-cert.pem – MariaDB server certificate file.
/etc/mysql/certs/server-key.pem – MariaDB server key file.
```
## Create the client TLS/SSL certificate
To create the client key, run:
```sh
$galera-01 sudo openssl req -newkey rsa:2048 -days 365000 -nodes -keyout client-key.pem -out client-req.pem
```
{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
Generating a RSA private key
.......................................+++++
...............+++++
writing new private key to 'client-key.pem'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:Mariadb client
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```
{% endcapture %}{% include details.html %} 

Next, process client RSA key, enter:
```sh
$galera-01 sudo openssl rsa -in client-key.pem -out client-key.pem
```
{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
writing RSA key
```
{% endcapture %}{% include details.html %} 
Finally, sign the client certificate, run:
```sh
$galera-01 sudo openssl x509 -req -in client-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
```
{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
Signature ok
subject=/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=MariaDB client
Getting CA Private Key
```
{% endcapture %}{% include details.html %}
## Verify the certificates
Type the following command to verify the certificates to make sure everything was created correctly:
```sh
$galera-01 openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem
```
{% capture summary %}Sample output:{% endcapture %}  
{% capture details %}  
```sh
server-cert.pem: OK
client-cert.pem: OK
```
{% endcapture %}{% include details.html %}
## Configure SSL for MariaDB Server
Edit `/etc/mysql/mariadb.conf.d/50-server.cnf` and add the following lines in [mysqld] section:
```sh
ssl-ca=/etc/mysql/certs/ca-cert.pem
ssl-cert=/etc/mysql/certs/server-cert.pem
ssl-key=/etc/mysql/certs/server-key.pem
bind-address            = *      
```

Give permission to mysql so it can read the certs properly:
```sh
$galera-01 sudo chown -Rv mysql:root /etc/mysql/certs/

changed ownership of '/etc/mysql/certs/server-key.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/client-req.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/server-req.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/ca-key.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/server-cert.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/client-cert.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/ca-cert.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/client-key.pem' from root:root to mysql:root
changed ownership of '/etc/mysql/certs/' from root:root to mysql:root
```

Then, restart MariaDB service to apply the changes:

```sh
$galera-01 sudo systemctl restart mysql
```
Next, log in to MariaDB shell and check SSL variable:

```sh
$galera-01 sudo mysql -u root -p
```
Enter your root password, then run the following command:

```sh
MariaDB [(none)]> SHOW VARIABLES LIKE '%ssl%';
```

You will see that SSL variables are now enabled:
```sh
+---------------------+----------------------------------+
| Variable_name       | Value                            |
+---------------------+----------------------------------+
| have_openssl        | NO                               |
| have_ssl            | YES                              |
| ssl_ca              | /etc/mysql/certs/ca-cert.pem     |
| ssl_capath          |                                  |
| ssl_cert            | /etc/mysql/certs/server-cert.pem |
| ssl_cipher          |                                  |
| ssl_crl             |                                  |
| ssl_crlpath         |                                  |
| ssl_key             | /etc/mysql/certs/server-key.pem  |
| version_ssl_library | YaSSL 2.4.4                      |
+---------------------+----------------------------------+
10 rows in set (0.001 sec)
```
## Configure SSL for MariaDB Client
Edit `/etc/mysql/mariadb.conf.d/50-client.cnf` and add the following lines in [client] section:
```sh
ssl-ca=/etc/mysql/certs/ca-cert.pem
ssl-cert=/etc/mysql/certs/client-cert.pem
ssl-key=/etc/mysql/certs/client-key.pem
```
## Verify Secure Connection
Log in to MariaDB shell:
```sh
$galera-01 sudo mysql -u root -p
```

Now, check the status of connection with the following command:
```sh
MariaDB [mysql]> status
```

Detail about secure connection should be displayed like so:
```sh
--------------
mysql  Ver 15.1 Distrib 10.3.22-MariaDB, for debian-linux-gnu (x86_64) using readline 5.2

Connection id:		282
Current database:
Current user:		root@localhost
SSL:			Cipher in use is DHE-RSA-AES256-SHA
Current pager:		stdout
Using outfile:		''
Using delimiter:	;
Server:			MariaDB
Server version:		10.3.22-MariaDB-0+deb10u1 Debian 10
Protocol version:	10
Connection:		Localhost via UNIX socket
Server characterset:	utf8mb4
Db     characterset:	utf8mb4
Client characterset:	utf8mb4
Conn.  characterset:	utf8mb4
UNIX socket:		/var/run/mysqld/mysqld.sock
Uptime:			7 hours 27 min 20 sec

Threads: 10  Questions: 31302  Slow queries: 0  Opens: 159  Flush tables: 1  Open tables: 63  Queries per second avg: 1.166
--------------
```
# Conclusion
This post guides us how to set up a MariaDB server and secure connection between the server and its clients. Next post will cover setting up the Galera cluster.

# Resources
[https://mariadb.com/kb/en/secure-connections-overview](https://mariadb.com/kb/en/secure-connections-overview)

[https://mariadb.com/kb/en/securing-connections-for-client-and-server](https://mariadb.com/kb/en/securing-connections-for-client-and-server)
