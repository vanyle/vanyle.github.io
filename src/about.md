{%
setvar("layout",theme .. ".html")
add_pic = false
%}

# About me

Hi. I'm Antoine Delègue. Some guy on the internet that likes to make cool HTML animation as well as other fun programming projects.

I'm interested in math, programming, science, cooking, squishmallows and everything that looks even remotely neat.

I put here stuff that I noticed or just nano projects I made in a few hours that look interesting and that can inspire
you to try out new ideas.

If you're really bored and you've already played around with all the stuff on this website, I suggest you checkout my non-HTML projects on my [GitHub](https://github.com/vanyle)

You can reach my on [LinkedIn](https://www.linkedin.com/in/d-antoine/).

You can also contact me at the following email (just run the code below in a python interpreter):

{%
-- The input string was generated using:
-- s = ".".join([chr(c+1) for c in base64.b64encode(bytes(e,'utf8'))])
-- Where e is my mail.
%}

```python
s = "[.H.W.t.[.X.e.2.[.T.6.i.c.o.S.w.b.X.6.m.R.H.e.u.Z.X.m.t.M.n.O.w.c.R.>.>"
import base64; print(base64.b64decode(bytearray([ord(i)-1 for i in s.split(".")])).decode("utf8"))
```
