---
title: Solving bizarre hard drive corruption issues
#img_path: '/assets/posts/2019-02-22-solving-bizarre-hard-drive-corruption-issues/'
slug: solving-bizarre-hard-drive-corruption-issues
date_published: 2019-02-22T17:21:17.000Z
date_updated: 2021-10-03T16:21:17.000Z
---

I've recently encountered some pretty weird problems with my two USB3 external hard drives. Disk disconnecting when opening specific files, and refusing to reconnect on the computer until I plug it into another computer, then it works again, and so on.

Then I started noticing a pattern. The files that trigger the crash are always files that I have opened on another computer with that hard drive, which should give you a clue on what this might be about.

It seems that there's a bug in Windows' drive ejection system, which basically means that if you plug a hard drive on a computer, open a file in any software that _keeps the descriptor open all the time_ (I'm looking at you, IDA Pro), and then eject the drive without closing the software first (which sometimes happens), the file will somehow still be marked as open in the NTFS attributes, and when you'll try to open it on another computer, Windows will _flip out_ and disconnect the hard drive. And until you plug the HDD back on the other computer, it will refuse to read it on the first one, showing as RAW in the management console, even in another OS (I tried Ubuntu and FreeBSD) as long as you stay on that computer. But then, if you do plug it back, then it will magically unlock and it will work again on all computers. This took me about a week to figure out. Hope it'll have helped you figure it out in less time than me.
