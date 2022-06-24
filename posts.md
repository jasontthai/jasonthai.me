---
layout: page
title: Archives
---

<h3>
Other ways to browse:
</h3>
<ul class="p-0">
    <li class="flex p-0">
        <a href="/categories/">By categories</a>
    </li>
    <li class="flex p-0">
        <a href="/tags/">By tags</a>
    </li>
</ul>

{% assign postsByYearMonth = site.posts | group_by_exp:"post", "post.date | date: '%Y %B'"  %}
{% for yearMonth in postsByYearMonth %}
<h3>
    {{ yearMonth.name }}
</h3>
<ul class="p-0">
    {% for post in yearMonth.items %}
    <li class="flex p-0">
        <a href="{{ post.url }}">
            {{ post.title }}
        </a>
    </li>
    {% endfor %}
</ul>
{% endfor %}
