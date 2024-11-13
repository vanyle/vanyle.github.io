{%

setvar("outfile","output/feed")

-- Make posts 1-indexed
posts[#posts] = posts[0]
posts[0] = nil

table.sort(posts, orderPosts)

%}

<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">

<channel>

<title>Antoine's blog</title>
  <link>https://vanyle.github.io</link>
  <description>A blog about tech, cooking and random interesting things</description>
{% for i in pairs(posts) do %}
  <item>
    <title>{{ posts[i].title }}</title>
    <link>https://vanyle.github.io/{{ posts[i].url }}</link>
    <description>{{ posts[i].description }}</description>
    <pubDate>{{ posts[i].last_modified }}</pubDate>
  </item>

{% end %}

</channel>
</rss>