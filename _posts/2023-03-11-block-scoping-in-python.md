---
title: Block scoping in Python
slug: block-scoping-in-python
date_published: 2023-03-11T16:58:06.000Z
date_updated: 2023-03-12T12:09:18.000Z
tags: [Programming, Dark magic]
excerpt: "Python doesn't have block scoping. Or does it?"
image: 
    path: julia-kadel-YmULswIbc3I-unsplash.jpg
    alt: Photo by <a href="https://unsplash.com/@juliakadel">Julia Kadel</a> on <a href="https://unsplash.com">Unsplash</a> 
---

Python uses function-level scoping, for most cases:

```py
def f():
	x = 6
    if x > 0:
    	y = 5
    print(y)  # This works, even though `y` was declared inside the `if`
```

A variable declared anywhere outside a function is in the (module's) global scope, and a variable declared inside a function is in that function's scope except exceptions in `except` blocks since it would create GC cycles and comprehension expressions because those behave like functions ; blocks like conditionals and loops don't have their own scope like in C-family languages such as C, C++, Java, etc.

JavaScript, famously, also historically used function scoping, with `var`, though block scoping has been introduced in ES6 with the keywords `let` and `const`. Python doesn't have declarations though, so there's no real way to properly retrofit that onto the language, so we're still stuck with function scoping. Whether it's a good feature or not is outside the _scope_ (got it?) of this blogpost.

Python's scoping is quite coherent with the absence of declarations, how would you do something like this:

```py
if cond:
	x = 5
else:
	x = 6
```

If variables had to be declared, you'd have to resort to tricks like writing `x = None` beforehand, but this messes with typing, since `x` is not an `int` anymore but an `Union[int, None]` (the cool kids call it `Optional[int]`).

But it has its warts. Since blocks don't introduce scopes, you can't shadow variables, like in Rust:

```rust
let x = 123;
if true {
	let x = 456; // shadows the outer `x`, i.e. creates a new variable with the same name
}
let y = x; // y == 123
```

You can't shadow variables either in C#, but since there _is_ block scoping anyway, the compiler will yell at you:

```csharp
var x = 123;
if (true) {
	var x = 456; // CS0136: A local or parameter named 'x' cannot be declared in this scope because that name is used in an enclosing local scope to define a local or parameter
}
```

In Python, if you do this:

```py
x = 123
if True:
	x = 456  # well... it does what you expect
y = x  # y == 456
```

Which... isn't bad, per se. But this is a simplified case. Problems start to appear when you start have nested blocks (which... are another discussion we'll have someday). Imagine this:

```py
def greet(self, person):
	name = person.name.title()
	print("Hello", name)
    for child in person.children:
    	name = child.name.title()
        print("- child:", name)
	print("Goodbye", name)
```

We're declaring a new variable `name` inside the loop, but this just overwrites the outer one, so the function will actually end by displaying "Goodbye" followed by... the name of the last child.

> Yeah, but this is just how Python's scoping works! Any Python developer would see that this code doesn't know what it's supposed to be doing!
{: .prompt-warning }

The Principle of Least Astonishment (hereafter PLA) posits that a system (user interface, machine, tool...) should behave in the way the (average) user expects it to behave. Basically, behavior should be intuitive within reason. The principle itself sounds intuitive and self-evident, but push-pull doors and the USB port are famous examples of physical devices that consistently fail to behave consistently with the user's expected behavior.

Python is, and has been for a long time, a repeated offender. More than a lot of other programming languages, actually.

Most people would agree that C, for example, behaves counter-intuitively in a lot of situations, but since this is true, most people _expect_ C to behave counter-intuitively. It is expected that professional, seasoned C programmers will involuntarily write profoundly incorrect code, that triggers undefined behavior and gets yeeted out by the optimizer in unexpected ways. This is a hill I will die on.

Python, on the other hand, is supposed to be that easy language, that does what you expect it to do.

This code behaves intuitively:

```py
def thing(seq=[]):
	seq.append("Hello")
    print(seq)
    
thing()  # Displays ["Hello"]
```

But what about this one?

```py
def thing(seq=[]):
	seq.append("Hello")
    print(seq)
    
thing()  # Displays ["Hello"]
thing()  # Displays ["Hello", "Hello"] ?!
```

The default values of function arguments in Python are... evaluated once, when the function is declared, and are therefore mutable and shared through function calls. Basically, Python has `static` local variables. This is perhaps the most famous violation of the PLA in Python, and has been the source of [many](https://stackoverflow.com/questions/1132941/least-astonishment-and-the-mutable-default-argument) [StackOverflow](https://stackoverflow.com/questions/73765587/how-to-get-a-warning-about-a-list-being-a-mutable-default-argument) [posts](https://stackoverflow.com/questions/73609881/why-default-arguments-value-is-mutable-if-param-initiated-by-call) through the years.

The lack of block scoping is a plentiful source of PLA violations, especially for programmers customary of block-scoped programming languages. Not having to declare variables is easy to get right, but having to remember that it means that you can accidentally overwrite outer-scope variables is harder.

Friends, this is block scoping for Python:

```py
import sys

import ctypes

def calling_scope():
	return sys._getframe(2)

def update(frame):
	ctypes.pythonapi.PyFrame_LocalsToFast(ctypes.py_object(frame), ctypes.c_int(0))

class var:
	def __init__(self, **kwargs):
		self.vars = kwargs
		self.backup = {}

	def __enter__(self):
		scope = calling_scope()
		for name, val in self.vars.items():
			if orig := scope.f_locals.get(name):
				self.backup[name] = orig
			scope.f_locals[name] = val
		update(scope)
		return self

	def __exit__(self, *args):
		scope = calling_scope()
		for name in self.vars:
			if old := self.backup.get(name):
				scope.f_locals[name] = old
			else:
				del scope.f_locals[name]
		update(scope)

def f():
	b = 5
	print(locals())
	with var(a=5, b=6):
		print(locals())
		with var(c=7):
			print(locals())
		print(locals())
	print(locals())

f()
```

Here's the output:‌

```py
{'b': 5}
{'b': 6, 'a': 5}
{'b': 6, 'a': 5, 'c': 7}
{'b': 6, 'a': 5}
{'b': 5}
```

Python's really dynamic, and we can access internal things such as the contents of the call stack using weird things like `sys._getframe`.

> This is illegal in 140 countries.
{: .prompt-tip }

The above code is in the public domain, though I would recommend firing anyone who would use it in production code.

I'm not the first to stumble upon this trick, there's actually [a Python package](https://pypi.org/project/scoping/) that does pretty much the same thing, with the added functionality of automatically detecting variables, so you can declare variables as you normally do instead of passing them in the `with` statement.
