{%
setvar("outfile","output/feed")

posts_table = {}
for p in posts() do
	table.insert(posts_table, p)
end

table.sort(posts_table, orderPosts)

%}

<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/">

<channel>
  <title>Antoine's blog</title>
  <docs>https://validator.w3.org/feed/docs/rss2.html</docs>
  <generator>ASG</generator>
  <link>https://vanyle.github.io</link>
  <description>A blog about tech, cooking and random interesting things</description>
  {% for i in ipairs(posts_table) do %}
    <item>
      <title>{{ posts_table[i].title }}</title>
      <link>https://vanyle.github.io/{{ posts_table[i].url }}</link>
      <description>{{ posts_table[i].description }}</description>
      <guid>https://vanyle.github.io/{{ posts_table[i].url }}</guid>
      <pubDate>{{ to_rfc2822_date(posts_table[i].last_modified) }}</pubDate>
    </item>
  {% end %}
</channel>
</rss>
