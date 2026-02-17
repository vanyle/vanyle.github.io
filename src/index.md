{%
add_pic = false
setvar("layout", theme .. ".html")
posts_table = {}
for p in posts() do
	table.insert(posts_table, p)
end

table.sort(posts_table, orderPosts)
page_title = "Facteer Blog"
%}


<div class='card intro'>
	<p>Hey! You there, reading this, welcome to my blog! 🎉</p>
	<p>I'm Antoine, I <s>rarely</s> sometimes post articles
	about programming, making games, or just general throughts.</p>
	<p>I try to present things that are rarely talked about
	online, provide a fresh perspective on topics or write concise explainers.</p>
</div>

{% for i in ipairs(posts_table) do %}
<a href="{{ posts_table[i].url }}">

<div class='card post'>
			<h3 class='title'>
			{{ posts_table[i].title }}
			</h3>
		<div class="time">{{ timeToDate(posts_table[i].created_at) }}</div>
		<p>
		{{ posts_table[i].description }}
		</p>
		<div class="time">
		About {{ math.ceil(posts_table[i].word_count / 200) }} minutes to read
		</div>
</div>
</a>
{% end %}

