---
title: PlexDLWeb - for want of a Plex Pass
tags: [Programming]
shortname: PlexDLWeb
category: "Projects"
image: home.webp
cover_hide: true
---

## I like Plex

I use Plex to share my media with my friends and family. If you don't know Plex, it's a nifty tool that basically allows you to take a folder containing movies and TV shows, and share it to people as a Netflix-like user-friendly interface, so that people don't have to care about the fact that you're actually hosting the files.

Plex is an **amazing piece of software**. Time isn't free, and Plex Inc. needs money. I paid €120 for the Plex Pass so my friends and family can use my server at its full potential (hardware transcoding, credits skipping, etc., all of those are unavailable on the free version).

## The problem

However, since August 1st, 2022, the server owner having a Plex Pass isn't sufficient for users to be able to download. **Each user** must have the Pass for the download feature to be enabled for them. We're not talking about a complex feature, again, like transcoding or credits detection. Downloading files. I could do that with Apache 20 years ago with a 10-line httpd.conf file.

My users travel. My users take the train, the plane, and go in a number of different places where they don't have a stable connection, and they need to be able to download files for offline viewing. **This is not negociable.** And giving an SFTP access is not acceptable, most of my users are not computer-literate.

## The solution

**PlexDLWeb**. A simple web app that runs alongside Plex and allows logging in with a Plex account and searching for stuff.

![Screenshot of PlexDLWeb open, with "james" in the search box and various movies and episodes shown in the results.](home.png)

Similar tools already exist: (non-exhaustive list)
- [elklein96/plex-dl](https://github.com/elklein96/plex-dl): CLI, Python, requires token, uses base URL and media ID
- [danielhoherd/plexdl](https://github.com/danielhoherd/plexdl): CLI, Node.js, requires username and password, gives URL without downloading, has search
- [codedninja/plexmedia-downloader](https://github.com/codedninja/plexmedia-downloader): CLI, Python, requires username and password or auth cookie, uses media URL
- [Monschichi/plex_downloader](https://github.com/Monschichi/plex_downloader): CLI, Python, requires username and password, uses media name

However, none of those are approachable by the average user, the most important factor being CLI. Most of my users don't know what a terminal is. I wanted something that would be as easy to use as Plex itself.

Hence: a web app.

It uses [NiceGUI](https://github.com/zauberzeug/nicegui) for the UI, and [Python-PlexAPI](https://github.com/pkkid/python-plexapi) to query the Plex server. Authentication is done via OAuth through the Plex server -- this means only authorized Plex users can access the app (since their token is used to query the API). Downloading is done by serving the raw file (the Plex API allows retrieving the full local file path), so the PlexDLWeb service must be executed on the same server as Plex (or at least, on a machine where the media files are accessible under the same path).

Code (GPLv3) is available [here](https://github.com/zdimension/plexdlweb). Full installation instructions are provided (standalone & Systemd service).