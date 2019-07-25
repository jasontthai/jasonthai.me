---
title: My Blog's PageSpeed Insights Score
featured_img: /assets/img/pagespeed-featured.png
tags: tech
toc: true
---

![PageSpeed Insights](/assets/img/pagespeed-full.png)

## Introduction

I have been testing how responsive my blog is and PageSpeed Insights give me a pretty good idea of the result. Certainly there are always improvements to be made but for now I am quite glad that the site is snappy.

<!--more-->
[Check my blog's PageSpeed Insights Score](https://developers.google.com/speed/pagespeed/insights/?url=https%3A%2F%2Fjasonthai.me%2F&tab=desktop)

I also tried out [Lighthouse](https://developers.google.com/web/tools/lighthouse), an open source tool to audit my site's performance. The result is [here](/assets/js/jasonthai.me-20190725T135457.json) in json or you can download the file and use [Lighthouse Report Viewer](https://googlechrome.github.io/lighthouse/viewer/) for the graphical view.

## Things I have done to improve speed

### Leverage [Cloudflare](https://cloudflare.com) for its SSL and CDN service
Cloudflare CDN ensures that my site is highly available and fast. Its SSL service also ensures your connection to my site is secure.

### Load scripts asynchronously
Since scripts by default will block the rendering of the page, I use `async` attribute to have them load asynchronously

### Less use of style and scripts
The more scripts and styles a page has, the slower it becomes. I try not to overload the site with these things

### Smaller images
I always try to resize and optimize the images so they take less time to load and render.

## Conclusion
To be clear, I do not think having a high score means the website is awesome. It also has to do with other factors like quality of content. That said, user experience is very important and we should not make the users wait to view our content.