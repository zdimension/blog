---
title: Fix for the Psy-Q Saturn SDK
#img_path: '/assets/posts/2019-02-23-fix-for-the-psy-q-saturn-sdk/'
slug: fix-for-the-psy-q-saturn-sdk
date_published: 2019-02-23T17:23:22.000Z
date_updated: 2022-06-06T09:42:16.000Z
tags: [TOMB5, PSX development, Programming]
---

If you ever want to write code for the Sega Saturn using the Psy-Q SDK ([available here](https://antime.kapsi.fi/sega/files/psy-q.zip)), you may encounter a small problem with the toolset when using `#include` directives.

Example:

```c
#include "abc.h"

int main()
{
    int b = a + 43;
    return 0;
}
```
{: file="main.c" }

```batchfile
C:\Psyq\bin>ccsh -ITHING/ -S main.c
```
{: file="build.bat" }

```c
int a = 98;
```
{: file="abc.h" }

This will crash with the following error: `main.c:1: abc.h: No such file or directory`, which is quite strange given that we explicitly told the compiler to look in that `THING` folder.

What we have:

*   `CCSH.EXE`: main compiler executable (**C** **C**ompiler **S**uper-**H**)
*   `CPPSH.EXE`: preprocessor (**C** **P**re**P**rocessor **S**uper-**H**)

`CCSH` calls `CPPSH` with the source file first to get a raw code file to compile, and then actually compiles it. Here, we can see by running `CPPSH` alone that it still triggers the error, which means the problem effectively comes from `CPPSH`. After a thorough analysis in Ida, it seems that even though the code that handles parsing the command-line parameters related to include directories, those paths aren't actually added to the program's internal directory array and thus never actually used. I could have decompiled it and fixed it myself, but I found a faster and simpler way: use the PSX one.

Though `CCSH` and `CCPSX` are very different in nature (one compiles for Super-H and one for MIPS), their preprocessors are actually almost identical — when we think about it, it makes sense: the C language doesn't depend on the underlying architecture (most of the time), so why would its preprocessor do?

So here's the fix: rename `CCSH` to something else and copy `CCPSX` to `CCSH`. Solves all problems and finally allows compiling C code for the Sega Saturn on Windows (the only other working SDK on the Internet is for DOS, which requires using DOSBox and 8.3 filenames, which makes big projects complicated to organize).

That's nice and all but can we compile actual code? Seems that the answer is no. Here is a basic file:

```c
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

int main()
{
	printf("%d\n", 42);

	return 0;
}
```

Compiling this will give the following error:

    In file included from bin/main.c:2:
    D:\SATURN\INCLUDE\stdlib.h:7: conflicting types for 'size_t'
    D:\SATURN\INCLUDE\stddef.h:166: previous declaration of 'size_t'

Weird, eh?

It seems that the `STDLIB.H` file in the SDK is somehow wrong, in that it has the following at the top:

```c
#ifndef	__SIZE_TYPE__DEF
#define	__SIZE_TYPE__DEF	unsigned int
typedef	__SIZE_TYPE__DEF	size_t;
#endif
```
{: file="STDLIB.H" }

Whereas its friend `STDDEF.H` looks like this:

```c
#ifndef __SIZE_TYPE__
#define __SIZE_TYPE__ long unsigned int
#endif
#if !(defined (__GNUG__) && defined (size_t))
typedef __SIZE_TYPE__ size_t;
#endif /* !(defined (__GNUG__) && defined (size_t)) */
```
{: file="STDDEF.H" }

Two incompatible declarations, the compiler dies. The simple fix is to remove the `DEF` at the end of the names in `STDLIB.H`, to get something like this:

```c
#ifndef	__SIZE_TYPE__
#define	__SIZE_TYPE__	unsigned int
typedef	__SIZE_TYPE__	size_t;
#endif
```
{: file="STDLIB.H" }
