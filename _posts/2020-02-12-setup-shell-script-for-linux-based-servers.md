---
title: Setup Shell Script for Linux-based Servers
description: A script I created to quickly set up and harden Linux based servers.
category: tech
image: "/assets/img/scripts.png"
---

Since I have a few Linux servers that are running RHEL, Debian or Ubuntu OS, I want to have an automatic and convenient way to quickly set up and get them running.  Specifically I want to do a the following things for a fresh server:

* Upgrade the server's packages to the latest version
* Install essential packages such as: fail2ban, ufw, htop, apache2, docker, etc.
* Create new user with sudo access
* Disable root login and password authentication in favor of SSH keys
* Ability to install other packages if required

With that in mind, I created a simple setup script which you can find here: [https://github.com/jasontthai/shell-scripts](https://github.com/jasontthai/shell-scripts)

### Running the Script
To run the script manually with prompt so you can decide what the script does:
```
curl -L json.id/setup.sh | sudo bash
```
To run the script in automatic mode without prompt except for adding new user:
```
curl -L json.id/setup.sh | sudo bash -s -- -a
```

### Example of output
```shell
curl -sL json.id/setup.sh | sudo bash
# ## ## ## ## ## ## ## ## ## ## ## ## #
#           VPS Setup Script          #
# ## ## ## ## ## ## ## ## ## ## ## ## #

Wed 12 Feb 2020 03:56:01 PM PST
Updating system...

Installing Basic Packages: sudo ufw fail2ban htop curl apache2

Add Sudo User? [y/N]: y
Disable Root Login? [y/N]: y
Disable Password Authentication? [y/N]: y
Install Docker? [y/N]: y
Install Docker Compose? [y/N]: y
Enter your TIMEZONE [Empty to skip]:
Enter any other packages to be installed [Empty to skip]:

Setting sudo user...
Username: testuser
Password:

Adding SSH Keys
Enter SSH Key [Empty to skip]:

Disabling Root Login...

Disabling Password Authentication...

Docker Installed. Added testuser to docker group

Docker Compose Installed.

Finished setup script.
```

or to view help
```shell
curl -sL json.id/setup.sh | sudo bash -s -- -h
# ## ## ## ## ## ## ## ## ## ## ## ## #
#           VPS Setup Script          #
# ## ## ## ## ## ## ## ## ## ## ## ## #

Wed 12 Feb 2020 04:04:07 PM PST

Usage: ./setup.sh [-mh]
       curl -sL json.id/setup.sh | sudo bash
       curl -sL json.id/setup.sh | sudo bash -s --{ah}

Flags:
       -a : run setup script automatically
       -h : prints this lovely message, then exits
```
