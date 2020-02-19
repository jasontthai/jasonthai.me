---
title: Better SSH Keys Management with AuthorizedKeysCommand
description: Use AuthorizedKeysCommand to better manage SSH keys
category: tech
---

I usually use authorized_key files to store SSH public keys in order to access my servers . However once I start to have multiple servers, I realize manually managing SSH keys is nightmare.

Recently I found out a better way to manage these SSH keys
In /etc/ssh/sshd_config file there are 2 configurations:
```
AuthorizedKeysCommand /keys.sh
AuthorizedKeysCommandUser nobody
```

We can use **AuthorizedKeysCommand** to point to an script that returns all the SSH keys. In this case, my script is:
```shell
#!/bin/bash
curl https://raw.githubusercontent.com/jasontthai/keys/master/$1
```
Name this file `key.sh` and make it executable: `chmod a+x /keys.sh`

The public keys are stored in a Github repo which can be updated any time. The structure of the repo is this:
```
keys/
├── user1
├── user2
├── user3
└── user4
```

When I login with  user1, the server will get user1's public keys from Github and validates it agaisnt user1's private key. 

There are a few problems with this approach:  I rely on an external service to retrieve the public keys. If Github goes offline, I will be unable to login to my servers at all. This also adds latency to the login step as we need to retrieve the keys over the internet. So I should think about some caching mechanism in case this happens.