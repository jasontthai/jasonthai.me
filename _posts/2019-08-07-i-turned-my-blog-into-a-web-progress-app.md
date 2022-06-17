---
title: I Turned My Blog into a Progressive Web App
category: tech
description: A note of how I turn my blog into a progressive web app
image: "/assets/img/pwa-logo.png"
---

I recently create a post of [how to enable offline support to websites with Workbox]({{ site.url }}{% post_url 2019-08-06-enable-offline-support-to-websites-with-workbox %}) and turns out it already covers half of the work of turning my blog into a progressive web app (PWA). This note will cover the rest to fully convert a regular website to a PWA.
<!--more-->

The first thing is to check what is needed to be done in order to be a PWA. We can do that by using Google Chrome's developer tools' audit.

![Dev Tool Audits](/assets/img/devtool-audits.png)

Give it a run, and see who well your website is doing.

Now let's dive in the steps to turn my blog to a PWA.

## Prerequisites:
Make sure have completed registering the worker service. Details are covered in the post I mentioned above.

## Create manifest.json
The [Web App Manifest](https://developer.mozilla.org/en-US/docs/Web/Manifest) is a JSON file designed to describe a Web Application. Below is what I declared for my site:
```json
{
  "short_name": "Jason's Notes",
  "name": "Jason's Notes",
  "icons": [
    {
      "src": "/assets/img/android-chrome-192x192.png",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "/assets/img/android-chrome-512x512.png",
      "type": "image/png",
      "sizes": "512x512"
    }
  ],
  "start_url": "index.html",
  "background_color": "#fdfdfd",
  "display": "standalone",
  "scope": "/",
  "theme_color": "#faf5ef"
}
```
Above are the minimum fields you should declare for your manifest. Make sure you fill all of them.

## Add meta tags:
I also added the required meta tags for a PWA:
```html
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="manifest" href="/manifest.json">
<link rel="apple-touch-icon" href="/assets/img/apple-touch-icon.png">
<meta name="theme-color" content="#faf5ef" />
```

## Verify through Audits
If you have completed all the above steps, verify using the audits tool again and hopefully you'll be greeted with this screen:
![PWA](/assets/img/pwa.png)

## More ways to verify
* If you open the menu on chrome browser, you'll see the option to install your pwa as an app on your desktop.
* View the site on browser and you can be asked to add this site as an app.

## Conclusion
Using PWA, we ensure our site is viewable no matter what network condition is. I hope you'll be able to turn your site to a PWA to improve your visitors' experience.