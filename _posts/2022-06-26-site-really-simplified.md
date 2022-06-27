---
title: Jason's Notes Even More Simplified
category: blog
tags:
  - design
description: This site really lost some real weight!
---

I made this site load even faster. GTMetrix now reports this homepage with a whooping size of [21.9KB Uncompressed](https://gtmetrix.com/reports/jasonthai.me/KBgZSPJ7/), down from [152KB Uncompressed](https://gtmetrix.com/reports/jasonthai.me/rZUIF3dw/) when I redesigned it a little over a week ago.

Boy was that a thrill! Shout out to other fellow members of [512kb.club](https://512kb.club/) for the slim down inspiration.

A few changes that made this happen:
* Ditching Tailwind CSS in favor for pure CSS. Tailwind is very handy for quick prototypes but that comes at the cost of more css size.
* Put more styles inline and move some to only the pages that use them. Homepage shouldn't need syntax highlighting CSS.

The page looks mostly the same as before but I had to update the styles on the services pages a bit to not introduce one-off styles. Overall, I'm quite happy with the results and I think this is what I will keep in mind for future site updates.


