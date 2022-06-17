---
title: My Blog's PageSpeed Insights Score
image: /assets/img/pagespeed-featured.png
category: tech
toc: true
description: A note of how to achieve high score on PageSpeed Insights
---

![PageSpeed Insights](/assets/img/pagespeed-full.png)

## Introduction

I have been testing how responsive my blog is and PageSpeed Insights give me a pretty good idea of the result. Certainly there are always improvements to be made but for now I am quite glad that the site is snappy.

<!--more-->
[Check my blog's PageSpeed Insights Score](https://developers.google.com/speed/pagespeed/insights/?url=https%3A%2F%2Fjasonthai.me%2F&tab=desktop)

I also tried out [Lighthouse](https://developers.google.com/web/tools/lighthouse), an open source tool to audit my site's performance. The result is [here](/assets/js/jasonthai.me-20190726T112605.json) in json or you can download the file and use [Lighthouse Report Viewer](https://googlechrome.github.io/lighthouse/viewer/) for the graphical view.

Some other tools to test your site are [Pingdom](https://tools.pingdom.com) and [GTmetrix](https://gtmetrix.com/)

## Things I have done to improve speed

### Leverage [Cloudflare](https://cloudflare.com) for its SSL and CDN service
Cloudflare CDN ensures that my site is highly available and fast. Its SSL service also ensures your connection to my site is secure.

### Load scripts asynchronously
Since scripts by default will block the rendering of the page, I use `async` attribute to have them loaded asynchronously.

### Less use of style and scripts
The more scripts and styles a page has, the slower it becomes. I try not to overload the site with these things. 

I also include CSS and javascripts directly on the page if they are small to reduce HTTP calls to fetch them.

### Lazyload images and webp format
I optimize the images by converting them to [webp format](https://developers.google.com/speed/webp/) and using [lazyloading](https://github.com/aFarkas/lazysizes)  so they take less time to load and render.

## Conclusion
To be clear, I do not think having a high score means the website is awesome. It also has to do with other factors like quality of content. That said, user experience is very important and we should not make the users wait to view our content.