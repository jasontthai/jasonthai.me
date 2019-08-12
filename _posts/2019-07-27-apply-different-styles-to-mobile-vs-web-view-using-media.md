---
title: Apply Different Styles to Mobile vs Web View Using @media
category: Tech
image: "/assets/img/responsive-media-queries.webp"
toc: true
description: a brief walkthrough of how to use @media queries to apply styles to mobile and web view
---

This note goes over how I render the mobile and web view of my site differently to optimize user experience on different screen sizes with the use of `@media`  queries.
<!--more-->
First let's examine how it looks on web vs mobile:

## Web View:
This view is designed to be viewed on devices with larger screen like laptops or desktops and it includes more information such as the cover image and description of the post.

{% include lazy-img.html src="/assets/img/jasonthai-web-view.webp" at="web view" %}
 

## Mobile View:
The view on mobile is optimized a lot more for information browsing. The image and description are eliminated in favor of more number of articles in the view. This makes viewing on mobile devices faster too since the browser does not have to load any images.

{% include lazy-img.html src="/assets/img/jasonthai-mobile-view.webp" at="mobile view" %}

## How to: using @media
Using `@media` query, we can define specific css behavior depending on certain width or height of the screen. You can learn more about it [here](https://www.w3schools.com/cssref/css3_pr_mediaquery.asp)

For example, the following query will apply to device with screen width up to 480px
```css
@media screen and (max-width: 480px) {
  // define css here
}
```

For my specific site, this is what I define:
```css
@media screen and (max-width: 600px) {
  .bg-img {
    display: none;   // hiding the cover image
  }

  .excerpt p {
    display: none;  // hiding the description
  }
}
```

## Conclusion
Using @media is a simple way to apply specific styles to different media/screens. I believe there are other ways to do it too such as grid or flex view. I am going to take a look at those a different time.