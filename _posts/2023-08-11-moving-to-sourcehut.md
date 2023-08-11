---
title: Moving to Sourcehut
category: blog
tags:
- cicd
- sourcehut
description: Site is now powered by Sourcehut page
---

For quite a while, this site has been posted on Cloudflare Pages (before that it was on Github Page). I don't really have any complaint about it as the uptime is great (perfect 100%).

I found out [Sourcehut](https://srht.site/) not long ago and the dedication for open source just clicks with me. This is why I decided to support the ecosystem by using their ecosystem to host the blog. I also found out how to move one git repo to another from [a stackoverflow post](https://stackoverflow.com/questions/1365541/how-to-move-some-files-from-one-git-repo-to-another-not-a-clone-preserving-hi). There is some clean up to do such as removing the config file for CircleCI as Sourcehut has their own build system, and hosting some CSS and JS files locally to respect [Sourcehut limitations](https://srht.site/limitations). The process is straightforward and not anger-inducing, which is nice.

I'm going to monitor the uptime of the page for some time to see whether it lives up to my expectation. Bye now.
