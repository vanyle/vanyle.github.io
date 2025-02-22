{%
setvar("layout", theme .. ".html")
table.sort(posts, orderPosts)
%}

<style>
@import url('https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap');
.card.post:hover{
    /*animation: wiggle 0.5s infinite;*/
    transform: scale(1.01);
}
.card.post:active{
    transform: scale(0.99);
}
.card p{
	font-size: 20px;
	font-family: "Roboto", "Arial", sans-serif;
	line-height: 1.5;
	margin: 0;
}
.card.intro p{
	padding: 0;
}
</style>

<div class='card intro'>
	<p>Hey! You there, reading this, welcome to my blog! 🎉</p>
	<p>I'm Antoine, I <s>rarely</s> sometimes post articles
	about programming, making games, or just general throughts.</p>
	<p>I try to present things that are rarely talked about
	online, provide a fresh perspective on topics or write concise explainers.</p>
</div>

{% for i in ipairs(posts) do %}
<a href="{{ posts[i].url }}">

<div class='card post'>
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

{% if production ~= nil then %}

<!-- 100% privacy-first analytics -->
<script async defer src="https://scripts.simpleanalyticscdn.com/latest.js"></script>

<noscript><img src="https://queue.simpleanalyticscdn.com/noscript.gif" alt="" referrerpolicy="no-referrer-when-downgrade" /></noscript>
{% end %}
