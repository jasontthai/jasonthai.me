---
title: Link Color Switcher
description: I added some customization to the site.
category: blog
tags:
  - design
---

Recently, I added support for dark modes to this blog as a long-overdue item. Keeping up the momentum, I want to add a new feature that would allow me or you to have some fun with customizing the link colors dynamically. Instead of the default color, there are now a few more options to choose from. You can test it out by trying the buttons in the footer. They may look something like this:

<div style="display: flex; align-items: center;">
  Themes:
  <button id="default" class="tb" style="background-color: var(--default-color);" onclick="o(this)"></button>
  <button id="red" class="tb" style="background-color: var(--red-color);" onclick="o(this)"></button>
  <button id="yellow" class="tb" style="background-color: var(--yellow-color);" onclick="o(this)"></button>
  <button id="green" class="tb" style="background-color: var(--green-color);" onclick="o(this)"></button>
  <button id="blue" class="tb" style="background-color: var(--blue-color);" onclick="o(this)"></button>
  <button id="indigo" class="tb" style="background-color: var(--indigo-color);" onclick="o(this)"></button>
  <button id="purple" class="tb" style="background-color: var(--purple-color);" onclick="o(this)"></button>
</div>

I borrow a few designs from my current work project so if you are aware of what I'm working on, this will look very familiar. If you are not, well I'm working on [supporting the RGB Keyboards on ChromeOS](https://chromeunboxed.com/chromeos-keyboard-backlight-personalization-hub).

The idea is pretty simple. I've manually defined a couple of CSS variables like so:

```sh
 :root {
  --link-color: #1d4ed8;
  --link-text-color: #FFF;
  --default-color: #1d4ed8;
  --red-color: #F28B82;
  --yellow-color: #FDD663;
  --green-color: #81C995;
  --blue-color: #78D9EC;
  --indigo-color: #8AB4F8;
  --purple-color: #C58AF9;
}
```

I also added some scripts that handle on click events for the theme buttons, and saving or retrieving the user's preference in local storage:
```sh
<script>
  const t = localStorage.getItem('theme') ? localStorage.getItem('theme') : 'default';
  if (t) {
    u(t);
  }
  window.matchMedia('(prefers-color-scheme: dark)').addListener(function (e) {
    const t = localStorage.getItem('theme') ? localStorage.getItem('theme') : 'default';
    u(t);
  });
  function f() {
    const t = localStorage.getItem('theme') ? localStorage.getItem('theme') : 'default';
    const buttons = document.querySelectorAll('.tb');
    buttons.forEach((button) => {
      if (button.getAttribute('id') === t) {
        button.style.setProperty('transform', 'scale(1.5)');
      } else {
        button.style.removeProperty('transform');
      }
    });
  }
  f();
  function c(color) {
    const r = document.querySelector(':root');
    const rs = getComputedStyle(r);
    const hex = rs.getPropertyValue(`--${color}-color`) || rs.getPropertyValue(`--default-color`);
    return hex;
  }
  function u(color) {
    const r = document.querySelector(':root');
    const hex = c(color);
    r.style.setProperty('--link-color', hex);
  }
  function o(d) {
    const color = d.getAttribute("id");
    u(color);

    localStorage.setItem('theme', color);
    f();
  }
</script>
```

I ran into an issue with the link color flickering between the default and new colors due to the script executing after the page loads. This was resolved by moving the appropriate functions to `<head>`. Another issue is that the button doesn't highlight properly, which is also addressed by keeping parts of the scripts in the `<footer>`.

The changes added about 2kb to the site but I think it's worth making this site a bit more fun. I also have a TODO to add a rainbow theme, so stay tuned.