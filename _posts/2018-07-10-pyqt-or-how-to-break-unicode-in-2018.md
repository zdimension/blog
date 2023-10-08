---
title: PyQt, or how to break Unicode in 2018
#img_path: '/assets/posts/2018-07-10-pyqt-or-how-to-break-unicode-in-2018/'
slug: pyqt-or-how-to-break-unicode-in-2018
date_published: 2018-07-10T16:18:52.000Z
date_updated: 2022-11-29T22:02:07.000Z
tags: [Programming]
---

For my latest project ([Turing](https://github.com/TuringApp/Turing)), I chose to use PyQt 5 for the GUI because it's what seemed the best to me to allow the whole thing to be cross-platform without much of a hassle. It has done its job quite well for about everything.

After some months of development though, I ran into an issue I was unable to fix : there is a bug, somewhere inbetween `pylupdate5` (that scans code files for lines to translate) and `lrelease` (that compiles .ts files to .qm files) which basically prevents using non-ASCII characters in source strings. You can use them in translated strings, but not in the code files.

Quite strange, since both the code files and the .ts files (which are in XML format) are encoded in UTF-8. Or so I thought.

It seems that `lrelease` assumes that everything is ASCII (well, to be precise, Latin-1) if you don't specify it at each `<message>` element in the file, even though the very first line of the file (the XML header) specifies the encoding, in this case `utf-8`. `pylupdate5` has no problem with that and assumes UTF-8 by default.

The workaround is to add an attribute to each `<message>` element in the .ts file to force `lrelease` to understand that it's UTF-8. Basically, replacing `<message>` by `<message encoding="UTF-8">` everywhere. The problem is that when `pylupdate5` re-saves the file after adding the new lines from the code, it discards the attributes (maybe it assumes that they aren't needed, which is a correct assumption given that it's _a freaking XML file_). Thus, I needed to write a script that is executed between the two calls to make sure that `lrelease` always gets fed a file with the attributes, so that it always parses it correctly.

```python
for ts in glob.iglob('../**/*.ts', recursive=True):
    with open(ts, "r", encoding="utf8") as f:
        orig = f.read()
        
    orig = orig.replace('<message>', '<message encoding="UTF-8">')
    
    with open(ts, "w", encoding="utf8") as f:
        f.write(orig)
```

I don't know if it's a bug on the PyQt side or on the Qt side, but it stills seems quite weird to me that we still encounter this kind of problems in 2018, when every sane piece of software uses UTF-8 by default.

[This article](https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses/) by Joel Spolsky is from 2003, and it seems that back then the basic knowledge of how to correctly use encodings had already been invented, so why are so many programs still unable to use text correctly?
