{%
setvar("layout",theme .. ".html")

posts_table = {}
for p in posts() do
	table.insert(posts_table, p)
end

%}

<style>
	input[type=text]#search{
		border: none;
		border-radius: 8px;
		outline: none;
		display: block;
		width: 100%;
		padding: 8px 16px;
		font-size: 24px;
		font-family: "Oswald", sans-serif;
		margin-bottom: 16px;
	}
	.posts{
		background-color: transparent;
		box-shadow: none;
	}
</style>
<input id="search" placeholder="Search for a post" type="text"/>
<div id="results"></div>

<script>
	let posts = [
	{% for i in ipairs(posts_table) do %}
		{
			title: `{{ posts_table[i].title }}`,
			url: `{{ string.gsub(posts_table[i].url,"\\","/") }}`,
			description: `{{ posts_table[i].description }}`
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
