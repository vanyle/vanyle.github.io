production = true -- don't forget this toggle!
theme = "themes/modern"

if production == nil then
	setvar("livereload", "true")
	setvar("port", "8080")
end

-- utils functions

function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

function reverse(lst)
	rev = {}
	for i = #lst, 1, -1 do
		rev[#rev + 1] = lst[i]
	end
	return rev
end

function reverseDate(d)
	return table.concat(reverse(split(d, "/")), "")
end

function keys(tab)
	local keyset={}
	local n=0

	for k,v in pairs(tab) do
		n=n+1
		keyset[n]=k
	end
	return keyset
end

function to_string(tab)
	return table.concat(tab, ", ")
end

function orderPosts(a, b)
	v1 = reverseDate(timeToDate(a.created_at))
	v2 = reverseDate(timeToDate(b.created_at))
	return tonumber(v1) > tonumber(v2)
end
