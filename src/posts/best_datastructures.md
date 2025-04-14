{%
add_pic = true
setvar("layout",theme .. ".html")
%}

<script defer src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/languages/nim.min.js"></script>


# Top 5 of the best data structures

Number 2 might surprise you!

[data structure](https://en.wikipedia.org/wiki/Data_structure) are ways for a computer to represent a bunch of data. There
are a lot of different data structure that have different purposes.
I will present 5 data structures that I find cool because of their properties
or just because they might not be well know (so no hash tables or double linked list here!)

They are sorted in a semi-random order to give some tension to the article.

## Number 5 - Ropes

While ropes are not the most useful structure (unless you're building a text editor), they're pretty neat and can
inspire you to find new data structure when faced with a new problem, hence their number 5 spot.

Ropes are a binary tree-like data structure where the leaves contain strings and the length of strings.
The branches of the tree contain the total length of the subtree.

Using this property, if you know the position of a cursor in a string, you can insert new strings
at arbitrary position in the tree in O(log(n)) time as you just need to update the lengths along the way.

Same does for deletion of elements. Access of a character at an index is also O(log(n)).
String concatenation is done in constant time, however as you just need to concatenate the two trees.

You just need to rebalance the tree in O(n) from time to time to ensure that the depth stays about O(log(n)),
which might not always remain true is you keep inserting strings in poor spots.

All in all, if you need a data structure that represents an ordered set of elements with fast insertion and deletion
at any index, a rope is the structure for you!

What? You want an implementation example?

I'm really too lazy to write one, but the Nim standard library has a neat rope implementation that you can checkout.

[Documentation](https://nim-lang.org/docs/ropes.html)

[Implemementation](https://github.com/nim-lang/Nim/blob/version-1-6/lib/pure/ropes.nim)

Don't be scared by Nim, it's just sparkling python with some type annotations.

How to access item at character i:

```nim

type
  Rope* {.acyclic.} = ref object
    left, right: Rope
    length: int
    data: string # not empty if a leaf

proc `[]`*(r: Rope, i: int): char
  var x = r
  var j = i
  if x == nil or i < 0 or i >= r.len: return
  while true:
    if x != nil and x.data.len > 0:
      return x.data[j] # leaf reached
    else: # explore left or right side
      if x.left.length > j:
        x = x.left
      else:
        j -= x.left.length
        x = x.right
```

Note that this implementation didn't bother having arbitrary position insertion.

## Number 4 - Octotrees

*Remember binary trees? What if we made them bigger?*

Octotrees are trees where every node has eight children. They are used to solve problems involving geometry and 3d space, mainly when you need to iterate over all the elements that are "close" to another element quickly.

In order to list nearby elements of a given node, you just need to check the 27 cubic areas that contain the element and the ones around him.

This makes the complexity linear in the number of nearby elements. Even if you have a lot of elements in your 3d space, you don't need to check all of them to identify close elements.

The only issue with the structure is that there is added complexity when moving elements around. You need to change which node contains a given element when crossing some space boundaries.

This makes it a O(log(n)) operation in the worst case but it's still fine in general.

The size of the subdivision of the tree depends on your octotree implementation. You can go for constant size areas if you know that your elements are evenly distributed or you can build octotrees where there are more subdivisions at spots with more stuff.

The latter are more efficient for enumerating neighbors as you have fewer elements to consider in dense areas, but have a larger overhead when trying to move elements around as you have to rebuild branches of the tree instead of just moving the places of the elements.

I love octotrees because of how useful they are to build various simulations. For particle simulation, they are crucial if you want to be able to detect collisions between stuff as it's not feasible iterating over all pairs of particles to detect interactions when you have a large (>1000) of them.

They are typically used to answer questions where objects have positions and there is a relevant idea of proximity between the objects. For example, when finding the closest pair of points in a 3d space (or the closest pair of stars with a quad tree).

## Number 3 - Disjointed Sets

Disjointed sets are a structure that represents grouping of elements. They are mainly known because of their use for computing connected components of graphs.

It's a structure that does not represent data itself but relations between data.

Let's say you have a graph and want to find it's connected components.

You start by storing every node in a structure like this:

```nim

type DisjointedSet* {.acyclic.} = ref object
	parent: DisjointedSet
	size: int
	rank: int

proc makeSet(): DisjointedSet =
	result.parent = nil
	result.size = 1
	result.rank = 0

proc Hash(x: DisjointedSet): DisjointedSet =
	if x.parent == nil: return x
	x.parent = Hash(x.parent)
	return x.parent

proc Merge(a: DisjointedSet, b: DisjointedSet): DisjointedSet =
	let root_a = a.Hash()
	let root_b = b.Hash()
	# In practice, pick the root with the lowest rank
	# to minimize tree depth
	# So, you might flip root_a and root_b here based on ranks 
	root_a.parent = root_b
	if root_a.rank == root_b.rank:
		root_a.rank += 1
```

The idea is that parent stores a reference to another element of the set in order to form a chain that points to a final element (which is final because it points to `nil`).

To check that how elements are in the same set, you check that they have the same parent element. What makes this structure clever is that as you go through the chain to find the root, you can replace the `parent` field so that subsequent calls are performed in constant time.

## Number 2 - Functions

What functions? Functions are not a data structure! I already hear you say.
Well, not in every language, but in languages were functions are first-class (i.e you can use them as arguments of other functions),
functions can store data and thus behave as data structures.

Consider the following example:

```js

function makeStruct(){
	let a = 0;
	let b = 0;
	function struct(field, mode, value){
		if(field == "a" && mode) return a;
		if(field == "b" && mode) return b;
		if(field == "a") a = value;
		if(field == "b") b = value;
	}
	return struct;
}

```

Well, `makeStruct` returns a struct like object with 2 fields that you can read and write!

What I really like about functions and what put them so high in this list is that they can be used
to build a number of other data structure.

Consider this implementation of linked lists:

```js

let makeList = () => (() => {}); 
let append = (lst, element) => (m) => {
	if(m) return lst;
	return element;
};

let head = (lst) => lst(false);
let tail = (lst) => lst(true);

```

Now, consider this implementation of binary trees:

```js

let makeNode = (n) => n; // a node is just a value
let makeTree = (left,right) => (m) => {
	if(m == "left") return left;
	if(m == "right") return right;
}
let right = (t) => t("right")
let left = (t) => t("left")
```

And if we have binary trees and linked lists, we can build all sorts of other structures such as dictionaries (with O(log(n)) lookup times), double linked lists, octotrees, etc...

Because an idea as simple as a function can do so many things, I believe functions earned their spot as number 2 in this list.

Note however, that you cannot build a classic variable size array with constant lookup time using this technique. Arrays can, however be simulated with trees and you can still have an O(log(n)) access time which is pretty reasonable.

This is because searching data at a specific index is an operation that cannot be implemented with the primitives available (function declarations, function calls, if, for and while loops). Only ifs can be used to operate on our data in constant time, so we need to lookup data indexed by integer-like object by passing these integers through a series of if-based tests, hence the logarithmic time.

## Number 1 - Segment Trees

Segment trees are my favorite data structure. When I first heard of them, I was surprised such a thing existed. And they make a lot of competitive programming problems trivial.

You can read and edit them in logarithmic time like arrays and build them in linear time.

Segment trees can quickly (in logarithmic time) perform associative operations on data ranges (including sums, multiplications, finding a max, gcd, etc...).

They take up not a lot more space than a regular array (4 times the space).

I have a simple (also written in Nim) implementation of Segment trees with decent documentation.

[Implementation](https://github.com/vanyle/RangeQueriesNim/blob/master/src/rangequeries.nim)

[Documentation](https://vanyle.github.io/RangeQueriesNim/rangequeries.html)

The idea is that you can store your data as a binary tree (with leaves containing the values of the segment tree) and by storing at every node the result of the associative operation on all the children.

Because the operation is associative, if you need to compute it over a range, you just select the branches that correspond to parts of the range you are interested in and apply the operation on these. You will need to consider at most a logarithmic number of nodes.

As you know, \\\[1 + 2 + 4 + 8 + ... + 2^k = 2^{k+1}-1 \\\] where k is the smallest value such that \\\[ 2^{k+1} > n \\\] (n is the total number of elements stored in the structure). So, the segment tree has a memory footprint that is linear in n as every level of the tree contains double the amount of the previous level.

When modifying an element however, you'll need to recompute the values of the branches above it hence the logarithmic time for element modification.

Why are segment trees so awesome?
Well, go try [CSES problem](https://cses.fi/problemset/task/1143) and come back afterwards !

Tip: Consider `min` as the associative operation.

If your operation is bijective and its inverse can be computed in constant time, you can even modify whole ranges of values in log time !

To do this, instead of storing the values of elements as leaves, you can consider that the whole path of nodes taken to reach an element are values that you have to operate together to get the value of the element at the bottom.

Using this representation, you can just modify an element in a branch the change the result of everything below quickly.
However, if you have the ability to quickly modify a range, you lose the ability to quickly apply the operation over a range and get the result, so you need to choose between these two.