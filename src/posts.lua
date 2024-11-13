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

function orderPosts(a, b)
    v1 = reverseDate(timeToDate(a.created_at))
    v2 = reverseDate(timeToDate(b.created_at))
    return v1 > v2
end
