---
title: backup
#img_path: '/assets/posts/1970-01-01-backup/'
slug: backup
date_published: 1970-01-01T00:00:00.000Z
date_updated: 2023-02-01T17:26:46.000Z
math: true
---

Let's say we're not working with arrays anymore, we want to store a company's employee hierarchy. At the top of the company, there's the CEO, then under them is the rest of the C-suite, all the way down to the third floor sophomore intern. There are two kinds of people in this company: either you're the boss, or you're an employee, and there's someone else above you.

```ocaml
type Person =                             (* a person is either *)
	| Boss                                (* - the boss *)
    | Employee of { manager : Person }    (* - an employee, with a manager *)
```

It doesn't seem like it when only looking at the code, but the data structure this type is modeling is a **tree**.

> We're implicitly assuming there are no _cycles_, i.e. there's no employee A whose manager is employee B, with A being B's manager. Otherwise, it's not a tree anymore, it's a graph (a tree being a special kind of graph).
{: .prompt-tip }

* * *

Recursion usually refers to a property of _code_ (generally, _an algorithm_), but at its core it is also a property of _data_. Let's have a look at a bit of recursive code.

```csharp
uint factorial(uint n) 
{
	if (n == 0) // base case
    	return 1;
    else // recursive case
    	return n * factorial(n - 1);
}
```

We're gonna try to reason about the _structure_ of the data we're manipulating.

> Structure?

— you ask, wondering what kind of structure I could get out of an unsigned integer. And you would be on the right track. An integer, in itself, doesn't really contain structure. At least, not immediately visible to the eye. There's an infinite number of ways to "create" structure out of an integer; we could, for example, say that a number is either twice another, or twice another plus one:

\[ n \in \mathbb{N}^{+} \implies \exists k \in \mathbb{N}, (n = 2 k \lor n = 2 k + 1) \]

Whoah, maths! If you're reading this blogpost, chances are you're more fluent in code than set theory, so here's another way to write the above:

```ocaml
type Natural =
    | Zero
    | NonZero of { n : Natural, odd : Bool }
```
<label>(in an imaginary language)</label>

Here, we're defining the type `Natural` that is either a value of zero, or a non-zero value that is then made of another natural, and a parity. It gives us a _recursive_ type: it contains a field of its own type. We can encode the number 37 as:

```ocaml
let one = NonZero { n = Zero, odd = True }              (* 2*0  + 1 *)
let two = NonZero { n = one, odd = False }              (* 2*1      *)
let four = NonZero { n = two, odd = False }             (* 2*2      *)
let nine = NonZero { n = four, odd = True }             (* 2*4  + 1 *)
let eighteen = NonZero { n = nine, odd = False }        (* 2*9      *)
let thirty_seven = NonZero { n = eighteen, odd = True } (* 2*18 + 1 *)
```
> Notice the successive values of `odd`: true, false, false, true, false, true.  
> Or, in digits: 100101. This is 37 written in base 2 (binary)!  
>   
> What we've done is tantamount to repeatedly dividing a number by two and keeping the remainder somewhere. The sequence of remainders give us the binary digits of the number.  
>   
> This is actually the generic algorithm for base conversion; if you do the same and divide a number by 10 till you get something that's smaller than 10, the sequence of remainders will give you... the (base 10) digits of the number.
{: .prompt-tip }

But it's not the only way to write the `Natural` type: here's another one.

```ocaml
type Natural =
    | Zero
    | Succ of Natural
```

Here, it's either zero, or the _successor_ of another natural. The successor of a number

\(n\)

is simply

\(n + 1\)

. One is `Succ Zero`, two is `Succ (Succ Zero)`, and so on. Again, it's a recursive type.

Let's get back to our `factorial` example. I'll rewrite the function in OCaml since it's the language I'm using for the current examples:

```ocaml
let rec fact n = 
    if n = 0 
    then 1 
    else n * fact (n - 1)
```

* * *

The usual way to think of computers from a theoretical standpoint is to imagine a simple machine with a bunch of registers (imagine "memory", but simpler, and faster), that runs instructions sequentially, where each instruction can perform reads or writes on those registers. Such a machine would execute code looking like this:

```armasm
mov r0, 3       ; r0 := 3
mov r1, 4       ; r1 := 4
add r2, r1, r0  ; r2 := r1 + r0
mov r3, r2      ; r3 := r2
add r4, r2, r3  ; r4 := r2 + r3
```

This is real assembly, for the ARM instruction set. A fixed number of registers, reads, writes, that's it.

This is the "close to the real world" approach. Real CPUs work like this, but it's not always the best choice when you aren't constrained by the laws of the real world.

There is another approach: stack machines. Here, you're not throwing register numbers around and storing stuff in fixed cells. You've got a stack of values, two operations: push and pop.

Here's what the above code would look like, for such a machine:

```armasm
push 3
push 4
add      ; pop two values from the stack, push their sum
dup      ; duplicate the value on top of the stack
add
```
<label>Note that this is not any real language, it's more like pseudocode.</label>

Here's how the machine looks like at each step of the execution:

<table style="table-layout: fixed ; width: 100%;" class="forth"><tbody><tr><th>Code</th><th colspan="3" style="width: 50%">Stack afterwards</th><th>Variables</th></tr><tr><td>push 3</td><td>3</td><td></td><td></td><td></td></tr><tr><td>push 4</td><td>3</td><td>4</td><td></td><td></td></tr><tr><td>add</td><td>7</td><td></td><td></td><td></td></tr><tr><td>dup</td><td>7</td><td>7</td><td></td><td></td></tr><tr><td>add</td><td>14</td><td></td><td></td><td></td></tr></tbody></table>

The first obvious difference with the register machine program is that here we didn't have to think about numbering registers. In complex programs, this is a real problem (how do you know whether you can/should reuse the value in a register, or overwrite it?), but we don't even have registers here! We're just pushing and popping values.

On top of that, some CPUs have a fairly limited number of registers (ARM Thumb only has 16 registers, and not all of them are really useable), whereas here there doesn't seem to be an obvious limit to how many things we can push onto the stack.

However, you may notice in the table above that there's a column called "Variables" with nothing in it. And indeed, there's a problem with the model above. We're doing everything on a stack, but that means we can't have variables, can we?

This is where your favorite programming paradigm will determine how you're understanding all of this.

If you're more accustomed to imperative programming (think C, Java, Python), this'll look like a real problem to you. Programming without variables isn't really feasible.

On the other hand, if you're coming from a more functionally-inclined language (Haskell, OCaml) you may already have a stack-oriented (function call-oriented) mental model of programming.

Here's an attempt at printing 1 to 10 imperatively, on our imaginary stack machine:

      push 1
    loop:
      dup
      push 10
      compare
      if_greater_goto end
    end:
      

From a computational standpoint, stack machines are elegant in one aspect: locality. Since programs always reason in terms of popping and pushing on top of the stack, you don't really have problems like register overwriting. On a register machine, the following isn't trivial:

```armasm
mov r0, 123
bl func     ; calling func
mov r1, r0  ; r0 may have been modified by func!
```

It requires defining a calling convention that specifies which registers can be clobbered and which registers must be kept the same by the callee. Most of the time, a stack machine is simulated for local variables anyway, and a stack will have to be used anyway if you want recursion. It's stacks all the way down™ (which makes sense, since all computations can in essence be reduced to recursion).

On a stack machine, the only calling convention you have to define is "this function consumes N values from the stack and pushes back M values to the stack". You can still have problems if you violate the convention: if a subprogram pops or pushes more values than it should, you're on for a whole lot of issues.

* * *

Forth, as I said, is like an assembly language for a stack machine. It provide basic operations, like arithmetic operators, branching, and variables. There are some special operations, such as `dup` that duplicates the value on top of the stack, `!` that stores a value in a variable and `@` that gets the value stored in a variable.

Here's a program that shows off some of these instructions: `1 2 dup * + dup + dup * hundred ! 2 hundred @ *`. Not very readable, I admit, so here's a tabulated version with comments:

<table style="table-layout: fixed ; width: 100%;" class="forth"><tbody><tr><th>Code</th><th colspan="3" style="width: 50%">Stack afterwards</th><th>Variables</th></tr><tr><td>1 2</td><td>1</td><td>2</td><td></td><td></td></tr><tr><td>dup</td><td>1</td><td>2</td><td>2</td><td></td></tr><tr><td>*</td><td>1</td><td>4</td><td></td><td></td></tr><tr><td>+</td><td>5</td><td></td><td></td><td></td></tr><tr><td>dup</td><td>5</td><td>5</td><td></td><td></td></tr><tr><td>+</td><td>10</td><td></td><td></td><td></td></tr><tr><td>dup</td><td>10</td><td>10</td><td></td><td></td></tr><tr><td>*</td><td>100</td><td></td><td></td><td></td></tr><tr><td>hundred</td><td>100</td><td>hundred</td><td></td><td></td></tr><tr><td>!</td><td></td><td></td><td></td><td>hundred = 100</td></tr><tr><td>2</td><td>2</td><td></td><td></td><td>hundred = 100</td></tr><tr><td>hundred</td><td>2</td><td>hundred</td><td></td><td>hundred = 100</td></tr><tr><td>@</td><td>2</td><td>100</td><td></td><td>hundred = 100</td></tr><tr><td>*</td><td>200</td><td></td><td></td><td>hundred = 100</td></tr></tbody></table>
