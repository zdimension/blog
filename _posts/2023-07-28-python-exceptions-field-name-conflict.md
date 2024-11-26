---
title: Be careful when naming fields in your Python exceptions
#img_path: '/assets/posts/2023-07-28-python-exceptions-field-name-conflict/'
slug: python-exceptions-field-name-conflict
date_published: 2023-07-28T13:37:31.000Z
date_updated: 2023-07-28T13:40:28.000Z
tags: [Programming, Ramblings]
description: "tl;dr: Python exceptions reserve the field \"args\" for internal magic. Don't name your field \"args\"."
---

## The Problem

Here's a Python dataclass:

```py
@dataclass
class InvalidCallError:
	function: str
    args: list
```

Nothing unusual in sight. We want it to be a real, raisable exception, so it needs to inherit `Exception` (technically, `BaseException`, but anyway):

```py
class InvalidCallError(Exception):
```

Now, let's try to raise such an exception:

```py
raise InvalidCallError("foo", [1, 2, 3])
```

Since this is a dataclass, we would expect it to display something along the lines of `InvalidCallError("foo", [1, 2, 3])`, but instead, we get this:

```
Traceback (most recent call last):
  File "/app/output.s", line 8, in <module>
    raise InvalidCallError("foo", [1, 2, 3])
InvalidCallError: (1, 2, 3)
```

`foo` was lost in the process! What happened?

Let's look at a variant:

```py
@dataclass
class ArgList:
	args: list
    kwargs: dict
    
@dataclass
class InvalidCallError(Exception):
	function: str
    args: ArgList
```

Let's throw it:

```py
raise InvalidCallError("foo", ArgList([1, 2, 3], {"a": 4, "b": 5}))
```

Now it's even more cryptic:

```
Traceback (most recent call last):
  File "/app/output.s", line 13, in <module>
    raise InvalidCallError("foo", ArgList([1, 2, 3], {"a": 4, "b": 5}))
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "<string>", line 4, in __init__
TypeError: 'ArgList' object is not iterable
```

Something's being thrown in the file... `<string>`? At line 4? In `__init__`? What `__init__`?

If you try to debug this, you won't even be able to see the frame where the exception was thrown.

## What's happening here?

`BaseException` is a special class in Python, with the bulk of its methods implemented in C. The exact code we're looking for is its [constructor](https://github.com/python/cpython/blob/2aaa83d5f5c7b025f4bf2e04836139eb01a33bd8/Objects/exceptions.c#L76). When a `BaseException` object is constructed, the arguments passed to the constructor are stored in the `args` field. This is indeed what the [docs](https://github.com/python/cpython/blob/2aaa83d5f5c7b025f4bf2e04836139eb01a33bd8/Objects/exceptions.c#L76) say about it. However, what's unclear is that this means you can't easily have a custom exception type with a field named `args`.

The second traceback we've seen, with the `is not iterable` error, is simply due to some code somewhere assuming the exception has an `args` field containing the list of its arguments.

It took me some time to track down the exact origin of the bug, but I couldn't find anything online that warns people not to use the name `args` for a field in a custom exception.
