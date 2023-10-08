---
title: TOMB5 - Feb'19 status update
#img_path: '/assets/posts/2019-02-20-tomb5-feb19-status-update/'
slug: tomb5-feb19-status-update
date_published: 2019-02-20T17:20:32.000Z
date_updated: 2021-10-03T16:20:32.000Z
tags: [TOMB5]
---

The project has come a long way since June of 2017.

Since the beginning of the project, the codebase has been divided into two separate branches: PC and PSX, which share a common "GAME" folder which contains the platform-independent game logic code.

More progress has been made on the PSX version since a lot of code is plain old MIPS assembly which we haven't had to decompile to C, so the PC version is still lagging behind. Problems with the old DirectX version used by the game (DX5) makes all of this much harder.

Also, debugging the PSX version has always been a pain in the ass because of the need to run it in an emulator (we've used no$psx most of the time).

To solve that problem, we've started working on what we call the Emulator, which is simply put an implementation of the PSY-Q PSX SDK acting as an HLE emulator for the game. That way, we can debug the game directly in VS which is quite appreciable. We simply need to link the game binary against our emulator DLL instead of the standard PSY-Q libs. The emulator is based on SDL for windowing and OpenGL for 3D rendering.

Behold, pics.

![](https://i.imgur.com/rMjEoyX.png)
_Title screen_

![](https://i.imgur.com/TRzugzo.png)
_Secret cutscene menu used for debugging purposes, only reachable through RAM editing_

![](https://i.imgur.com/KbfYQiD.png)
_Internal beta title screen_

![](https://i.imgur.com/6w8lRpf.png)
_Game load screen_

![](https://i.imgur.com/j7Lgqjk.png)
_Level loading screen_

You can [check the code out on GitHub](https://github.com/TOMB5/TOMB5).
