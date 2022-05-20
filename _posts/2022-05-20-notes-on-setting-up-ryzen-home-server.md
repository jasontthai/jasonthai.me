---
title: Notes on Setting Up Ryzen Home Server
category: tech
description: Setting up Debian on Beelink SER3
image: "/assets/img/beelink.jpg"
---

I've just got a [Beelink SER3 AMD Ryzen™ 7 3750H](https://www.amazon.com/gp/product/B09HJQN9RH/) and decided to replace Windows 11 Pro with Debian linux OS. The set up was mostly fine except a few hiccups that I documented below:

* The wifi adapter didn't work. Beelink seems to have Intel based wifi chipset and it didn't come by default with Debian. I need to fallback to using the good old ethernet cable during the OS installation. To get the firmware, we can do this:

```sh
$ sudo nano /etc/apt/sources.list

...
deb http://deb.debian.org/debian/ buster main contrib non-free
deb http://deb.debian.org/debian/ buster main contrib non-free
...
```

Also run these after saving the changes.

```sh
$ sudo apt update
$ sudo apt install firmware-iwlwifi
```

* I also need to install the AMD GPU firmware as (you guessed it) it didn't come with Debian either. To do so:

```
$ git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
$ sudo mkdir /lib/firmware/amdgpu
$ sudo cp linux-firmware/amdgpu/* /lib/firmware/amdgpu/ && sudo update-initramfs -k all -u -v
```

Now it should be in a good state.
