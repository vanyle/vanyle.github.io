{%
setvar("outfile","output/feed")
table.sort(posts, orderPosts)

%}

<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/">

<channel>
  <title>Antoine's blog</title>
  <docs>https://validator.w3.org/feed/docs/rss2.html</docs>
  <link>https://vanyle.github.io</link>
  <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
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
