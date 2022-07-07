---
title: I bought a new domain
description: What to do with jt0.dev?
category: blog
tags: [domain]
---

I purchased a new domain today [https://jt0.dev/](https://jt0.dev/) and now I am wondering what to do with it. It is a bit backward because I should have planned for it first but oh well, the domain is short and contains my intials.

My list of domains are growing:
* [json.id](https://json.id)
* [jasonthai.me](https://jasonthai.me)
* [jt0.dev](https://jt0.dev)

In other news, I learned how to retrieve a page size today using curl. Here's an example:

```sh
# No compression
curl https://jasonthai.me -w '%{size_download}' -so /dev/null
7821%

# With compression
curl --compressed https://jasonthai.me -w '%{size_download}' -so /dev/null
3209%
```

I also replaced the favicon with an image of a tree! And it is smaller in size too!