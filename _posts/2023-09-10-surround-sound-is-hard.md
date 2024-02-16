---
title: Surround sound is hard
tags: [Hardware, Programming, Dark magic]
category: "Long posts"
image: 81GHq5UPjYL_pixian_ai.png
cover_hide: true
---

I own a **Logitech Z506** 5.1 audio system. I bought it in 2014 and it's been doing its job just fine since then. It looks like this:

![Logitech Z506](81GHq5UPjYL_pixian_ai.png)

Audio is easy. It's just an analog signal you transmit over a wire and you get sound. Too simple to mess up. Right?

Most PC audio devices use the evergreen, time-tested **3.5mm jack**. It's used for almost all headphones, speakers, and microphones. Modern desktop motherboards following the HD Audio standard usually have six of them:

![HD Audio](hdaudio_Plan de travail 1.svg)

For a 5.1 setup like I have, the connectors that will be used are green (front), orange (center/subwoofer), and black (rear). This is exactly what we find at the back of the Z506's subwoofer/amp: 

![Image from the Z506 user manual](z506_ports.png)
<label>(the image is from the [user manual](https://www.logitech.com/assets/33015/z506620-002649005326gsamr.pdf), and, yes, the "AUDIO IN" text was broken in the original file)</label>

However, the TV world does things differently. 

The same way for a long time PCs used PC-specific connectors like VGA or DVI for display, while the TV world used S-Video, SCART or composite, PCs have been using 3.5mm for decades while the TV world has been using... well, lots of different things. RCA was used a lot in the olden days, then there was the TOSLINK (commonly called S/PDIF or just "optical") connector that was supposed to fix everything, then at the same time 3.5mm was used to be compatible with regular audio devices like headphones, and then HDMI came along and was supposed to fix everything again. It actually did fix things a bit, since PCs started using it because it was better than everything that we had before (though not perfect, hence DisplayPort) and we magically started being able to use TVs with PCs without having to use adapters or VGA cables.

Long story short, if you want to get 5.1/7.1 sound from a "TV world" device (like a TV or an Android box), the "happy path" is to buy a multi-$100 surround sound amplifier, plug every device you own into its HDMI inputs, plug its HDMI output to your TV, and plug your speakers (which must be the expensive ones with raw wires and whatnot) to the amp.

There is no easy way to go from a "TV world" audio stream played on a "TV world" device to three 3.5mm connectors so you can use a "PC world" 5.1/7.1 sound system with it.

— Surely, there must be one?, might you say with a quizzical tone that would be quite understandable given how anything and everything can be converted in the PC world nowadays.

Think about it. There's an audio stream coming from your Android box. The usual way to do things is to output audio through the HDMI output, forward it to your TV, then get the audio from the TV's output. But your TV doesn't have three 3.5mm outputs for surround sound. At best, it'll have one, for headphones. The only surround-compatible audio output your TV may have is S/PDIF. And even then, most TVs can't forward surround sound from an external HDMI device to the S/PDIF output. But what if your TV can? Well, then, you have to convert that S/PDIF signal to the three 3.5mm connectors. "Just buy a converter on Amazon!" should be the correct answer, but surround audio is complicated, and codecs are complicated, and all those $30-50 S/PDIF-to-3.5mm adapters on Amazon are either half-functional or completely broken. Sometimes they swap channels, and many codecs are unsupported so you just don't get sound at all.

What about HDMI ARC? Well, you need your audio system to support it. What about plugging the S/PDIF cable to the audio system? Well, you need your audio system to support it (the Z906 has an optical input, but the Z506 doesn't).

It's never-ending.

I found a half-working solution: I bought a USB sound card on Amazon and plugged it to my Android box. Working, because, well, the surround sound works. Half, because sometimes it doesn't work. The Plex app refuses to output surround sound with it sometimes so I'm stuck with stereo. But, hey, still better than the converters that just stopped working when they decided it wasn't their day.

At that point, I was starting to get mad that such a simple problem was so hard to solve without throwing hundreds of euros at it.

Then I realized: the USB sound card has an S/PDIF input. What if I used something more... flexible than a converter, to do the conversion? Behold: [spdif-decoder](https://github.com/morningstar1/spdif-decoder). Exactly what I'm looking for: listen for a stream from an S/PDIF input, and output it to the regular 3.5mm surround outputs.

I set it up on my home server, modified it a bit to use the latest libffmpeg version, and fixed some crashing bugs, and it worked! Well, almost. I couldn't change the volume, since my Android box wasn't able to do that when outputting audio through the optical output. So I made a cute little GUI:

![Screenshot of my GUI running in Chrome on Android](Screenshot_20230804-173029.jpg){: style="max-height: 50em" }

About a hundred lines of Python for that (40 of which are for the PWA support) using the Nicegui library, and I've got myself an app that runs like a native app on my phone (since it's a PWA) that allows me to change the volume of the soundcard on the server.

Here's the simplified bulk of the GUI code:

```python
with ui.column().classes(add="w-full").style(add="height: 100vh"):
    with ui.row():
        ui.label('Volume serveur')
        ui.button('🔄', on_click=lambda: restart_service())
    lbl_vol = ui.label('0%')
    sld_vol = ui.slider(min=0, max=100, value=0, on_change=lambda args: set_volume(args.value))
    with ui.grid(rows=3).classes(add="w-full").style(add="flex-grow: 1"):
        ui.button('🔊', on_click=lambda: set_volume(get_volume() + 7)).classes(add="big")
        ui.button('🔉', on_click=lambda: set_volume(get_volume() - 7)).classes(add="big")
        btn_mute = ui.button("🔇", on_click=lambda: toggle_mute()).classes(add="big")

ui.run(port=8765, show=False)
```

The full code is available [here](https://gist.github.com/zdimension/2b193e5d1ba403aa1ad1f570becd5399).

Everything works! Well, not everything. I needed to write a small script that ping-checks my Android box, because if it's turned off, the decoder starts decoding random noise from the S/PDIF input and destroys my ears, so the script turns off the decoder if the box stops responding to pings. And sometimes, it doesn't work, and I have to restart the service (so I put a "restart" button on the remote). And sometimes, it crashes (with E-AC3 streams mostly). And when I switch from stereo stream (like, the Android UI) to a surround stream (like, a movie), there's a small, but noticeable noise.

I used that for a few weeks. Then I bought a new Android box (Nokia Streaming Box 8000) because the old one (Xiaomi Mi Box S) was becoming unuseable (didn't like my 4K TV for some reason, switched to 720p by itself all the time). I tried plugging the USB sound card to the box directly like before, and now everything works perfectly with all codecs, so I retired my cobbled-together remote control thingy. 

Now it works.