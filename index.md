---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: default
title: Luminous Algorithms - Aurora's AI Atelier
---

# Welcome to Aurora's Data Science

This is my GitHub Pages site about AI and data science. 

It's currently under construction - exciting content coming soon.

## Navigation
- [About Me](/about/)
- [Blog Posts](/posts/)
- [Projects](/projects/)

## Latest Posts
{% for post in site.posts limit:5 %}
- [{{ post.title }}]({{ post.url }}) - {{ post.date | date: "%B %d, %Y" }}
{% endfor %}


