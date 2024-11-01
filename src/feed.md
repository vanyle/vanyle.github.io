{%

setvar("outfile","output/feed")

function split (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
function reverse(lst)
	rev = {}
	for i=#lst, 1, -1 do
		rev[#rev+1] = lst[i]
	end
	return rev
end

function reverseDate(d)
	return table.concat(reverse(split(d,"/")), "")
end

function order(a,b)
	v1 = reverseDate(timeToDate(a.last_modified))
	v2 = reverseDate(timeToDate(b.last_modified))
	return v1 > v2
end

-- Make posts 1-indexed
posts[#posts] = posts[0]
posts[0] = nil

table.sort(posts, order)

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