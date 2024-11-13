{%

setvar("layout",theme .. ".html")
title = "Antoine's blog"

table.sort(posts, orderPosts)

%}


# Latest posts and projects

{% for i in ipairs(posts) do %}
<a href="{{ posts[i].url }}">
<div class='card'>
		<h3 class='title'>
		{{ posts[i].title }}
		</h3>
		<div class="time">{{ timeToDate(posts[i].created_at) }}</div>
		<p>
		{{ posts[i].description }}
		</p>
		<div class="time">
		About {{ math.ceil(posts[i].word_count / 200) }} minutes to read
		</div>
</div>
</a>
{% end %}

<!-- 100% privacy-first analytics -->
<script async defer src="https://scripts.simpleanalyticscdn.com/latest.js"></script>
<noscript><img src="https://queue.simpleanalyticscdn.com/noscript.gif" alt="" referrerpolicy="no-referrer-when-downgrade" /></noscript>