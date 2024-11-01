production = false -- don't forget this toggle!
theme = "light"

if production == nil then
	setvar("livereload", "true")
	setvar("port", "8080")
end
