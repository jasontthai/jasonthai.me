---
layout: page
title: Archives
---

You can also view by [categories](/categories) or [tags](/tags).

{% assign postsByYearMonth = site.posts | group_by_exp:"post", "post.date | date: '%Y %B'"  %}
{% for yearMonth in postsByYearMonth %}
### {{ yearMonth.name }}
<ul>
    {% for post in yearMonth.items %}
    <li>
        <a href="{{ post.url }}">
            {{ post.title }}
        </a>
    </li>
    {% endfor %}
</ul>
{% endfor %}
