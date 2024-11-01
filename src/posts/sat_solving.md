{%
setvar("layout",theme .. ".html")
%}
# Making the computer do math
*How I wrote a sat solver, and what I learnt along the way.*

I'm not really good at calculus. There are all these symbols everywhere, you need
to operate on them, and you have a lot of opportunities to make mistakes.

I mean like come on, I'm not computing a 5x5 determinant.

Wouldn't it be neat if the computer could do calculus for me? Compute derivative,
solve equation, etc...

Well, there is [WolframAlpha](https://wolframalpha.com), but I need something more.

You see, I'm tired of finishing third on my school's Advent Of Code leaderboard. Part of it is because
I'm not motivated enough to make up at 6am all of december. But another part of it is because I'm a bit 
slow at solving the problem during the later days of the month.

Usually, the first solves come after three hours, because the best are probably using something like [Picat](http://picat-lang.org/),
which is clearly cheating. To be able to catch up, I need a picat like solver in my favorite language, [Nim](https://nim-lang.org)!

The most important part of Picat is the predicate driven programming style.
When you define a computation, you can execute it both ways.

```python

def my_func(A,B,C):
	return 3*A + 2*B + C

```

Consider `my_func`. If you know A,B and C, you can know `my_func(A,B,C)`.
But what if you know `my_func(A,B,C)`, A and B, how do you find C ?
Well, you could use your brain.
Or you could use picat.

```pi
import cp.

main =>
	Vs = [A,B,C,D],
	D #= 3*A + 2*B + C,
	A #= 1,
	B #= 2,
	D #= 3,
	solve(Vs),
	println(Vs)
```

This prints: `[1,2,-4,3]`

I want the same in Nim.
The idea is that I can define a list of constraints, like: `D = 3*A + 2*B + C` or `D = 3`, and
then solve for the constraints.

I'm starting small with only booleans and plan to expand the solver to more complex datatypes later.

My API looks like this:

```nim
let sa = eSym("a")
let sb = eSym("b")
let sc = eSym("c")

var expression = (sa and not sb) and (sc or not sa)
var (solvable, solution) = solve(expression)

if solvable:
	echo $solution
else:
	echo "No solution!"
```

We just everwrite the `and`, `or` and `not` operators for the `Expression` type to build a tree.
Now, we need to write the `solve` function.

I'm using a common approch for NP-complete problems: start by doing human like deductions (think of it like solving a sudoku) and then brute-forcing over the space of allowed values (which is smaller because we deduce that some values are impossible).

The brute force is kinda boring and looks like this:

```nim

var overflow = false
var unbound: seq[Symbol] # symbols whose value was not deduced.
var binaryCounter: seq[bool]

# Init unbound and binaryCounter
# ...

while not eval(exp): # We want to solve exp, our SAT-expression.
    if overflow: break

    # Incrementation of the binaryCounter.
    for i in 0..<binaryCounter.len:
        if not binaryCounter[i]:
            binaryCounter[i] = true
            break
        else:
            binaryCounter[i] = false
            if i == binaryCounter.len - 1:
                overflow = true

    for i in 0..<unbound.len:
        unbound[i].value = binaryCounter[i]
```

The interesting part is the deduction engine.

The idea is that we infer constraints on parts of the expression in order to make deductions.
For example, if `A and B` is true, then, we deduce that `A` is true and `B` is true.
Also, if `A and B` is false and `A` is true, than `B` must be false.

Using this strategy, and by first assuming that the whole expression E is true, we deduce the values of every subcomponent.

Let's consider for example: `(sa and not sb) and (sc or not sa)`

We first deduce that: `(sa and not sb)` is true and `(sc or not sa)` is true.
Then that: `sa` is true and `not sb` is true and thus that `sb` is false.

We then perform an important other step: substitutions!
If a variable has a known value, we can substitute it's value in the equation.
We get: `(true and not false) and (sc or not true)`
We simplify and get `true and (sc or false)`, and further `sc`.
Thus, `sc` is true and we solve the problem without even needing bruteforce.

What I found interesting while implementing the problem is that we are actually defining an isomorphism between
true and false as formal logic values and true and false, as booleans that the computer can understand.

Take this sentence:

`A and B` is true, then, we deduce that `A` is true and `B` is true.

We went from `and` the boolean operation to "and", the logic operator.

```
if top.operator == '&' and onlyTrue(allowed): # if top is known to be true (and not true or false)
    allowedValues.deduce(top.lexpr, true, deductionPerformed) # deduce that both subexpressions are also true
    allowedValues.deduce(top.rexpr, true, deductionPerformed)
```

I think that's interesting because it's not the first time I write formal solvers and this kind of things comes up a lot.

You often need to convert from a "data" representation that is usually a tree like structure to a behavior, and you find yourself
writing this kind of code. This is also true when writing an interpreter for example.

So, next time you need to write a formal solver like program, keep in mind what fundamental rules your objects follow so that
you can perform simplification easily!
