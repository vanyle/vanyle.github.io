{%
setvar("layout",theme .. ".html")
%}

## Search for a post

<style>
	input[type=text]#search{
		border: none;
		outline: none;
		border-bottom: 3px solid #36f;
		padding: 5px;
		margin: 5px;
		font-size: 1.2em;
	}
</style>
<input id="search" placeholder="Search" type="text"/>
<div id="results"></div>

<script>
	let posts = [
	{% for i in pairs(posts) do %}
		{
			title: `{{ posts[i].title }}`,
			url: `{{ string.gsub(posts[i].url,"\\","/") }}`,
			description: `{{ posts[i].description }}`
		},
	{% end %}
	];

	search.onkeyup = () => {
		let query = search.value;
		let s = [];
		if(query === ""){
			results.innerHTML = "";
			return;
		}
		for(let i = 0;i < posts.length;i++){
			if(
				posts[i].title.toLowerCase().indexOf(query) !== -1 ||
				posts[i].description.toLowerCase().indexOf(query) !== -1
			){
				s.push(`
					<a href="${posts[i].url}">
					<div class='card'>
						<h3 class='title'>${posts[i].title}</h3>
						<p>
							${posts[i].description}
						</p>
					</div>
					</a>
				`)
			}
		}
		results.innerHTML = s.join("");
	}
</script>

<!-- 100% privacy-first analytics -->
<script async defer src="https://scripts.simpleanalyticscdn.com/latest.js"></script>
<noscript><img src="https://queue.simpleanalyticscdn.com/noscript.gif" alt="" referrerpolicy="no-referrer-when-downgrade" /></noscript>