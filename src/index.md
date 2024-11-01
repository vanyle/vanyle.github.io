{%

setvar("layout",theme .. ".html")
title = "Antoine's blog"

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


# Latest posts and projects


{% for i in pairs(posts) do %}
<a href="{{ posts[i].url }}">
<div class='card'>
		<h3 class='title'>
		{{ posts[i].title }}
		</h3>
		<div class="time">{{ timeToDate(posts[i].last_modified) }}</div>
		<p>
		{{ posts[i].description }}
		</p>
		<div class="time">
		About {{ math.ceil(posts[i].word_count / 200) }} minutes to read
		</div>
</div>
</a>
{% end %}
