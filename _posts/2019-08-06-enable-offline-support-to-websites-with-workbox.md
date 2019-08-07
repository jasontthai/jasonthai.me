---
title: Enable Offline Support to Websites with Workbox
description: A note of what Workbox is and how to use it to enable offline access
  for websites
tags: tech
toc: true
image: "/assets/img/workbox.webp"
---

{% include lazy-img.html src="/assets/img/workbox.webp" alt="workbox" %}

Recently I have added offline support for this blog using [Workbox](https://developers.google.com/web/tools/workbox/). You can test this by going offline and then browsing my blog. This note gives a walkthrough of how I did it and summarizes my findings.
<!--more-->

## TLDR
Steps to enable offline support:
* Create sw.js with
```javascript
importScripts('https://storage.googleapis.com/workbox-cdn/releases/4.3.1/workbox-sw.js');
workbox.precaching.precacheAndRoute([]);
```
* Install workbox-cli with `npm install workbox-cli --global`
* Follow workbox wizard `workbox wizard --injectManifest`
* Inject `sw.js` with what to cache `workbox injectManifest workbox-config.js`

## What is Workbox?
Workbox is a set of javascript libraries that add support for caching and offline access of web apps. Workbox provides an abstract layer for developers when working with [service workers](https://developers.google.com/web/fundamentals/primers/service-workers/). Some of the things workbox support like precaching, runtime caching, etc will be covered below.

## Enable service worker
Add this script to the bottom of your website:
```html
<script>
// Check that service workers are supported
if ('serviceWorker' in navigator) {
  // Use the window load event to keep the page load performant
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js');
  });
}
</script>
```
This tells the browser to wait until the window load and then register for service worker  in `/sw.js` route.

## Using Workbox
There are a few ways to generate service workers using Workbox. I choose to use workbox-cli as I can enable it as part of my build pipeline for my blog which is currently powered by Jekyll. If you use Node or Gulp, you can use [workbox-build](https://developers.google.com/web/tools/workbox/guides/precache-files/workbox-build) or if you use Webpack, there is [workbox-webpack-plugin](https://developers.google.com/web/tools/workbox/guides/precache-files/webpack).

### Install workbox-cli
Install by using npm:

`npm install workbox-cli --global`

### Setup service worker
In `sw.js` specify the following boilerplate code:
```javascript
importScripts('https://storage.googleapis.com/workbox-cdn/releases/4.3.1/workbox-sw.js');
workbox.precaching.precacheAndRoute([]) 
```
Notice we have not specified anything yet to precache. This serves as an injection point for workbox to compute and inject all the routes to be cached. 

### Use workbox-cli to populate what to precache
Run workbox-cli wizard

```javascript
workbox wizard --injectManifest
```
This command provides the option to specify what to cache by looking at all the file extensions in the website. After this is done, a new file called `workbox-config.js` will be created.

```javascript
workbox injectManifest workbox-config.js
```
This command then uses what is specified in `workbox-config.js` and injects all the files to be cached into the injection point we specified above in `sw.js` files.

### Manually specify what to cache during runtime
There are already a few [common recipes](https://developers.google.com/web/tools/workbox/guides/common-recipes) that provide examples of caching css, js, images, etc.

[I use a few from those recipes for my site]({{ "/sw.js" | absolute_url }}):
```javascript
// Caching Images
workbox.routing.registerRoute(
  /\.(?:png|gif|jpg|jpeg|webp|svg)$/,
  new workbox.strategies.CacheFirst({
    cacheName: 'images',
    plugins: [
      new workbox.expiration.Plugin({
        maxEntries: 60,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 Days
      }),
    ],
  })
);

// Cache CSS and JavaScript Files
workbox.routing.registerRoute(
  /\.(?:js|css)$/,
  new workbox.strategies.StaleWhileRevalidate({
    cacheName: 'static-resources',
  })
);

// Caching Content from Multiple Origins
workbox.routing.registerRoute(
  /.*(?:googleapis|gstatic)\.com/,
  new workbox.strategies.StaleWhileRevalidate(),
);
```

## Add to build and automate
[Since I am using CircleCI to deploy changes of my site to Github Pages]({% post_url 2019-07-22-how-to-deploy-a-github-page-using-circleci-20-custom-jekyll-gems %}), I also add the workbox + service worker script generation to the build. 

Declared `workbox-config.js`:
```javascript
module.exports = {
  "globDirectory": "_site/",
  "globPatterns": [
    "**/*.{html,txt,css,webp,js,json,svg,ico}"
  ],
  "swDest": "_site/sw.js",
  "swSrc": "sw.js"
};
```


In `config.yml` file I added:
{% raw %}
```yaml
      # -- more omitted --
      - run: JEKYLL_ENV=production bundle exec jekyll build
      - run: npm install workbox-cli
      - run: npx workbox injectManifest workbox-config.js
      # -- more omitted --
```
{% endraw %}

It is quite simple, just added two extra steps to install workbox-cli and run the same command to inject the precache routes.

## Consideration
* Using the workbox-cli, we can cache everything on the site. However, this will not work if the website contains thousands of posts and images as everything will be downloaded to the browser cache.
* Using the workbox-cli, we can only set service workers to cache our website's assets. It will not handle caching other website's sites. This is important because we probably use things like external fonts, javascripts, css files, etc. So we need to manually add that support to our service workers.