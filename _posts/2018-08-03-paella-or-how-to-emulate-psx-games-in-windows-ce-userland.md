---
title: Paella, or how to emulate PSX games in Windows CE userland
#img_path: '/assets/posts/2018-08-03-paella-or-how-to-emulate-psx-games-in-windows-ce-userland/'
slug: paella-or-how-to-emulate-psx-games-in-windows-ce-userland
date_published: 2018-08-03T16:19:50.000Z
date_updated: 2021-10-03T16:19:50.000Z
tags: [TOMB5, Programming, PSX development]
---

Lately, I've been [decompiling Tomb Raider 5](https://github.com/TOMB5/TOMB5) with some friends and while researching potential sources of debug informations that could help the process, I stumbled upon the Pocket PC version of Tomb Raider 1. It was ported by Ideaworks3D, a London-based game development company specialized in porting.

It's supposed to run on low-performance handheld devices running Windows Mobile/CE 5.0 and thus one would imagine that they have simply taken the Windows code and tweaked it a little bit to make it run on CE. Well as I discovered, it's more complicated than that. First, there is no Windows version of TR1, it was only released for DOS and was never ported to either Win16 or Win32. Second, they actually didn't take the PC version as a base, but the PSX version.

It may seem weird, why take the PSX version if your product is going to run on Windows CE. As it appears, Ideaworks3D seems to have developed an in-house reimplementation of the PSX's "userland" (APIs), and uses it when porting games to CE. In other words, they compile the PSX codebase to ARM code and link that binary against a library called "Paella" (`iepaella.dll`) which contains implementations of PSX syscalls (used for drawing, audio, etc.) that in turn call the WinCE APIs (DirectX, ...). Apparently, they have also made a version of that DLL which runs on standard Win32 that they used to make an ActiveX port of their Pocket PC port of the PSX version. It allowed playing TR1 in Internet Explorer. Not sure why anyone would ever do that, though.

I find this quite interesting because the main game executable seems to have a code near-identical to the original PSX version, which means that "IEPaella" is effectively a full-featured userland PSX emulator for WinCE and Win32 that is capable of mapping the PSX system routines to DirectX API calls. I haven't been able to find any other similar product on the internet. The only software that could be considered similar is [Usercorn](https://github.com/lunixbochs/usercorn), a userland emulator based on [Unicorn](https://github.com/unicorn-engine/unicorn) which implements most of the Linux, BSD and Darwin syscalls and even some DOS interrupts. It's very basic though, nowhere near what Paella does.

More info on Ideaworks3D and Paella [here](https://needforspeedtheories.boards.net/thread/2433/nfsug2-nfsmw-mobile-brew-versions).

---

Currently, the codebase of the decompilation project is divided in 3 main folders:

*   `GAME` contains the shared game code
*   `SPEC_PSX` contains the PSX platform code
*   `SPEC_PC` contains the PC platform code

Debugging on PSX is much harder than on PC, because the binary is run in an emulator and you can't just run the code step-by-step to see where it crashes. Using Paella would allow doing such a thing because the binary is effectively being run on the computer and works like any other C++ program. We're currently search for ways to implement Paella support in TOMB5, but it may take time because not all PSX syscalls are implemented. It will eventually work, though.
