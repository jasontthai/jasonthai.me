---
title: Using jekyll-last-modified-at on Cloudflare Pages
category: tech
---

I ran into the problem where `jekyll-last-modified-at` plugin did not work properly on Cloudflare pages. Luckily, I found the solution via [Github issue](https://github.com/gjtorikian/jekyll-last-modified-at/issues/69#issuecomment-1638574705). 

The fix for this issue is to update the `Build command` to be 
```git fetch --unshallow && bundle exec jekyll build```.

Also a quick update: I'm testing hosting running this site on a VPS instead of Cloudflare. Let's see how it affects the uptime.

