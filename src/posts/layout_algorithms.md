{%
setvar("layout",theme .. ".html")
add_pic = true
%}
<script defer src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/languages/nim.min.js"></script>

# Layout Algorithms
*A story about shuffling rectangles around*

I'm currently writing a game engine in Nim.
To test the game engine, I'm also making a small game on the side to test all of the features.
This is because I find writing engine more fun than actually making games.

I know, I'm weird, get used to it.

At some point, I realized that I needed a way to build guis for the menu of my game.
I already had [imgui](https://github.com/ocornut/imgui) installed as a dependency, but imgui is not really made for
production guis (even though it can be used as so), as it can be hard to customize and
most interfaces made with imgui have an imgui vibe (like [Telemetry from Rad Game Tools](http://www.radgametools.com/telemetry.htm) for example)

Moreover, imgui introduced complexities in the building process as it forced me to use the C++ backend.

So, the planets had aligned for me to write a custom GUI library inside my engine.
However, I felt like if I was going to write a GUI renderer, I might as well include an HTML-like renderer,
so that guis are easy to write and customize.

First, I designed a small set of tags that will be used for my XML.

```xml
<body></body> <!-- positions the gui relative to the screen -->
<view></view> <!-- div -->
<text></text> <!-- render text -->
<button></button> <!-- self descriptive -->
```

Then, I thought of the minimal amount of properties needed to customize the tags while still being able to do all
kind of layouts.
As I'm working in React Native, I took inspiration from their system where every `div` is has the flex property.

The result looks like this as the syntax.

```xml
<!-- Example -->
<view padding="0.05" backgroundColor="#eeeeee" borderWidth="0.005" borderColor="black">
	<view alignSelf="center">
		<text size="0.15" font="retrofont">Settings</text>
	</view>
	
	<view height="0.1" width="0.01"></view>	
	
	<view alignSelf="start" padding="0.02">
		<button
			alignSelf="start"
			backgroundColor="blue"
			padding="0.01"
			borderWidth="0.005"
			direction="row"
			borderColor="black">
			<text color="white">Toggle [placeholder]</text>
		</button>
		<view height="0.05" width="0.01"></view>
		<button 
			id="fullscreen_button"
			alignSelf="start"
			backgroundColor="green"
			direction="row"
			padding="0.01"
			borderWidth="0.005"
			borderColor="black">
			<text color="white">Toggle Fullscreen</text>
		</button>
		<view height="0.05" width="0.01"></view>
		<button
			id="back_button"
			alignSelf="start"
			backgroundColor="black"
			direction="row"
			padding="0.01"
			borderWidth="0.005"
			borderColor="black">
			<text color="white">Go Back</text>
		</button>
		<view height="0.05" width="0.01"></view>
	</view>
</view>
</body>

```

Now that we have a specification, we need to render it !
We first convert the XML to an abstract render tree (like an AST, but for the graphics people)
This is done using the xml parsing library provided by Nim and is straighforward, most of the code
being error checking to make sure the user does not include text outside a text tag for example.

Then, we need to convert this tree into a bunch of nested boxes. This is the meat of the layout algorithm.
This can be done in linear time by passing twice through the tree.
The first time, width and height of every element are computed using the following logic:

- If we are dealing with text, the size of the box is the size required by the text (+ padding)
- If we have a view/button/body:
	- If the direction is row
		width <- sum of width of children + padding and border
		height <- max of height of children + padding and border
	- If the direction is column (the default)
		width <- max of width of children + padding and border
		height <- sum of height of children + padding and border
- If the width/height property are defined, they override the previous rules

This is not the exact algorithm, just an explanation. The padding needs to be counted twice for the left and right sides of the boxes.
Implementing left and right padding can easily be done, but I didn't do it as it can be easily simulated using Spacer elements
and I wanted to keep the code simple.

Now that everything is sized, we can compute the position of everybody !
This can also be done by walking though the tree once.

Where as the size of the children changes the size of the parent, for the position, it's the opposite:
The position of the parent changes the position of the children.

The algorithm for the position is more complicated as we handle the row/column case but also the various alignments
cases that flex provides, just as center, flex-start and flex-end, totaling six cases in the code.

The body element is special as its position is relative to the screen and not the parent.

All in all, the code for centering is pretty simple:

```nim
proc recomputePosition(
        cmp: Component,
        parent: Component,
        offsetX: float32,
        offsetY: float32,
        deltaParentX: float32 = 0,
        deltaParentY: float32 = 0) =
    ## Apply the centering in the direction opposite to the layout of the parent
    ## This is like applying the justify-content property in CSS.
    ## We assume that the children are already correctly positionned on the other axis.

    var startOffsetX = cmp.cachedOffsetX
    var startOffsetY = cmp.cachedOffsetY

    if parent.layoutDirection:
        # ROW, Center on the Y axis
        if cmp.alignSelf == AlignmentEnum.Center:
            cmp.cachedOffsetY = (parent.cachedOffsetY - parent.cachedHeight / 2 + cmp.cachedHeight / 2)
        elif cmp.alignSelf == AlignmentEnum.Start:
            cmp.cachedOffsetY = parent.cachedOffsetY - parent.padding

        cmp.cachedOffsetX += deltaParentX 
    else:
        # COL, Center on X axis
        if cmp.alignSelf == AlignmentEnum.Center:
            cmp.cachedOffsetX = (parent.cachedOffsetX + parent.cachedWidth / 2 - cmp.cachedWidth / 2)
        elif cmp.alignSelf == AlignmentEnum.Start:
            cmp.cachedOffsetX = parent.cachedOffsetX + parent.padding

        cmp.cachedOffsetY += deltaParentY

    for c in cmp.children:
        recomputePosition(
            c,
            cmp,
            cmp.cachedOffsetX,
            cmp.cachedOffsetY,
            cmp.cachedOffsetX - startOffsetX,
            cmp.cachedOffsetY - startOffsetY
        )
```

And using these simple building blocks, we can quickly obtained very pretty GUIs.
And remove imgui from our dependences!

Of course, a lot of features are lacking in the example above:
- Scrolling
- Text inputs
- More widgets

But the core is there and can easily be expanded.