---
layout: page
title: Posts
sidebar_link: true
---

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
