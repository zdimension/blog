---
title: How I Learned to Stop Worrying and Love Macros
slug: how-i-learned-to-stop-worrying-and-love-macros
date_published: 2022-06-07T10:52:08.000Z
date_updated: 2022-11-29T21:39:48.000Z
tags: [Programming, Rust, Compilers, Macros, Code analysis]
excerpt: "A Modest Proposal For Preventing The Children of Rust Developers From Being Exposed To Procedural Macros"
category: "Long posts"
---

Rust macros are powerful, that's a fact. I mean, they allow running any code at compile-time, of course they're powerful.

C macros, which are at the end of the day nothing more than glorified text substitution rules, allow you to implement new, innovative, modern language constructs, such as:

```c
#define ever (;;)
for ever { 
	...
}
```
<label><https://stackoverflow.com/a/652802/2196124></label>

or even:

```c
#include <iostream>
#define System S s;s
#define public
#define static
#define void int
#define main(x) main()
struct F{void println(char* s){std::cout << s << std::endl;}};
struct S{F out;};

public static void main(String[] args) {
	System.out.println("Hello World!");
}
```
<label><https://stackoverflow.com/a/653028/2196124></label>

But these are just silly examples written for fun. Nobody would ever commit such macro abuse in real-world, production code. Nobody...

```c
/*	mac.h	4.3	87/10/26	*/

/*
 *	UNIX shell
 *
 *	S. R. Bourne
 *	Bell Telephone Laboratories
 *
 */
 
...

#define IF		if(
#define THEN	){
#define ELSE	} else {
#define ELIF	} else if (
#define FI		;}

#define BEGIN	{
#define END		}
#define SWITCH	switch(
#define IN		){
#define ENDSW	}
#define FOR		for(
#define WHILE	while(
#define DO		){
#define OD		;}
#define REP		do{
#define PER		}while(
#undef DONE
#define DONE	);
#define LOOP	for(;;){
#define POOL	}

...

ADDRESS alloc(nbytes)
    POS     nbytes;
{
    REG POS rbytes = round(nbytes+BYTESPERWORD,BYTESPERWORD);

    LOOP    INT     c=0;
    REG BLKPTR  p = blokp;
    REG BLKPTR  q;
    REP IF !busy(p)
        THEN    WHILE !busy(q = p->word) DO p->word = q->word OD
        IF ADR(q)-ADR(p) >= rbytes
        THEN    blokp = BLK(ADR(p)+rbytes);
            IF q > blokp
            THEN    blokp->word = p->word;
            FI
            p->word=BLK(Rcheat(blokp)|BUSY);
            return(ADR(p+1));
        FI
        FI
        q = p; p = BLK(Rcheat(p->word)&~BUSY);
    PER p>q ORF (c++)==0 DONE
    addblok(rbytes);
    POOL
}
```
<label>I'm sorry.</label>

This bit of code is taken directly from the original Bourne shell code, from a BSD Tahoe 4.3 source code archive. Steve Bourne was an Algol 68 fan, so he tried to make C look more like it.

But Rust macros ain't like that.

## What are Rust macros?

That's a good question. I've got a better one for you:

## What are macros?

Macros, at the simplest level, are just _things_ that _do other things_ quicker (for the user) than by _manually doing said things_.

This definition encompasses quite a lot of features you've probably already encountered. Of course, if you're a developer, hearing "macro" often triggers a fight-or-flight response, deeply rooted in a bad experience with C preprocessor macros. If you're a Microsoft Office power user, "macros" are probably the first thing you're taught to be afraid of (second only to "moving a picture in a Word document"), thanks in part to the large number of malware that used VBA macros to propagate in the early 2000s. This definition even includes the simple, "key-sequence" macros that a lot of programs allowed you to record and bind to keys.

![](image-1.png){: width="297" height="212"}

I use the past tense here, because this trend wore off quite long ago, around the same time we stopped seeing MDI interfaces.

![](image.png){: width="677" height="437"}
<label>These have pretty much disappeared, replaced by tabs and docking UIs.</label>

Back on topic. This is about programming, so the macros we're talking about are the ones we find in programming languages. Even though the C ones are the most famous (because there's no other language where there are so few built-in constructs that you _have_ to write macros at one point or another), they weren't the first ones.

## A Brief History of Macros

In the early 1950s, if you wanted to write a program for your company's mainframe computer, your choices were more limited than today, language-wise. "Portable" languages (Fortran, COBOL, eventually Algol) were a new concept, so basically everything _serious_ was written in whatever machine language your computer understood. Of course, you didn't write the machine language directly, you used what was and is still called an _assembler_ to translate some kind of textual representation into the raw numeric code data you'd then pass on to the mainframe using punch cards or whatnot.

After some time, assemblers started providing ways to declare "shortcuts" for other bits of code. I'll make a bit of an anachronism here by writing x86 assembly targeting Linux. Let's say you want to make a simple "Hello World" program:

```nasm
section .text						; text segment (code)
	mov eax, 4 						; syscall (4 = write)
	mov ebx, 1 						; file number (1 = stdout)
	mov ecx, message				; string to write
	mov edx, length					; length of string
	int 80h							; call kernel

section .data
	message db 'Hello World', 0xA	; d(efine) b(yte) for the string, with newline
    length equ $ - message			; length is (current position) - (start)
```

Don't worry if you don't fully understand the code above, it's not the point. Here, writing a string takes 5 whole lines (filling up the 4 parameters and then calling the kernel). Compare this to Python:

```python
print("Hello World")
```

If only there were a way to tell the assembler that those five lines are really one single operation, that we may want to do often...

```nasm
%macro print 2		; define macro "print" with 2 parameters
	mov eax, 4
	mov ebx, 1
	mov ecx, %1		; message is first parameter
	mov edx, %2		; length is second parameter
	int 80h	
%endmacro

section .text
	print message1, length1
	print message2, length2
    
section .data
	message1 db 'Hello World', 0xA
	length1 equ $ - message1
    
	message2 db 'Simple macros', 0xA
	length2 equ $ - message2
```

Here, the "macro" is just performing simple text substitution. When you write `print foo, bar`, the assembler replaces the line with everything between `%macro` and `%endmacro`, all while also replacing every occurrence of `%N` with the value of the corresponding parameter. This is the most common kind of macro, and is pretty much what you get in C:

```c
#define PRINT(message, length) write(STDOUT_FILENO, message, length)
```
<label>Don't do this in C.</label>

## Too good to be true

Obviously, it has limitations. What if, in assembly, you did this:

```nasm
mov eax, 42		; just storing something in eax
print foo, bar	; just printing my message
mov ebx, eax	; where's my 42 at?
```

Unbeknownst to you, the `print` macro modified the value of the `eax` register, so the value you wrote isn't there anymore!

What if, in C, you did this:

```c
#define SWAP(a, b) int tmp = a;	\
                   a = b;		\
                   b = tmp;

int main() {
	int tmp = 123;
    // ...
	int x = 5, y = 6;
    SWAP(x, y); // ERROR: a variable named 'tmp' already exists
}
```

Here, there's a conflict between the lexical scope of the function (`main`) and the macro (`SWAP`). Short of using names like `__macro_variable_dont_touch_tmp` in your macros, there's not much you can do to entirely prevent problems like this. What about this:

```c
int main() {
	int x = 5, y = 6, z = 7;
    int test = 100;

	if (test > 50)
    	SWAP(x, y);
    else
    	SWAP(y, z);
}
```

The above code does not compile. It walks like correct code and quacks like correct code, but here's what it looks like after macro-expansion:

```c
int main() {
	int x = 5, y = 6, z = 7;
    int test = 100;

	if (test > 50)
    	int tmp = x;
        x = y;
        y = tmp;
    else
    	int tmp = y;
        y = z;
        z = tmp;
}
```

Braceless `if`s must contain exactly one statement, but here there are 3 of them! Let's fix it:

```c
#define SWAP(a, b) {int tmp = a;	\
                   a = b;			\
                   b = tmp;}
```

Now, it should work, shouldn't it? Nope, still broken!

```c
if (test > 50)
   	{int tmp = x;
    x = y;
    y = tmp;};
else
   	{int tmp = y;
    y = z;
    z = tmp;};
```

Not seeing it? Let me reformat it for you:

```c
if (test > 50) {
   	int tmp = x;
   	x = y;
  	y = tmp;
}
;
else
   	...
```

Since we're writing `SWAP(x, y);` there's a semicolon hanging right there, after the code block, so the `else` is not connected to the `if` anymore. The solution, _obviously_, is to do:

```c
#define SWAP(a, b) do{int tmp = a;		\
                   a = b;				\
                   b = tmp;}while(0)
```

Here, the expanded code is equivalent to the one we had before, but requires a semicolon afterwards, so the compiler is happy.

Another simple example is

```c
#define MUL(expr1, expr2) expr1 * expr2

int res = MUL(2 + 3, 4 + 5);
```

This gets expanded to

```c
int res = 2 + 3 * 4 + 5; // bang!
```

Macros have no knowledge of concepts such as "expressions" or "operator precedence", so you have to resort to tricks like adding parentheses _everywhere_:

```c
#define MUL(expr1, expr2) ((expr1) * (expr2))
```

> But... it's broken? There's no reason anyone should have to do this sort of syntax wizardry just to get a multiline macro or a macro processing expressions to work!

A few years ago, in the 1960s to be precise, some smart guys in a lab realized that "just replace bits of text by other bits of text" was not, bear with me, the best way to _do macros_. What if, instead of performing modifications on the _textual form_ of the code, the macros could work on an abstract representation of the code, and likewise produce an output in a similar way.

## SaaS (Software as an S-expression)

This is a Lisp program (and its output):

```scheme
> (print (+ 1 2))
3
```

Lisp (for _LISt Processing_) has a funny syntax. In Lisp, things are either _atoms_ or _lists_. An atom, as its name implies, is something "not made of other things". Examples include numbers, strings, booleans and symbols. A list, well, it's a list of things. A list being itself a thing, you can nest lists. This is a list containing various things (don't try to run it, it's not a full program):

```scheme
(one ("thing" or) 2 "inside" a list)
```

You may notice that this looks awfully like the program I wrote earlier; it's not luck: one of Lisp's basic tenets is that programs are just data. A function call, that most languages would write `f(x, y)` can simply be encoded as a list: `(f x y)`.

The technical term for a "thing" (something that is either an atom or a list, with lists written with parentheses and stuff) is _s-expression_.

When you give Lisp an expression, it tries to evaluate it. A symbol evaluates to the value of the variable with the corresponding name. Other atoms evaluates to themselves. A list is evaluated by looking at its first element, which must be a function, and calling it with the rest of the list as its parameters. You can tell Lisp to _not_ evaluate something, using a function (~technically...~) called `quote`.

```scheme
> (+ 4 5)
9
> (quote (+ 4 5))
(+ 4 5)
```

In the end, you get code like this:

```scheme
> (print (length (quote (a b c d))))
4
```

`(print...` and `(length...` are evaluated, but `(a...` is kept as it, because it's really a list, not a bit of code.

The opposite of `quote` is called `eval`:

```scheme
> (quote (+ 4 5))
(+ 4 5)
> (eval (quote (+ 4 5))
9
```

Through this simple mechanic, Lisp allows you to modify programs dynamically as if they were any other kind of data you can manipulate — because they really are any other kind of data you can manipulate.

Let's rewrite our `MUL` macro from before. I'll define a function which takes two parameters, and returns _code_ that multiply them.

```scheme
> (define (mul expr1 expr2)
  	(list (quote *) expr1 expr2)) ; * is quoted so it appears verbatim in the output
> (mul (+ 2 3) (+ 4 5))
  	(* 5 9)
```

That's not exactly what I want, since I don't want the operands to be evaluated right at the beginning, so I'll `quote` them:

```scheme
> (mul (quote (+ 2 3)) (quote (+ 4 5)))
  	(* (+ 2 3) (+ 4 5))
> (eval (mul (quote (+ 2 3)) (quote (+ 4 5))))
  	45
```

You'll notice right away that we don't have any operator precedence problem like we had in C. But we do have problems: we have to put `(quote ...)` around every operand to prevent it from being evaluated, and we have to `(eval ...)` the result to really run the code that was produced. Since these steps are quite common, they were [abstracted away in a language builtin](https://wiki.c2.com/?DesignPatternsAreMissingLanguageFeatures) called `define-macro`:

```scheme
> (define-macro (mul expr1 expr2)
  	(list (quote *) expr1 expr2))
> (mul (+ 2 3) (+ 4 5))
  	45
```

Here's what the `SWAP` macro would look like:

```scheme
(define-macro (swap var1 var2)
  	(quasiquote 
    	(let ((tmp (unquote var1)))
    		(set! (unquote var1) (unquote var2))
        	(set! (unquote var2) tmp)))
```

I'm using functions I haven't talked about yet. `quasiquote` does the same thing as `quote`, that is, return its argument without evaluating it, except that if you write `(unquote ...)` somewhere in it, the argument of `unquote` is inserted _evaluated_. You don't have to understand this, only that all of these tools are, in the end, nothing more than syntactic sugar for manipulating lists. I could've written `swap` using only list manipulation functions:

```scheme
(define-macro (swap var1 var2)
	(list 'let (list (list 'tmp var1))
    	(list 'set! var1 var2)
        (list 'set! var2 'tmp)))
```

We could argue that even `list` is syntactic sugar, and it's true, the real primitive used to build lists is `cons`: `(list 1 2 3)` can be constructed by doing `(cons 1 (cons 2 (cons 3 ())))`. `()` is a special value that corresponds to the empty list, it's often used as an equivalent of `null`.

`set!` is just what you use to change a variable's value.

Quick sidenote, since `quote`, `unquote` and `quasiquote` are _very_ common, there's even more syntactic sugar in the language to write them more concisely: `'` for `quote` , `,` for `unquote` and `` ` `` for `quasiquote`. The code above, in a real codebase, would look like this:

```scheme
(define-macro (swap var1 var2)
  	`(let ((tmp ,var1))
		(set! ,var1 ,var2)
		(set! ,var2 tmp)))
```

## That's cheating, Lisp isn't a real language anyway

I mean, obviously. Real languages have syntaxes way more complex than lists of things. When you look at a real program written in a real language, for example C, you don't see a list. You see blocks, declarations, statements, expressions.

```c
int factorial(int x) // function signature
{ // code block
	if (x == 0) // conditional statement
    {
    	return 1; // return statement
    } 
    else 
    {
    	return x * factorial(x - 1); // expression, function call
    }
}
```

Well...

```scheme
(define (factorial x)
	(if (zero? x)
    	1
        (* x (factorial (- x 1)))))
```

Or, linearly:

```scheme
(define (factorial x) (if (zero? x) 1 (* x (factorial (- x 1)))))
```
<label>That's a list of lists if I've ever seen one</label>

When a compiler or interpreter reads a program, it does something called _parsing_. It reads a sequence of characters (letters, digits, punctuation, ...) and converts it (this is the non-trivial part) into something it can process more easily.

Think about it, when you read the block of C code above, you don't read a sequence of letters and symbols. You see that it's a function declaration, with a return type, a name, a list of parameters and a body. Each parameter has a name and a type, and the body is a code block containing an `if`\-statement, itself containing more code.

A data structure that stores things that are either atomic or made of other things is called a _tree_. Lisp lists (try saying that out loud quickly) can contain atoms or other lists, they're just one way of encoding trees.

Here, we're using a _tree_ to store a program's source code, which is text, but we know that the code respects a set of rules, called the _syntax_. Oh, and we _abstract_ away non-essential details like whitespace, parentheses and whatnot.

We might as well call that _an Abstract Syntax Tree_! (a.k.a. AST)

<svg class="kg-image" style="max-width: 100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0.00 0.00 608.44 401.73"><style>html:not([data-mode="light"]) body svg .edge text { fill: rgb(192, 186, 178) !important; } html:not([data-mode="light"]) body svg .node text { fill: rgb(0, 0, 0) !important; } html:not([data-mode="light"]) body svg .edge polygon { fill: rgb(192, 186, 178); stroke: rgb(192, 186, 178); } html:not([data-mode="light"]) body svg .edge path { stroke: rgb(192, 186, 178); } html:not([data-mode="light"]) body svg ellipse { filter: brightness(.7) contrast(1.2); stroke: transparent; } </style><g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 397.7251)"><title>G</title> <g id="node1" class="node"><title>fdecl</title> <ellipse fill="#cae8ff" stroke="#000000" cx="183.5156" cy="-364.3095" rx="100.3619" ry="29.3315"></ellipse><text text-anchor="middle" x="183.5156" y="-368.5095" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Function declaration</text> <text text-anchor="middle" x="183.5156" y="-351.7095" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'factorial'</text> </g><g id="node2" class="node"><title>id1</title> <ellipse fill="#ff989c" stroke="#000000" cx="61.5156" cy="-252.6782" rx="33.1356" ry="29.3315"></ellipse><text text-anchor="middle" x="61.5156" y="-256.8782" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Type</text> <text text-anchor="middle" x="61.5156" y="-240.0782" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'int'</text> </g><g id="edge1" class="edge"><title>fdecl-&gt;id1</title> <path fill="none" stroke="#000000" d="M135.374,-338.478C125.5083,-332.0981 115.5785,-324.8006 107.1636,-316.8939 97.9741,-308.2592 89.4835,-297.5161 82.3801,-287.3027"></path><polygon fill="#000000" stroke="#000000" points="85.2284,-285.2658 76.7547,-278.906 79.4129,-289.162 85.2284,-285.2658"></polygon><text text-anchor="middle" x="143.6916" y="-304.2939" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Return type</text> </g><g id="node3" class="node"><title>plist</title> <ellipse fill="#cae8ff" stroke="#000000" cx="183.5156" cy="-252.6782" rx="70.6761" ry="18"></ellipse><text text-anchor="middle" x="183.5156" y="-248.4782" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Parameter list</text> </g><g id="edge2" class="edge"><title>fdecl-&gt;plist</title> <path fill="none" stroke="#000000" d="M183.5156,-334.6874C183.5156,-318.0498 183.5156,-297.3965 183.5156,-280.9788"></path><polygon fill="#000000" stroke="#000000" points="187.0157,-280.8864 183.5156,-270.8865 180.0157,-280.8865 187.0157,-280.8864"></polygon><text text-anchor="middle" x="219.6853" y="-304.2939" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Parameters</text> </g><g id="node6" class="node"><title>body</title> <ellipse fill="#cae8ff" stroke="#000000" cx="372.5156" cy="-252.6782" rx="66.0007" ry="18"></ellipse><text text-anchor="middle" x="372.5156" y="-248.4782" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'If' statement</text> </g><g id="edge5" class="edge"><title>fdecl-&gt;body</title> <path fill="none" stroke="#000000" d="M228.306,-337.8544C261.1917,-318.4308 305.3052,-292.3755 336.048,-274.2175"></path><polygon fill="#000000" stroke="#000000" points="337.9072,-277.1844 344.7375,-269.0851 334.3473,-271.1572 337.9072,-277.1844"></polygon><text text-anchor="middle" x="305.4665" y="-304.2939" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Body</text> </g><g id="node4" class="node"><title>p1</title> <ellipse fill="#cae8ff" stroke="#000000" cx="57.5156" cy="-141.0469" rx="57.5313" ry="29.3315"></ellipse><text text-anchor="middle" x="57.5156" y="-145.2469" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Parameter</text> <text text-anchor="middle" x="57.5156" y="-128.4469" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'x'</text> </g><g id="edge3" class="edge"><title>plist-&gt;p1</title> <path fill="none" stroke="#000000" d="M163.8281,-235.2358C145.1728,-218.7079 116.6969,-193.4793 93.9099,-173.2908"></path><polygon fill="#000000" stroke="#000000" points="96.2286,-170.6691 86.4226,-166.6574 91.5866,-175.9086 96.2286,-170.6691"></polygon></g><g id="node5" class="node"><title>id4</title> <ellipse fill="#ff989c" stroke="#000000" cx="57.5156" cy="-29.4156" rx="33.1356" ry="29.3315"></ellipse><text text-anchor="middle" x="57.5156" y="-33.6156" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Type</text> <text text-anchor="middle" x="57.5156" y="-16.8156" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'int'</text> </g><g id="edge4" class="edge"><title>p1-&gt;id4</title> <path fill="none" stroke="#000000" d="M57.5156,-111.4249C57.5156,-98.5568 57.5156,-83.2867 57.5156,-69.4319"></path><polygon fill="#000000" stroke="#000000" points="61.0157,-69.1761 57.5156,-59.1761 54.0157,-69.1762 61.0157,-69.1761"></polygon><text text-anchor="middle" x="73.0745" y="-81.0313" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Type</text> </g><g id="node7" class="node"><title>cond</title> <ellipse fill="#cae8ff" stroke="#000000" cx="216.5156" cy="-141.0469" rx="83.2543" ry="29.3315"></ellipse><text text-anchor="middle" x="216.5156" y="-145.2469" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Binary operation</text> <text text-anchor="middle" x="216.5156" y="-128.4469" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'=='</text> </g><g id="edge6" class="edge"><title>body-&gt;cond</title> <path fill="none" stroke="#000000" d="M348.8226,-235.7238C325.7821,-219.2364 290.1909,-193.7678 261.7239,-173.3973"></path><polygon fill="#000000" stroke="#000000" points="263.6901,-170.5005 253.521,-167.5274 259.6165,-176.1931 263.6901,-170.5005"></polygon><text text-anchor="middle" x="334.0773" y="-192.6626" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Condition</text> </g><g id="node10" class="node"><title>body_true</title> <ellipse fill="#cae8ff" stroke="#000000" cx="382.5156" cy="-141.0469" rx="64.3327" ry="18"></ellipse><text text-anchor="middle" x="382.5156" y="-136.8469" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">[code if true]</text> </g><g id="edge9" class="edge"><title>body-&gt;body_true</title> <path fill="none" stroke="#000000" d="M374.1669,-234.2446C375.7542,-216.5258 378.1747,-189.5053 380.0015,-169.1129"></path><polygon fill="#000000" stroke="#000000" points="383.4888,-169.41 380.8951,-159.1376 376.5167,-168.7854 383.4888,-169.41"></polygon><text text-anchor="middle" x="396.4097" y="-192.6626" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">If true</text> </g><g id="node11" class="node"><title>body_false</title> <ellipse fill="#cae8ff" stroke="#000000" cx="532.5156" cy="-141.0469" rx="67.8454" ry="18"></ellipse><text text-anchor="middle" x="532.5156" y="-136.8469" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">[code if false]</text> </g><g id="edge10" class="edge"><title>body-&gt;body_false</title> <path fill="none" stroke="#000000" d="M396.8162,-235.7238C424.3845,-216.4895 469.4718,-185.0323 500.0391,-163.7056"></path><polygon fill="#000000" stroke="#000000" points="502.0505,-166.57 508.249,-157.9776 498.0452,-160.8292 502.0505,-166.57"></polygon><text text-anchor="middle" x="483.1327" y="-192.6626" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">If false</text> </g><g id="node8" class="node"><title>cop1</title> <ellipse fill="#98ff9c" stroke="#000000" cx="186.5156" cy="-29.4156" rx="47.7346" ry="29.3315"></ellipse><text text-anchor="middle" x="186.5156" y="-33.6156" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Variable</text> <text text-anchor="middle" x="186.5156" y="-16.8156" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">'x'</text> </g><g id="edge7" class="edge"><title>cond-&gt;cop1</title> <path fill="none" stroke="#000000" d="M208.6335,-111.7171C205.0852,-98.5138 200.8452,-82.7364 197.0311,-68.5441"></path><polygon fill="#000000" stroke="#000000" points="200.3206,-67.2985 194.3451,-58.5496 193.5605,-69.1153 200.3206,-67.2985"></polygon><text text-anchor="middle" x="236.5843" y="-81.0313" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Operand 1</text> </g><g id="node9" class="node"><title>cop2</title> <ellipse fill="#fffec9" stroke="#000000" cx="303.5156" cy="-29.4156" rx="50.8492" ry="29.3315"></ellipse><text text-anchor="middle" x="303.5156" y="-33.6156" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Constant</text> <text text-anchor="middle" x="303.5156" y="-16.8156" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">0</text> </g><g id="edge8" class="edge"><title>cond-&gt;cop2</title> <path fill="none" stroke="#000000" d="M253.4566,-114.4056C260.676,-108.1246 267.7768,-101.0719 273.5156,-93.6313 279.5395,-85.8211 284.7323,-76.6063 289.0238,-67.6321"></path><polygon fill="#000000" stroke="#000000" points="292.2502,-68.9912 293.1668,-58.4361 285.868,-66.1158 292.2502,-68.9912"></polygon><text text-anchor="middle" x="317.5843" y="-81.0313" font-family="Helvetica,sans-Serif" font-size="14.00" fill="#000000">Operand 2</text></g></g></svg>

I've omitted some details from the diagram above for the sake of brevity, but you get the idea. Code (text) becomes code (tree), and code (tree) matches more closely the mental idea we have of what code (text) means.

We reach the same conclusion we had we Lisp: code is data. The only difference is that in Lisp, you can really take code and turn it into data, it's "built-in", whereas there's nothing in C for that. The main reason is that code is a weird kind of data. Numbers are simple; arrays, a bit more convoluted but still simple; code is hard to reason about. Trees and stuff. Lisp is built around dynamic lists, so it's easy. C is built around human suffering, it's definitely not made for manipulating code. I mean, imagine writing a parser, or even a compiler in C.

Being able to manipulate code from code is called _metaprogramming_, and few languages have it built-in. Lisp does it, [because it's Lisp](https://en.wikipedia.org/wiki/Homoiconicity). C# does it too, albeit only for a (large enough) subset of the language, with what they call "expression trees":

```csharp
void Swap<T>(Expression<Func<T>> a, Expression<Func<T>> b)
{
	var tmp = Expression.Parameter(typeof(T));
	var code = Expression.Lambda(
		Expression.Block(new [] { tmp }, 		// T tmp;
			Expression.Assign(tmp, a.Body),		// tmp = [a];
			Expression.Assign(a.Body, b.Body),	// [a] = [b];
			Expression.Assign(b.Body, tmp)));	// [b] = tmp;
	var compiled = (Func<T>) code.Compile();
	compiled();
}

class Foo
{
	public int A;
	public int B;
}

var obj = new Foo { A = 123, B = 456 };
Swap(() => obj.A, () => obj.B);
```

It's a bit more complicated than in Lisp, because here, the way to achieve what we did with `quote` (i.e., pass an unevaluated expression to a function) involves declaring a parameter with the `Expression<T>` type, with `T` being a function type. This means that you can't pass _any_ expression directly, you must pass _a function_ returning that expression (hence the `() =>`). In other words, `() => x` is the closest C# provides to `(quote x)`.

We don't have `eval` either, instead we can compile an expression we built into a real function we can then call (and it's that call that does what `eval` would do in Lisp in that context).

Building code is also more complicated: since C# code is not made of lists, you can't just create a sequence of things and call it a day, code here is stored as objects ("expression trees") that you build using functions such as `Expression.Assign` or `Expression.Block`.

All of this also means that only a subset of the language is available through this feature — you can't have classes in functions for examples. At the end of the day, it's not really a problem, most problems solved by macros are solved through other means in C#, and this metaprogramming-like expression tree wizardry is almost only ever used in contexts where only simple expressions will be used.

## Long Recaps Considered Harmful

3,000! If you're still there, you've just read 3,000 words of me rambling about old languages and weird compiler theory terminology. This post was supposed to be about Rust macro abuse.

Rust has macros. Twice.

Rust supports two kinds of macros: declarative macros and procedural macros.

Declarative macros are a bit like C macros, in that they can be quite easy to write, although in Rust they are much less error-prone. See for yourself:

```rust
macro_rules! swap {
    ($a:expr, $b:expr) => { 
        let tmp = $a;
        $a = $b;
        $b = tmp;
    };
}

fn main() {
    let (mut a, mut b) = (123, 456);
    swap!(a, b);
    println!("a={} b={}", a, b);
}
```
```rust
macro_rules! mul {
	($a:expr, $b:expr) => {
    	$a * $b
    };
}

fn main() {
	println!("{}", mul!(2 + 3, 4 + 5)); // no operator precedence issue
}
```

Declarative macros can operate on various parts of a Rust program, such as expressions, statements, blocks, or even specific token types, such as identifiers or literals. They can also operate on a raw token trees, which allow for [interesting code manipulation techniques](https://github.com/scrabsha/dyl/commit/ef8b387c2d0f30daf10f4a46c9824c80a1c71e31). But even though they work in a cleaner way and support advanced patterns, with repetitions and optional parameters, they're just a _more advanced_ form of substitution. So, closer to C macros.

Procedural macros, on the other hand, are more like Lisp macros. They're written in Rust, get passed a token stream (a list of tokens from the source code) and are expected to give one back to the compiler. Apart from that, they can do basically anything.

They look like this:

```rust
#[proc_macro]
pub fn macro_name(input: TokenStream) -> TokenStream {
    todo!()
}
```

They're often used for code generation, for example for generating methods from a struct definition, for example:

```rust
#[derive(Debug)]
struct Person {
	name: String,
    age: u8
}
```

This generates an implementation of the `Debug` trait for the `Person` type, which will contain code allowing to get a pretty-printed, human-readable version of any `Person` object when needed. `derive(PartialEq)` and `derive(PartialOrd)` generate equality and ordering methods, etc.

But there are less... orthodox uses for procedural macros.

[Mara Bos](https://twitter.com/m_ou_se) famously wrote some interesting crates — the first one, [inline\_python](https://github.com/fusion-engineering/inline-python), allows running Python code from Rust seamlessly, with bidirectional interaction (for variables):

```rust
use inline_python::python;

fn main() {
    let who = "world";
    let n = 5;
    python! {
        for i in range('n):
            print(i, "Hello", 'who)
        print("Goodbye")
    }
}
```

I highly recommend reading [her blogpost series](https://blog.m-ou.se/writing-python-inside-rust-1/) on the subject where she goes deep in detail on how to implement such a macro. It involves lots of subtle tricks needed to deal with how the Rust compiler reads and tokenizes code, how errors can be mapped from Python to Rust, etc.

She also wrote [whichever\_compiles](https://github.com/m-ou-se/whichever-compiles), which runs multiple instances of the compiler to find... whichever bit of code compiles, among a list you provide:

```rust
use whichever_compiles::whichever_compiles;

fn main() {
    whichever_compiles! {
        try { thisfunctiondoesntexist(); }
        try { invalid syntax 1 2 3 }
        try { println!("missing arg: {}"); }
        try { println!("hello {}", world()); }
        try { 1 + 2 }
    }
}

whichever_compiles! {
    try { }
    try { fn world() {} }
    try { fn world() -> &'static str { "world" } }
}
```

The macros `fork`s the compiler process, at compile-time, and each child process tries one of the branches. The first one to compile wins, and the winning branch is used for the rest of the build process.

After a series of unfortunate events, I was informed of the existence of procedural macros, and decided that I had to make one. After some nights of work, I brought to the world [embed-c](https://github.com/zdimension/embed-c), the first procedural macro to allow anyone to write pure, unadulterated C code in the middle of a Rust code file. Complete with full interoperability with the Rust code, obviously. This has made a lot of people very angry and been widely regarded as a bad move.

```rust
use embed_c::embed_c;

embed_c! {
    int add(int x, int y) {
        return x + y;
    }
}

fn main() {
    let x = unsafe { add(1, 2) };
    println!("{}", x);
}
```

It uses a library called [C2Rust](https://github.com/immunant/c2rust) which, really, is what it sounds like. It's a toolset that relies on Clang to parse and analyze C code, and generates equivalent (in behavior) Rust code. Obviously, the generated code is not idiomatic, and quickly becomes unreadable if you use enterprise-grade C control flow features such as `goto`. But can Rust really replace C in the industry without a proper implementation of Duff's device?

```rust
embed_c! {
    void send(to, from, count)
        register short *to, *from;
        register count;
    {
        register n = (count + 7) / 8;
        switch (count % 8) {
        case 0: do { *to++ = *from++;
        case 7:      *to++ = *from++;
        case 6:      *to++ = *from++;
        case 5:      *to++ = *from++;
        case 4:      *to++ = *from++;
        case 3:      *to++ = *from++;
        case 2:      *to++ = *from++;
        case 1:      *to++ = *from++;
                } while (--n > 0);
        }
    }
}

fn main() {
    let mut source = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let mut dest = [0; 10];
    unsafe { send(dest.as_mut_ptr(), source.as_mut_ptr(), 10); };
    assert_eq!(source, dest);
}
```

After seeing Mara's inline\_python crate, I was taken aback by her choice of such an outdated language — Python was created in 1991!

VBScript, first released in 1996, is a much more modern language than Python. It provides transparent COM interoperability, is supported out-of-the-box on every desktop version of Windows since 98 — even Windows CE on ARM is supported; and it has been since 2000, whereas Python won't run on Windows ARM until 3.11 (2022).

As such, I had no other choice but to create [inline\_vbs](https://github.com/zdimension/inline-vbs), for all your daily VBS needs.

```rust
use inline_vbs::*;

fn main() {
    vbs![On Error Resume Next]; // tired of handling errors?
    vbs![MsgBox "Hello, world!"];
    if let Ok(Variant::String(str)) = vbs_!["VBScript" & " Rocks!"] {
        println!("{}", str);
    }
}
```

It relies on the [Active Scripting](https://docs.microsoft.com/en-us/archive/msdn-magazine/2000/december/active-scripting-apis-add-powerful-custom-debugging-to-your-script-hosting-app) APIs, that were originally designed to allow vendors to add scripting support to their software, and it's actually a nice idea. You can have multiple languages providers, and a program relying on the AS APIs would automatically support all installed languages. The most common were JScript and VBScript, because they were installed by default on Windows, but you could add support for Perl, REXX or even Haskell. Haskell! Think about it. This means that on a computer with the Haskell provider installed, this bit of code would be valid and would kinda work in Internet Explorer:

```html
<HTML>
    <HEAD>
        <TITLE>Active Scripting demo</TITLE>
    </HEAD>
    <BODY>
        <H1>Welcome!</H1>
        <SCRIPT LANGUAGE="HASKELL">
            main :: IO ()
            main = putStrLn "Hello World"
        </SCRIPT>
    </BODY>
</HTML>
```

One major pain point is that VBScript, like Python, is a dynamic language, where values can change type, something that statically-typed languages like Rust are proud to say they do not like at all, thank you very much.

Since VBScript is handled through COM APIs, values are transferred using the `VARIANT` COM type, which is pretty much a giant `union` of every COM type under the sun. Luckily, this matches up perfectly with Rust's discriminated unions — I take it as a sign from the universe that Rust and VBScript were made to work together.

That's pretty much it for today.

<a href="https://news.ycombinator.com/item?id=32507659">
    Discuss on Hacker News
</a>