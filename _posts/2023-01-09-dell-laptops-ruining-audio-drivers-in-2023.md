---
title: Dell laptops, ruining audio drivers in 2023
slug: dell-laptops-ruining-audio-drivers-in-2023
date_published: 2023-01-09T07:42:09.000Z
date_updated: 2023-01-18T06:37:29.000Z
tags: [Ramblings, Hardware]
excerpt: "My Dell laptop's audio drivers hog my CPU (WavesSysSvc.exe) and break my headphone jack. Here's how to fix it by restoring the basic HDA drivers."
---

This is a "rant + fix" blog post. If you're looking for an _interesting_ post, check out the other ones.

I own a Dell Latitude 3420. It works well, has good battery life, good keyboard, and lots of connectors (laptops today, ugh). I got the 1366x768 version though, so I bought a replacement 1080p display because 768p is... small.

Anyway.

From the beginning, there was a process constantly hogging up the CPU, idling at 25-30% usage, all the time. AC or battery, High Performance or High Efficiency mode, it was there. "WavesSysSvc":

![WavesSysSvc Service Application](image.png){: width="314" height="46"}

I looked around and found that it was part of the audio driver. Why the hell would my audio driver take up a third of my computing power?!

Additionally, the headphone jack would just... refuse to work. The only way to get it to work was to have my headphones/speakers plugged in when the computer started, but that's not viable, so for all intents and purposes it was broken.

I searched, browsed the Dell forums, saw that a _lot_ of people were having that same problem, with no answer from Dell apart from "try updating your drivers using SupportAssist" (my drivers were up to date).

## In my case

Then, stumbled onto [this](https://www.dell.com/community/Inspiron/WavesMaxxAudio-is-using-CRAZY-CPU-percentage-contantly/m-p/8166613/highlight/true#M140943) answer. It was a series of instructions in a blurry JPEG, so definitely looked more trustworthy than whatever Dell could tell me. For reference, here are the steps:

1.  Open the Device Manager (either Win+X then "Device Manager", or Win+R then `devmgmt.msc`)
2.  Find the "Realtek Audio" device:  
    ![Device Manager showing the "Realtek Audio" line selected](mmc_xZSOg6t4aj.png)
3.  Right-click, then "Update driver"  
    ![Context menu with the "Update driver" item selected](chrome_fAOs2ccgmc.png)
4.  Choose "Browse my computer"  
    ![Driver update window showing "Browse my computer" item highlighted](mmc_GE3o8Hcquj.png)
5.  Choose "Let me pick from a list"  
    ![Driver update window showing "Let me pick from a list" item highlighted](mmc_UeVQEN6o79.png)
6.  Uncheck "Show compatible hardware"  
    ![Hardware selection page with "Show compatible hardware" checkbox highlighted](mmc_uL3ZnrELN2.png)
7.  Choose "Realtek High Definition Audio"  
    ![Hardware list with "Realtek High Definition Audio" selected"](mmc_jjuFqaNIOd.png)
8.  Click "Next" and confirm any subsequent dialog boxes.

My audio now works perfectly, with no CPU usage at all, and the headphone jack works as well!

Note that this can be reverted by Windows Update, so if the issue comes back, just follow those same steps.

## If you don't have the "Realtek High Definition Audio" entry

Download the Realtek driver from [here](https://www.touslesdrivers.com/index.php?v_page=23&v_code=57969), install it (you may have to reboot multiple times during the installation).
