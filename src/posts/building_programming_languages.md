{%
setvar("layout",theme .. ".html")
%}

# Building a programming language

If you want to build your own programming language and have no idea where to start, there is this cool website / book
that explains every step of the process titled [Crafting Interpreters](https://craftinginterpreters.com/)

However, you might probably already have some idea of where to start. Or you just don't want to
follow a rigid step by step guide for your project and just want to get started with a few keywords and ideas.

Well, I'm here to help!

## But first, why do this

1. Incredible learning experience on how computers work
2. Cool project to show off
3. You can implement the language features of your dream
4. A fun challenge
5. You'll be asked to do this in ComSci in college anyway so might as well do it now to get ahead.

## General infos

But, you might say "you're just some random internet dude, what autority do you have on making programming languages?"
Well, I made one in a week (it took 2 days if you don't would the time taken to make the LR parser). [You can find it here](https://github.com/vanyle/lrparser) (inside the `tests`
directory of my parsing library)


Ok, so most programming languages you know use the following steps to turn a text file into something executable.

1. Tokenizing (also named Lexing)
2. Parsing (aka building the Abstract Syntax Tree)
3. Interpreting / Generating bytecode

## The tokenization step

Initially, you start by reading the source file provided by the user and you end up with a big string.
You need to cut this big string into small chunks called "tokens". A token is the equivalent of a word in
a human language. Tokens are short and common. Examples of tokens include: "=", "+", "var_name", "class", "<="

## The parser

You then need to assemble these tokens together in a tree like structure that reflects their meaning.
For example, the expression "1 + 4 \* 2" could be assembled to the tree:

(1,+,(4,\*,2))

in order to reflect the priority of operation. This is a complicated step if you want to do it quickly.
You need to look ahead of your tokens to match bits that have high priority together to progressively assemble your tree.

## Interpreting

Once you have built your abstract syntax tree, you can do whatever you like with it! You can generate bytecode, optimize it,
convert the code to another programming language or interpret it.

To interpret the language, you usually just perform a simple depth first parcours of the tree, recursively evaluating everything
as you go. You might during evaluation keep a table to store the current variables associated with a given scope.

## A few more tips

With the outline described above and some (a lot) of googling, you should be able to create a barebones programmoing language using a few weeks and a lot of motivation.
However, I'd also like to share some concrete tips that might help you in your journey. 

**Don't try to optimize everything at the start.**

In particular, don't try to support streams of bytes for your parser and lexer.
While this is possible, it adds a big overhead, a larger risk of bugs and it's not very fun.
Moreover, it's not common to parse files as large as your RAM, so this is rarely an issue in practive (but don't get me wrong, if you want to build a production-ready language, you'll have to do it at some point) 

Just read the whole source file, store it in a buffer and work on that buffer.

**Read some theory on parser theory**

Read [the wikipedia page](https://en.wikipedia.org/wiki/LR_parser) on LR, SLR, LALR and PEG parsers. It helps to understand their innerworkings to be inspired to build one in
order to get the sweet sweet \\\[ O(n) \\\] AST building time.

**Don't implement too many features at first**

Ever feature of the language will take some time to write. Numbers, strings, functions, arrays, etc... all of this will cause you to lose motivation if you can't test them right away.

That's why it'd recommend first building a barebones language, with only arithmetic expressions and maybe functions and then progressively add more types and features. 

**Write tests**

Programming languages are some of the most test-friendly projects ever. Your tests are just a series of source files and you just need to check that the program prints what it should print.

Testing allows you to quickly check that you did not introduce some bug while working on a feature, it gives you benchmarks if you want to optimize your language for speed, and it helps you having a good understanding of the syntax of your language at all times.

## Original stuff that you can do with a custom language

Once you have everything running, you can start having fun by implementing original features.
Because you have access to the syntax tree of your language, you can perform all kind of static analysis.

I'll describe some neat ideas that you can try out once you have built the tree.

### Proving termination
*Remember the halting problem? Well remember no more, we got just what you need!*

As you might know, proving that a function stops is [impossible in general](https://en.wikipedia.org/wiki/Halting_problem). However, there are classes of programs for which we can prove whever or not they finish.

This is useful as most functions that never stops are not correct (unless if intended, like servers or desktop apps).

One class of function that always stop are [Primitive recursive functions](https://en.wikipedia.org/wiki/Primitive_recursive_function), however, only having PRF is quite limiting for most functions.

There is another way of proving that a function always stops: You rewrite it as a recursive function by removing all loops (which is always possible) as check that during every function call, the arguments given to the function get smaller in some sense.

For example, if the function takes a list as a parameter and every recursive call of the function, the list given as argument gets shorter, and if the list is empty, the function stops then the function always stops.

You can generalize this idea to detect if a function stops as described in [this paper](https://www.researchgate.net/publication/220545855_On_Proving_the_Termination_of_Algorithms_by_Machine)

To simplify, for every common type in your language, you create a canonical order (for example, the usual < order for integer) or the size of the element for lists.
Then, when analyzing a recursive function, you check every [lexicographic ordering](https://en.wikipedia.org/wiki/Lexicographic_order) that can be built by permutating the arguments of the function.
If the recursive call follows that order, you can use it to build a proof of termination of your function.

Using this, your language can automatically tag function that terminate and the ones that might not and can give you useful insights into your program.

You can make your termination detection system more powerful by defining more orderings on your types (for example, a divides b is an ordering over the positive integers and the polynoms)


### Proving correctness
*Like Rust but more annoying*

Proving that a program stops is cool, but proving that a program is correct is cooler. That's the idea that helped create [Rust](https://www.rust-lang.org/).

You can do similar things inside your language to prove things about your program!

Using static analysis technics, you have detect in what sets the variables you have can be and using this, you can detect things like Out of Bounds arrays access or divisions by zero.

You can find [more info here](https://en.wikipedia.org/wiki/Formal_specification)

### Optimization that's a bit too smart
*Insert (n+1)n/2 clang optimization*

The more you understand a program, the more you can cleverly optimize it.
Take the following example:

```js

function fibo(n){
	if(n == 0) return 0;
	if(n == 1) return 1;
	return fibo(n-1) + fibo(n-2);
}

```

It's clear that the complexity of the function is crap for what it does. A simple analysis can show that the function is pure and that the result can be cached in order to achieve an \\\[ O(n) \\\].

```js

let c = {0:0,1:1};
function fibo(n){
	if(n in c) return c[n];
	c[n-1] = fibo(n-1);
	c[n-2] = fibo(n-2);
	return c[n-1] + c[n-2];
}

```

The optimization opportunities are endless:
- Converting values to references to avoid copies
- Moving repeated computation outside of loops
- Replacing datastructures by other ones based on use
- ...

### Cool visualization tools
*Discrete Bycelium self promotion*

When you have access to the AST of a language, you can really do anything with it including building cool ways to visualize your codebase.

Want a graph of all the function calls? It's just a depth-first search away!

Want to see the hotest code paths of a program? That just a few lines of code inside your interpreter!

Once again, there are many cool things that can be done, which is why I especially like languages that expose features that can interact with the code of the language.
For example:

- Python's `ast` package
- Nim's macro system
- the [JAI language](https://en.wikipedia.org/wiki/Jonathan_Blow#2017%E2%80%93present:_untitled_programming_language,_untitled_sokoban_game,_and_Braid,_Anniversary_Edition) as a whole
- Lisp