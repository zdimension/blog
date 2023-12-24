---
# the default layout is 'page'
# current page is 'projects' so appropriate icons would be fas fa-project-diagram or fas fa-folder-open
icon: fas fa-project-diagram
order: 4
---

<div id="project-list" class="flex-grow-1 px-xl-1">
    {% for post in posts %}
        {% if post.categories contains 'Projects' %}
            {{ post.title }}
        {% endif %}
    {% endfor %}
</div>