---
title: "Crabs All the Way Down: Running Rust on Logic Gates"
#img_path: '/assets/posts/2022-08-17-crabs-all-the-way-down/'
date_published: 2022-08-17T15:47:22.000Z
date_updated: 2023-01-07T23:30:11.000Z
tags: [Programming, Hardware, Rust]
excerpt: "A journey in building an ARM CPU from scratch in a digital circuit simulator, and running Rust on it to interpret Scheme and serve Web pages."
math: true
image: javaw_zD3bVnBuYi-2.png
category: "Long posts"
---

<style>.instr_encoding td { text-align: center; padding: 0; } table.instr_encoding { table-layout: fixed; font-size: 80%; }</style>> This article will discuss many topics, from CPU architecture design to historical shenanigans. Take a drink, it's downhill from there.
{: .prompt-tip }

Even though the number has steadily decreased since the 90s, there are still many different and incompatible CPU architectures in use nowadays. Most computers use x86\_64 and pretty much all mobile devices and recent Macs use some kind of ARM64-based ISA (instruction set architecture).

In specific fields, though, there are more exotic ones: most routers still use MIPS (for historical reasons), a roomful of developers use RISC-V, the PS3 used PowerPC, some servers 20 years ago used Itanium, and of course IBM still sells their S/390-based mainframes (now rebranded as z/Architecture). The embedded world has even more: AVR (used in Arduino), SuperH (Saturn, Dreamcast, Casio 9860 calculators), and the venerable 8051, an Intel chip from 1980 which is still being produced, sold and even extended by third parties.

All these architectures differ on their defining characteristics, the main ones being:

*   **word size**: 8, 16, 31, 32, 64 bits, sometimes more
*   **design style**: RISC (few instructions, simple operations), CISC (many instructions, performing complex operations, VLIW (long instructions, doing many things at once in parallel)
*   **memory architecture**: Harvard (separate code memory and data memory), von Neumann (shared)
*   **licensing costs**: RISC-V is open and free to use, whereas x86 and ARM, for example, require licensing fees
*   broadly, their **feature set**: floating-point numbers (x87), encryption (AES-NI), support for native high-level bytecode execution (Jazelle, AVR32B), vectorized computation (SSE, AVX, AltiVec)

> That's not even counting DSP architectures, which are, to put it lightly, the ISA counterpart to the Twilight Zone (supporting weird arithmetic operations, peculiar data sizes, etc).
{: .prompt-tip }

A lot of people have built homemade CPUs, either on [real breadboards](https://eater.net/8bit/) or in software, for [emulators](https://bellard.org/jslinux/) or [circuit synthesis](https://github.com/darklife/darkriscv). It's a very interesting project to do, even for beginners (really, check out Ben Eater's video series), because it really helps grasp how code translates to the electrical signals that power every device we use, and how complex language features can really be implemented on top of simple operations.

## Making a CPU

A number of circumstances have led me to design a simple _ARM-ish_ CPU in a digital circuit simulator. I originally used [logisim-evolution](https://github.com/logisim-evolution/logisim-evolution) (of which I have since become a member of the development team), and recently migrated the circuit to [Digital](https://github.com/hneemann/Digital), for performance reasons (Logisim couldn't simulate my circuit at more than 50 or 60 Hz, whereas Digital reaches 20 kHz).

_ARM_, because it supports a subset of the [ARM Thumb instruction set](http://bear.ces.cwru.edu/eecs_382/ARM7-TDMI-manual-pt3.pdf), which itself is one of the multiple instruction sets supported by ARM CPUs. It uses 32-bit words, but the instruction are 16 bits wide.

_\-ish_, because, well, it only supports a subset of it (big, but nowhere near complete), and is deliberately limited in some aspects. [Weird](https://developer.arm.com/documentation/ddi0406/c/Application-Level-Architecture/Thumb-Instruction-Set-Encoding/16-bit-Thumb-instruction-encoding/Miscellaneous-16-bit-instructions?lang=en) instructions, such as the `PUSH` / `POP` / `LDM` / `STM` family (one of the big CISC ink blots in the RISC ARM ISA), are not supported and are implemented as manual load/stores by the assembler. Interrupts are not supported either.

Pedantically, I didn't design only a CPU but what one could call a computer; it has a ROM, a RAM, and various devices that serve as the "front panel".

* * *

### Quick sidenote: devices

To be really useful, a computer will not _only_ have a CPU and a memory chip. It'll also have peripherals and other items plugged into it: a keyboard, a screen, a disk drive, speakers, a network card; pretty much [anything](https://www.gigabyte.com/hr/Press/News/404) [you](https://twitter.com/zdimension_/status/1505585954383355907) [can](https://twitter.com/foone/status/1219761584655880193) (or [can't](https://twitter.com/Foone/status/1546179997445943296)) imagine has already been made into a computer device.

At the end of the day, the only thing you need is to be able to transmit data to and from the device. There are two opposite ways to do this: either devices are ✨special✨, either they aren't.

Basically, some architectures (x86, I'm looking at you) have, in addition to the memory, a special, separate address space for I/O, with its own special, different instructions: [on an 8086](https://wiki.osdev.org/I/O_Ports), you'd use `MOV` to read and write main memory, and `IN` / `OUT` to read and write to a device. Some devices (the most important ones: PS/2 controller, floppy disk, serial port, ...) have a fixed port number, other have a port number assigned at boot by the BIOS. In the olden days, it was common practice to require setting environment variables or writing config files to inform software of which devices were plugged were (e.g. the famous [BLASTER](https://dos.fandom.com/wiki/BLASTER_Variable) config line). This is called PMIO (port-mapped input/output).

The other option, the one used by pretty much everybody else, including modern x86 computers, is to have a single unified address space, but to make it _virtual_.

> I'm using the word **virtual** here to differentiate this unified address space from the real physical memory address space (which, in itself, only really means anything on machines with a single memory unit). There's another concept called **virtual memory** that designates a completely unrelated (though similar in fashion) thing: providing programs with an address space larger than the computer's RAM through the use of strategies like swapping that allow moving RAM pages to the disk storage to free space in the working memory, and most importantly isolating programs running on the same computer.
{: .prompt-tip }

Imagine how IP addresses are supposed to map the entire Internet, but in reality an address does not have to exactly map to a single machine somewhere. For example, `127.0.0.1` (`::1` in IPv6) is the local loopback, and maps to the machine you're using. This is not required to be known by software communicating over the network, since the mapping is done by the network stack of the OS.

It's the same here: areas of the (virtual) address space are mapped to physical components. To give you a real-world example, here's the NES's address space:

![address space diagram, showing WRAM, PPU & APU registers, cartridge RAM and ROM](image.png){: width="671" height="172"}
_image from https://jarrettbillingsley.github.io/_

How to read: addresses from 0 to 800 (hexadecimal) are mapped to WRAM (work RAM), from 2000 to 2008 to the PPU (graphics card) control registers, from 4000 to 4018 to the APU (sound card), I trust you can take it from there. This is called MMIO (memory-mapped input/output).

The big advantage of this approach, for me, is really its simplicity, CPU-wise: it's just memory! Take the address of the device's area, read, write, it's really simple. It also makes things easier software-wise: you don't have to write inline assembly to call special instructions; as long as you can read and write from pointers, you're good to go.

In addition to this, memory mapping can also be used to provide access to different memory chips (e.g. ROM and RAM). Here's what it looks like for my circuit:

<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="-0.5 -0.5 480 272" style="width: 100%; height: auto" id="bus"><style>html:not([data-mode="light"]) body #bus rect { fill: rgba(124,139,154,.13); stroke-width: 0; } #bus path { stroke: var(--text-color); } </style><defs></defs><g><path d="M 128.17 236.22 L 151.03 236.21 L 151.03 156.97 L 294.63 157" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"></path><path d="M 122.92 236.22 L 129.92 232.72 L 128.17 236.22 L 129.92 239.72 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><path d="M 299.88 157 L 292.88 160.5 L 294.63 157 L 292.88 153.5 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><g transform="translate(-0.5 -0.5)"><text x="220" y="153" fill="rgb(0, 0, 0)" font-size="11px" text-anchor="middle" class="mono">FFFFFF00 - FFFFFFFF</text></g><rect x="0" y="210" width="120" height="60" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"></rect><g transform="translate(-0.5 -0.5)"><text x="60" y="244" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">MMIO controller</text></g><path d="M 126.37 100 L 141.03 100 L 141.03 125.03 L 294.63 125.03" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"></path><path d="M 121.12 100 L 128.12 96.5 L 126.37 100 L 128.12 103.5 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><path d="M 299.88 125.03 L 292.88 128.53 L 294.63 125.03 L 292.88 121.53 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><g transform="translate(-0.5 -0.5)"><text x="220" y="121" fill="rgb(0, 0, 0)" font-size="11px" text-anchor="middle" class="mono">00100000 - 001FFFFF</text></g><rect x="0" y="70" width="120" height="60" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"></rect><g transform="translate(-0.5 -0.5)"><text x="60" y="104" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">RAM</text></g><path d="M 120 30 L 151.03 30 L 151.03 110 L 295.35 110.02" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"></path><path d="M 300.6 110.02 L 293.6 113.52 L 295.35 110.02 L 293.6 106.52 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><g transform="translate(-0.5 -0.5)"><text x="220" y="105" fill="rgb(0, 0, 0)" font-size="11px" text-anchor="middle" class="mono">00000000 - 0000FFFF</text></g><rect x="0" y="0" width="120" height="60" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"></rect><g transform="translate(-0.5 -0.5)"><text x="60" y="34" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">ROM</text></g><path d="M 126.37 170 L 141.03 170 L 141.03 140 L 301 140" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"></path><path d="M 121.12 170 L 128.12 166.5 L 126.37 170 L 128.12 173.5 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><g transform="translate(-0.5 -0.5)"><text x="220" y="136" fill="rgb(0, 0, 0)" font-size="11px" text-anchor="middle" class="mono">01000000 - 010FFFFF</text></g><rect x="0" y="140" width="120" height="60" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"></rect><g transform="translate(-0.5 -0.5)"><text x="60" y="174" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">Video display</text></g><path d="M 427.37 115 L 471.03 115.03" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"></path><path d="M 422.12 115 L 429.12 111.51 L 427.37 115 L 429.12 118.51 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><path d="M 421 145 L 464.67 145.03" fill="none" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="stroke"></path><path d="M 469.92 145.03 L 462.91 148.53 L 464.67 145.03 L 462.92 141.53 Z" fill="rgb(0, 0, 0)" stroke="rgb(0, 0, 0)" stroke-miterlimit="10" pointer-events="all"></path><rect x="301" y="100" width="120" height="60" fill="rgb(255, 255, 255)" stroke="rgb(0, 0, 0)" pointer-events="all"></rect><g transform="translate(-0.5 -0.5)"><text x="361" y="134" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">Memory mapper</text></g><g transform="translate(-0.5 -0.5)"><text x="450" y="131" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">Write</text></g><g transform="translate(-0.5 -0.5)"><text x="450" y="164" fill="rgb(0, 0, 0)" font-size="12px" text-anchor="middle">Read</text></g></g></svg>

Notice the arrows on each side of the edges between the components and the mapper; they indicate whether the component is read-only, read/write or write-only.

* * *

### The CPU

It's simple, really. I mean, compared to _real_ CPUs.

As in real Thumb, there are sixteen 32-bit registers, numbered `r0` through `r15`. The last three have nicknames: `r13` is `sp` (stack pointer), `r14` is `lr` (link register) and `r15` is `pc` (program counter).

* * *

### Quick sidenote: stack pointer

Memory is hard. I'll talk about it later.

* * *

16 is a lot; so in reality they're divided into the low (`r0`\-`r7`)  and high (`r8`\-`r15`) registers. High registers can only be manipulated using specific instructions, so the low ones are the ones you're gonna use in everyday life.

Instructions are grouped into several categories, each containing instructions with a common header. I won't list them all here, but the most used ones are the ALU (arithmetic and logic) operations, the load/store instructions (relative to `pc`, to `sp`, or to a general register), the stack manipulation instructions and the branch instructions (conditional and unconditional).

Instruction groups are handled by separate, independent subcircuits, that all write into shared buses.

* * *

### Quick sidenote: buses

> **Bus** is a surprisingly polysemic word. It has definitions in more domains than I can count, and even in electronics and hardware it's used for a variety of things. The common factor between all those definitions is "thing that links other things".  
> As in previous parts, I will be simplifying the explanation anyway, because electronics is a vast field of study.
{: .prompt-tip }

In circuit design parlance, a bus is a group of wires connected together. Specifically, in this case, it's a group of wires where only one wire emits a signal at a given instant. Electrically, this is permitted by the use of what's called tri-state logic: a signal is either 0, 1 or Z (pronounced "high-impedance"). Z is "weak", in the sense that if you connect a Z signal with a 0 or 1 signal, the output will be that of the second signal. This is useful: you can have lots of independent components, each with an "enable" input, that only output a signal if they are enabled, and otherwise output Z. The basic component used for this is called, fittingly, a tri-state buffer. It's a simple logic gate that, if enabled, outputs its input unchanged, and otherwise outputs Z.

All these components can then be plugged together, and you can enable one and get its output easily.

* * *

### Component example: load/store with register offset

This is the component that handles instructions of the form `{direction}R{sign}{mode} {destination}, [{base}, {offset}]`, with:

*   `{direction}`: either `LD` (load) or `ST` (store)
*   `{sign}`: either nothing (do not extend), or `S` (sign-extend the value to fill 32 bits)
*   `{mode}`: either nothing (full word, 32 bits), `H` (halfword, 16 bits) or `B` (byte, 8 bits)
*   `{destination}`: the target register, to read from/write to
*   `{base}`, `{offset}`: the address in memory (which will be the sum of the values of both)

As an example, `ldrh r1, [r2, r3]` is roughly equivalent to `r1 = *(short*)(r2 + r3)` in C code.

The instructions for this group are encoded as follows:

<table class="instr_encoding"><tbody><tr><td>15</td><td>14</td><td>13</td><td>12</td><td>11</td><td>10</td><td>9</td><td>8</td><td>7</td><td>6</td><td>5</td><td>4</td><td>3</td><td>2</td><td>1</td><td>0</td></tr><tr><td>0</td><td>1</td><td>0</td><td>1</td><td colspan="3">opcode</td><td colspan="3">Ro</td><td colspan="3">Rb</td><td colspan="3">Rd</td></tr></tbody></table>

`opcode` is a 3-bit value encoding both `{direction}`, `{sign}` and `{mode}`.

> `{direction}` has two possible values (load, store); `{sign}` has two (raw, sign-extended) and `{mode}` has three (word, halfword, byte). That's 2⋅2⋅3 = 12 possible combinations, more than the 23 = 8 possible values for `opcode`, which means that some combinations are not possible.  
> This is because only load operations for incomplete (halfword, byte) values can be sign-extended, so the invalid combinations (`strsh`, `strsb`, `strs`, `ldrs`) are not given an encoding.
{: .prompt-tip }

Here's the circuit:

<svg class="kg-image" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" style="width: 100%; height: auto" viewBox="205 89 771.47251 597.97539" id="svg4220" version="1.1" inkscape:version="0.91 r13725" sodipodi:docname="sub.svg"><metadata id="metadata4810"><rdf:rdf><cc:work rdf:about=""><dc:format>image/svg+xml</dc:format> <dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"></dc:type><dc:title></dc:title></cc:work></rdf:rdf></metadata><style>html:not([data-mode="light"]) body svg .black { stroke: rgb(192, 186, 178) !important; } html:not([data-mode="light"]) body svg .blue { stroke: #505097 !important; } </style><defs id="defs4808"></defs><sodipodi:namedview pagecolor="#ffffff" bordercolor="#666666" borderopacity="1" objecttolerance="10" gridtolerance="10" guidetolerance="10" inkscape:pageopacity="0" inkscape:pageshadow="2" inkscape:window-width="1920" inkscape:window-height="1137" id="namedview4806" showgrid="false" fit-margin-top="0" fit-margin-left="0" fit-margin-right="0" fit-margin-bottom="0" inkscape:zoom="4.2073883" inkscape:cx="146.1287" inkscape:cy="57.939238" inkscape:window-x="-8" inkscape:window-y="-8" inkscape:window-maximized="1" inkscape:current-layer="svg4220"></sodipodi:namedview><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4224" d="m 285.96777,140.44636 10,0 10,0"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4226" d="m 305.96777,180.44636 -10,0"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4228" d="m 305.96777,220.44636 -10,0"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4230" d="m 305.96777,260.44636 -10,0"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4232" d="m 545.96777,160.44636 0,-13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4234" d="m 545.96777,200.44636 0,-13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4236" d="m 545.96777,240.44636 0,-13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4238" d="m 485.96777,360.44636 0,-13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4240" d="m 485.96777,400.44636 0,13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4242" d="m 285.96777,500.44636 10,0 10,0"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4244" d="m 485.96777,620.44636 0,-13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4246" d="m 805.96777,540.44636 0,-13"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4248" d="m 605.96777,500.44636 10,0 10,0"></path><path class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4250" d="m 625.96777,540.44636 -10,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4252" d="m 305.96777,640.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4254" d="m 465.96777,640.44636 20,0 0,-20"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4256" d="m 505.96777,100.44636 0,60 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4258" d="m 305.96777,300.44636 0,20 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4260" d="m 305.96777,580.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4262" d="m 305.96777,260.44636 40,0 0,40"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4264" d="m 305.96777,400.44636 0,20 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4266" d="m 505.96777,420.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4268" d="m 385.96777,380.44636 0,40 80,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4270" d="m 825.96777,520.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4272" d="m 725.96777,520.44636 60,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4274" d="m 305.96777,520.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4276" d="m 505.96777,160.44636 0,40 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4278" d="m 285.96777,360.44636 20,0 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4280" d="m 305.96777,620.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4282" d="m 265.96777,140.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4284" d="m 565.96777,140.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4286" d="m 485.96777,140.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4288" d="m 305.96777,140.44636 120,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4290" d="m 285.96777,300.44636 20,0 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4292" d="m 785.96777,560.44636 20,0 0,-20"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4294" d="m 305.96777,560.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4296" d="m 505.96777,200.44636 0,40 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4298" d="m 305.96777,380.44636 0,20 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4300" d="m 585.96777,500.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4302" d="m 625.96777,500.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4304" d="m 265.96777,500.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4306" d="m 305.96777,500.44636 40,0 0,20"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4308" d="m 305.96777,660.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4310" d="m 565.96777,180.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4312" d="m 485.96777,180.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4314" d="m 305.96777,180.44636 120,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4316" d="m 305.96777,320.44636 0,20 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4318" d="m 505.96777,340.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4320" d="m 445.96777,340.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4322" d="m 305.96777,600.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4324" d="m 505.96777,600.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4326" d="m 365.96777,600.44636 100,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4328" d="m 305.96777,420.44636 0,20 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4330" d="m 625.96777,540.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4332" d="m 305.96777,540.44636 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4334" d="m 565.96777,220.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4336" d="m 485.96777,220.44636 40,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4338" d="m 305.96777,220.44636 120,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4340" d="m 305.96777,360.44636 0,20 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4342" d="m 465.96777,380.44636 20,0 0,-20"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4344" d="m 365.96777,380.44636 20,0 0,-40 20,0"></path><path class="blue" style="fill:none;stroke:#0000b2;stroke-width:4;stroke-linecap:square" inkscape:connector-curvature="0" id="path4346" d="m 485.96777,380.44636 0,20"></path><g style="stroke-linecap:square" id="g4348" transform="translate(5.9677734,0.44635936)"><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4350" r="4" cy="160" cx="500"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4352" r="4" cy="320" cx="300"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4354" r="4" cy="420" cx="300"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4356" r="4" cy="200" cx="500"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4358" r="4" cy="360" cx="300"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4360" r="4" cy="300" cx="300"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4362" r="4" cy="400" cx="300"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4364" r="4" cy="380" cx="300"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4366" r="4" cy="380" cx="480"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4368" r="4" cy="380" cx="380"></circle></g><g style="stroke-linecap:square" id="g4370" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4372" d="m 260,140 -14,-8 0,16 z"></path><text id="text4374" style="font-size:18px;text-anchor:end;fill:#808080" y="146.75" x="241">Instr</text> <circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4376" r="2" cy="140" cx="260"></circle></g><g style="stroke-linecap:square" id="g4378" transform="translate(5.9677734,0.44635936)"><text id="text4380" style="font-size:12px;text-anchor:end;fill:#808080" y="137" x="278">0-15</text> <text id="text4382" style="font-size:12px;text-anchor:start;fill:#808080" y="137" x="302">0-2</text> <text id="text4384" style="font-size:12px;text-anchor:start;fill:#808080" y="177" x="302">3-5</text> <text id="text4386" style="font-size:12px;text-anchor:start;fill:#808080" y="217" x="302">6-8</text> <text id="text4388" style="font-size:12px;text-anchor:start;fill:#808080" y="257" x="302">9-11</text> <path class="black" style="fill:#000000;fill-opacity:1;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4390" d="m 288,138 4,0 0,124 -4,0 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4392" r="2" cy="140" cx="280"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4394" r="2" cy="140" cx="300"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4396" r="2" cy="180" cx="300"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4398" r="2" cy="220" cx="300"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4400" r="2" cy="260" cx="300"></circle></g><g style="stroke-linecap:square" id="g4402" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4404" d="m 600,140 14,8 0,-16 z"></path><text id="text4406" style="font-size:18px;text-anchor:start;fill:#808080" y="146.75" x="619">Reg<tspan id="tspan4408" style="font-size:80.00000119%;baseline-shift:sub">W</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4410" r="2" cy="140" cx="600"></circle></g><path d="m 426.96777,126.44636 58,0 0,28 -58,0 z" id="path4414" inkscape:connector-curvature="0" style="fill:#ffffb4;fill-opacity:0.78431373;stroke:#ffffb4;stroke-width:0;stroke-linecap:square"></path><path d="m 426.96777,126.44636 58,0 0,28 -58,0 z" id="path4416" inkscape:connector-curvature="0" class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square"></path><circle cx="425.96777" cy="140.44637" r="2" id="circle4424" class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4;stroke-linecap:square"></circle><circle cx="485.96777" cy="140.44637" r="2" id="circle4426" style="fill:#b20000;stroke:#b20000;stroke-width:4;stroke-linecap:square"></circle><g style="stroke-linecap:square" id="g4428" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4430" d="m 521,128 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4432" r="2" cy="140" cx="520"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4434" r="2" cy="160" cx="540"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4436" r="2" cy="140" cx="560"></circle></g><g style="stroke-linecap:square" id="g4438" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4440" d="m 600,180 14,8 0,-16 z"></path><text id="text4442" style="font-size:18px;text-anchor:start;fill:#808080" y="186.75" x="619">Reg<tspan id="tspan4444" style="font-size:80.00000119%;baseline-shift:sub">A</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4446" r="2" cy="180" cx="600"></circle></g><path d="m 426.96777,166.44636 58,0 0,28 -58,0 z" id="path4450" inkscape:connector-curvature="0" style="fill:#ffffb4;fill-opacity:0.78431373;stroke:#ffffb4;stroke-width:0;stroke-linecap:square"></path><path d="m 426.96777,166.44636 58,0 0,28 -58,0 z" id="path4452" inkscape:connector-curvature="0" class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square"></path><circle cx="425.96777" cy="180.44637" r="2" id="circle4460" class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4;stroke-linecap:square"></circle><circle cx="485.96777" cy="180.44637" r="2" id="circle4462" style="fill:#b20000;stroke:#b20000;stroke-width:4;stroke-linecap:square"></circle><g style="stroke-linecap:square" id="g4464" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4466" d="m 521,168 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4468" r="2" cy="180" cx="520"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4470" r="2" cy="200" cx="540"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4472" r="2" cy="180" cx="560"></circle></g><g style="stroke-linecap:square" id="g4474" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4476" d="m 600,220 14,8 0,-16 z"></path><text id="text4478" style="font-size:18px;text-anchor:start;fill:#808080" y="226.75" x="619">Reg<tspan id="tspan4480" style="font-size:80.00000119%;baseline-shift:sub">B</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4482" r="2" cy="220" cx="600"></circle></g><path d="m 426.96777,206.44636 58,0 0,28 -58,0 z" id="path4486" inkscape:connector-curvature="0" style="fill:#ffffb4;fill-opacity:0.78431373;stroke:#ffffb4;stroke-width:0;stroke-linecap:square"></path><path d="m 426.96777,206.44636 58,0 0,28 -58,0 z" id="path4488" inkscape:connector-curvature="0" class="black" style="fill:none;stroke:#000000;stroke-width:4;stroke-linecap:square"></path><circle cx="425.96777" cy="220.44637" r="2" id="circle4496" class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4;stroke-linecap:square"></circle><circle cx="485.96777" cy="220.44637" r="2" id="circle4498" style="fill:#b20000;stroke:#b20000;stroke-width:4;stroke-linecap:square"></circle><g style="stroke-linecap:square" id="g4500" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4502" d="m 521,208 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4504" r="2" cy="220" cx="520"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4506" r="2" cy="240" cx="540"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4508" r="2" cy="220" cx="560"></circle></g><g style="stroke-linecap:square" id="g4510" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4512" d="m 500,100 -14,-8 0,16 z"></path><text id="text4514" style="font-size:18px;text-anchor:end;fill:#808080" y="106.75" x="481">Instr<tspan id="tspan4516" style="font-size:80.00000119%;baseline-shift:sub">0708</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4518" r="2" cy="100" cx="500"></circle></g><g style="stroke-linecap:square" id="g4520" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4522" d="m 321,296 38,9 0,150 -38,9 z"></path><text id="text4524" style="font-size:18px;text-anchor:start;fill:#808080" y="315.5" x="323">0</text> <circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4526" r="2" cy="300" cx="340"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4528" r="2" cy="300" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4530" r="2" cy="320" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4532" r="2" cy="340" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4534" r="2" cy="360" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4536" r="2" cy="380" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4538" r="2" cy="400" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4540" r="2" cy="420" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4542" r="2" cy="440" cx="320"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4544" r="2" cy="380" cx="360"></circle></g><g style="stroke-linecap:square" id="g4546" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4548" d="m 460,380 -14,-8 0,16 z"></path><text id="text4550" style="font-size:18px;text-anchor:end;fill:#808080" y="386.75" x="441">Instr<tspan id="tspan4552" style="font-size:80.00000119%;baseline-shift:sub">0708</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4554" r="2" cy="380" cx="460"></circle></g><g style="stroke-linecap:square" id="g4556" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4558" d="m 540,340 14,8 0,-16 z"></path><text id="text4560" style="font-size:18px;text-anchor:start;fill:#808080" y="346.75" x="559">Store<tspan id="tspan4562" style="font-size:80.00000119%;baseline-shift:sub">Req</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4564" r="2" cy="340" cx="540"></circle></g><g style="stroke-linecap:square" id="g4566" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4568" d="m 461,328 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4570" r="2" cy="340" cx="460"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4572" r="2" cy="360" cx="480"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4574" r="2" cy="340" cx="500"></circle></g><g style="stroke-linecap:square" id="g4576" transform="translate(5.9677734,0.44635936)"><text id="text4578" style="font-size:24px;text-anchor:end;fill:#000000" y="309" x="277">0</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4580" r="2" cy="300" cx="280"></circle></g><g style="stroke-linecap:square" id="g4582" transform="translate(5.9677734,0.44635936)"><text id="text4584" style="font-size:24px;text-anchor:end;fill:#000000" y="369" x="277">1</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4586" r="2" cy="360" cx="280"></circle></g><g style="stroke-linecap:square" id="g4588" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4590" d="m 540,420 14,8 0,-16 z"></path><text id="text4592" style="font-size:18px;text-anchor:start;fill:#808080" y="426.75" x="559">Load<tspan id="tspan4594" style="font-size:80.00000119%;baseline-shift:sub">Req</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4596" r="2" cy="420" cx="540"></circle></g><g style="stroke-linecap:square" id="g4598" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4600" d="m 461,408 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4602" r="2" cy="420" cx="460"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4604" r="2" cy="400" cx="480"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4606" r="2" cy="420" cx="500"></circle></g><g style="stroke-linecap:square" id="g4608" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4610" d="m 401,328 18,12 -18,12 z"></path><circle class="black" style="fill:none;stroke:#000000;stroke-width:4" id="circle4612" r="9" cy="340" cx="430"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4614" r="2" cy="340" cx="400"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4616" r="2" cy="340" cx="440"></circle></g><g style="stroke-linecap:square" id="g4618" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4620" d="m 321,516 38,9 0,150 -38,9 z"></path><text id="text4622" style="font-size:18px;text-anchor:start;fill:#808080" y="535.5" x="323">0</text> <circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4624" r="2" cy="520" cx="340"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4626" r="2" cy="520" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4628" r="2" cy="540" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4630" r="2" cy="560" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4632" r="2" cy="580" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4634" r="2" cy="600" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4636" r="2" cy="620" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4638" r="2" cy="640" cx="320"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4640" r="2" cy="660" cx="320"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4642" r="2" cy="600" cx="360"></circle></g><g style="stroke-linecap:square" id="g4644" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4646" d="m 260,500 -14,-8 0,16 z"></path><text id="text4648" style="font-size:18px;text-anchor:end;fill:#808080" y="506.75" x="241">Instr</text> <circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4650" r="2" cy="500" cx="260"></circle></g><g style="stroke-linecap:square" id="g4652" transform="translate(5.9677734,0.44635936)"><text id="text4654" style="font-size:12px;text-anchor:end;fill:#808080" y="497" x="278">0-15</text> <text id="text4656" style="font-size:12px;text-anchor:start;fill:#808080" y="497" x="302">9-11</text> <path class="black" style="fill:#000000;fill-opacity:1;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4658" d="m 288,498 4,0 0,4 -4,0 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4660" r="2" cy="500" cx="280"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4662" r="2" cy="500" cx="300"></circle></g><g style="stroke-linecap:square" id="g4664" transform="translate(5.9677734,0.44635936)"><text id="text4666" style="font-size:24px;text-anchor:end;fill:#000000" y="529" x="297">0</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4668" r="2" cy="520" cx="300"></circle></g><g style="stroke-linecap:square" id="g4670" transform="translate(5.9677734,0.44635936)"><text id="text4672" style="font-size:24px;text-anchor:end;fill:#000000" y="549" x="297">1</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4674" r="2" cy="540" cx="300"></circle></g><g style="stroke-linecap:square" id="g4676" transform="translate(5.9677734,0.44635936)"><text id="text4678" style="font-size:24px;text-anchor:end;fill:#000000" y="569" x="297">2</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4680" r="2" cy="560" cx="300"></circle></g><g style="stroke-linecap:square" id="g4682" transform="translate(5.9677734,0.44635936)"><text id="text4684" style="font-size:24px;text-anchor:end;fill:#000000" y="589" x="297">2</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4686" r="2" cy="580" cx="300"></circle></g><g style="stroke-linecap:square" id="g4688" transform="translate(5.9677734,0.44635936)"><text id="text4690" style="font-size:24px;text-anchor:end;fill:#000000" y="609" x="297">0</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4692" r="2" cy="600" cx="300"></circle></g><g style="stroke-linecap:square" id="g4694" transform="translate(5.9677734,0.44635936)"><text id="text4696" style="font-size:24px;text-anchor:end;fill:#000000" y="649" x="297">2</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4698" r="2" cy="640" cx="300"></circle></g><g style="stroke-linecap:square" id="g4700" transform="translate(5.9677734,0.44635936)"><text id="text4702" style="font-size:24px;text-anchor:end;fill:#000000" y="629" x="297">1</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4704" r="2" cy="620" cx="300"></circle></g><g style="stroke-linecap:square" id="g4706" transform="translate(5.9677734,0.44635936)"><text id="text4708" style="font-size:24px;text-anchor:end;fill:#000000" y="669" x="297">1</text> <circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4710" r="2" cy="660" cx="300"></circle></g><g style="stroke-linecap:square" id="g4712" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4714" d="m 460,640 -14,-8 0,16 z"></path><text id="text4716" style="font-size:18px;text-anchor:end;fill:#808080" y="646.75" x="441">Instr<tspan id="tspan4718" style="font-size:80.00000119%;baseline-shift:sub">0708</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4720" r="2" cy="640" cx="460"></circle></g><g style="stroke-linecap:square" id="g4722" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4724" d="m 540,600 14,8 0,-16 z"></path><text id="text4726" style="font-size:18px;text-anchor:start;fill:#808080" y="606.75" x="559">Mem<tspan id="tspan4728" style="font-size:80.00000119%;baseline-shift:sub">Mode</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4730" r="2" cy="600" cx="540"></circle></g><g style="stroke-linecap:square" id="g4732" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4734" d="m 461,588 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4736" r="2" cy="600" cx="460"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4738" r="2" cy="620" cx="480"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4740" r="2" cy="600" cx="500"></circle></g><g style="stroke-linecap:square" id="g4742" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4744" d="m 780,560 -14,-8 0,16 z"></path><text id="text4746" style="font-size:18px;text-anchor:end;fill:#808080" y="566.75" x="761">Instr<tspan id="tspan4748" style="font-size:80.00000119%;baseline-shift:sub">0708</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4750" r="2" cy="560" cx="780"></circle></g><g style="stroke-linecap:square" id="g4752" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4754" d="m 860,520 14,8 0,-16 z"></path><text id="text4756" style="font-size:18px;text-anchor:start;fill:#808080" y="526.75" x="879">Mem<tspan id="tspan4758" style="font-size:80.00000119%;baseline-shift:sub">Signed</tspan> </text><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4760" r="2" cy="520" cx="860"></circle></g><g style="stroke-linecap:square" id="g4762" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4764" d="m 781,508 38,12 -38,12 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4766" r="2" cy="520" cx="780"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4768" r="2" cy="540" cx="800"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4770" r="2" cy="520" cx="820"></circle></g><g style="stroke-linecap:square" id="g4772" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4774" d="m 580,500 -14,-8 0,16 z"></path><text id="text4776" style="font-size:18px;text-anchor:end;fill:#808080" y="506.75" x="561">Instr</text> <circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4778" r="2" cy="500" cx="580"></circle></g><g style="stroke-linecap:square" id="g4780" transform="translate(5.9677734,0.44635936)"><text id="text4782" style="font-size:12px;text-anchor:end;fill:#808080" y="497" x="598">0-15</text> <text id="text4784" style="font-size:12px;text-anchor:start;fill:#808080" y="497" x="622">9</text> <text id="text4786" style="font-size:12px;text-anchor:start;fill:#808080" y="537" x="622">10</text><path class="black" style="fill:#000000;fill-opacity:1;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4788" d="m 608,498 4,0 0,44 -4,0 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4790" r="2" cy="500" cx="600"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4792" r="2" cy="500" cx="620"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4794" r="2" cy="540" cx="620"></circle></g><g style="stroke-linecap:square" id="g4796" transform="translate(5.9677734,0.44635936)"><path class="black" style="fill:none;stroke:#000000;stroke-width:4" inkscape:connector-curvature="0" id="path4798" d="m 690,550 -49,0 0,-60 49,0 c 10,0 30,10 29,30 0,20 -19,30 -29,30 z"></path><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4800" r="2" cy="500" cx="640"></circle><circle class="blue" style="fill:#0000b2;stroke:#0000b2;stroke-width:4" id="circle4802" r="2" cy="540" cx="640"></circle><circle style="fill:#b20000;stroke:#b20000;stroke-width:4" id="circle4804" r="2" cy="520" cx="720"></circle></g></svg>

Here are the different exotic logic components used here:

*   the small triangles are tunnels: named wires that are accessible anywhere in the circuit;
*   the big trapezoids are multiplexers: they output the nth input, where n is also an input;
*   the three-wired triangles are buffers: they output their input if the side wire is high, otherwise they output Z (high-impedance);
*   the yellow boxes convert a 3-bit low register number into a 4-bit register number (by adding a zero in front of it);
*   the large rectangles with integer ranges next to them are splitters: they split a multi-bit value into multiple smaller values, to access individual bits or bit ranges

From top to bottom:

*   the three registers (Rd, Rb, Ro) are read from the instruction at their respective positions (0-2, 3-5, 6-8) and sent to the corresponding global tunnels (RW, RA, RB)
*   `opcode` is decoded to check whether it's a store (`000`, `001`, `010`) or a load (remaining values)
*   `opcode` is decoded to find the value of `mode`: 0 for word, 1 for halfword, 2 for byte
*   `opcode` is yet again decoded to find the value of `sign` (true only for opcodes `011` and `111` so we can check that the last two bits are high)

The Instr0708 tunnel is the activation pin for this component; it's high if the current instruction belongs to this instruction group.

Pretty much all other components look like this one, and when you plug them all together, you get a circuit that can execute instructions.

* * *

### Quick sidenote: memory is hard

The seemingly simple problem of manipulating data and storing it somewhere so that you can get it back later is actually... not simple. Giving your CPU access to a big linear array of memory cells is not enough, you have to decide what you are going to do with it. Look at this Python program:

```python
print("Hello, World!")
```

Where should the string be stored? It's gotta be somewhere. What about `print`? It's not an instruction, it's just a global variable that happens to be set to an object of type `builtin_function_or_method`, that you can call with the `()` operator. It's gotta be stored somewhere too. Remember, the only thing you really have at the moment is a big array of numbers. On top of that, the only set of operations you really have is `{"load value from address", "store value at address"}`. Or is it?

The CPU speaks in assembly instructions. These instructions have a fixed, defined encoding, and on the ARM Thumb instruction set they always (i.e. almost always) have the same size: 16 bits. Ignoring the header of the instruction (that tells you which one it is), that will take up a few bits, we quickly see that if we were to give address as immediates (constant values, in the instruction), we couldn't address more than 216 bytes of memory.

Hence: addressing modes and memory alignment.

If we look at everyday life programs, we can observe that there are two main use cases for memory: storing local variables (variables in functions, or parameters), and storing global variables (global configuration, memory that will be shared between programs).

| Use case | Allocation size | Maximum lifetime | Time of allocation | Time of free |
| --- | --- | --- | --- | --- |
| Local | Generally small | Current function call | When entering function | When leaving function |
| Global | Any | Static (lifetime of the program) | Any | Any |

There's a clear difference: on one hand, "local memory", which is used for small, deterministic allocations, and "global memory", which is used for anything, at any time, with very few constraints.

How does that map to our "big block of cells"? We'll start with the "global" memory. We don't really know anything about how it'll be used, so we can't make too many assumptions. You can ask for any amount of bytes at any moment, and give it back to the OS any time you want, and you usually expect "given-back" space to be useable by subsequent allocations. This is [hard](https://www.researchgate.net/publication/234785757_A_comparison_of_memory_allocators_for_real-time_applications). The real-world equivalent would be a big pile of stuff, laying on the ground, waiting for some program to pick it up, use it, or throw it in the trash. For this reason, it's called the **heap**.

Next, we can see that the "local memory" evolves in a specific way: it grows when we enter a function, shrinks when we exit it, and function calls follow a stack-like pattern (when you've entered a function, you can do anything you want, but you always end up exiting it at some point). In fact, it really is a stack (in the algorithmic data structure meaning); it's got two operations: push (grow) and pop (shrink). This "local memory" is called the **stack**.

Since it grows and shrinks that way, we don't really have to do any bookkeeping of the blocks of allocated memory, where they are, what strategy to use to choose where to allocate new blocks, etc. The only piece of data we need is the "depth" (i.e. how deep we are in that stack, or in other words, the length of the stack). The way this is usually done is that we set some place in memory to be the beginning of the stack, and we keep a global variable somewhere (for example, _in a register_) that contains the position in memory of the topmost item of the stack: the **stack pointer** (on ARM, `sp`, or its full name `r13`).

There's something I haven't specified yet: which _direction_ the stack grows. Some architectures make it grow _upward_ (push = increment stack pointer, pop = decrement), but most do it the opposite way and make it grow _downward_. Growing it downward means that you can easily make the heap start at address 0 and make the stack start at whatever the maximum address is, and you're assured that they won't collide until the heap grows too far up or the stack grows too far down.

> In memory parlance, _upward_ means _increasing_ and _downward_ means _decreasing_. "The stack grows **downward**" means that growing the stack **decreases** the stack pointer, and vice versa. Many diagrams online illustrate memory with the address 0 at the top, suggesting that _downward_ means _increasing_, but this is misleading.
{: .prompt-tip }

Now that we know how memory works, how do we access it? We've seen that we can't address it all, since instructions are too small, so how can we counter that?

Well, the answer is to use different addressing modes. For example, if you want to access memory on the stack, you'll usually be accessing things that are on top of the stack (e.g. your local variables), so instead of giving the full memory address (big), you only have to give the distance to the data relative to the stack pointer (small). This is the `sp`\-relative addressing mode, and looks like `ldr r1, [sp, #8]`.

Additionally, we can assume you will mostly store things that are 4 bytes or bigger, so we'll say that the stack is word-aligned: everything will be moved around so that addresses are multiples of 4. This means that we can fit even bigger numbers in the instruction: we only have to store the offset, divided by 4. The instruction above would encode its operand as 2, for example.

Sometimes, you'll want to store data that is only useful to a single function. For example, `switch` / `match` instructions are usually implemented using jump tables: a list of offsets is stored in the program, and the correct offset is loaded and jumped to. Since this will be stored in the code of the function itself, it becomes useful to perform memory operations relative to the current position in the code, and that's how get get `pc`\-relative addressing: `ldr r2, [pc, #16]`. As with `sp`, memory is word-aligned, so the offset has to be a multiple of 4.

* * *

### Quick sidenode: function calls

The simplest way to call functions, in assembly, is through the use of **jumps**. You put a label somewhere, you jump to it. There's a problem though: how do you go back? A function can be called from multiple places, so you need to be able to "remember" where the function was called from, and you need to be able to jump to an address, rather than to a known label.

The simple approach, like with the stack pointer before, is to use a global variable (i.e. register) to store the address of the caller, and to have a special jump instruction that sets the register to the current position (_linking_), so we can go back to it later (_branching_). On ARM, this is the `bl` (_branch-link_) family of instructions, and that register is called the **link register** (abbreviated `lr`, nickname of `r14`).

But there's another problem: it doesn't work for nested calls! If you call a function from inside another called function, the value of the link register gets overwritten.

This is actually not a new problem: other registers can get overwritten as well when you call a function, and you can't expect the programmer to read the code of every function they're calling to see which registers are safe and which aren't. Here comes the **calling convention**: on every architecture (x86, ARM, ...) there's a set of rules (the **ABI**) that tell you how everything works, what a function is allowed to do, and specifically what registers should be preserved by the callee. A preserved register is not read-only: the callee can do whatever it wants with it, as long as when the control is given back to the caller, the old value is back.

The way to solve this is through register saving. When entering a function, space is allocated on the stack for local variables but also for registers that have to be preserved, and when exiting, the original values are pulled back from the stack into the registers.

Among those registers, on ARM, the link register is saved too. One cool aspect of ARM special registers being useable as general-purpose registers, is that you don't have to use a branch instruction to jump somewhere: you can just write into `pc`!

The usual pattern for functions in ARM assembly is thus:

```armasm
my_function:
    push {r4, r5, lr} ; save r4, r5 and lr
    movs r4, #123 ; do stuff
    movs r5, #42
    pop {r4, r5, pc} ; restore the values to r4, r5 and *pc*!
```

* * *

### Devices

Not much is needed to make a circuit look like a computer. For starters, you may want to start with:

*   a keyboard (reading raw character input);
*   a terminal display (displaying characters, like a terminal emulator);
*   a video display (displaying raw pixel data);
*   a random number generator;
*   a decimal 7-segment display;
*   a network card (that can receive and transmit data via TCP).

All of these are seen as addresses in memory by the CPU and programs running on it. For example, writing a byte to address `0xFFFFFF00` will display a character in the terminal display. Reading a byte from address `0xFFFFFF18` will tell whether the keyboard buffer is empty or not.

## Running code

The simplest way to run code on this thing is to simply write machine code and load it into the ROM.

Here's a simple program:

```armasm
movs r0, #255	; r0 = 255 (0x000000FF)
mvns r0, r0		; r0 = ~r0 (0xFFFFFF00, address of terminal)
movs r1, #65    ; r1 = 65  (ASCII code of 'A')
str r1, [r0]    ; *r0 = r1
```

It's assembled as `20ff 43c0 2141 6001` (8 bytes), and when loaded and run, it shows this after 4 cycles:

![terminal display showing the character A](image-1.png){: width="157" height="148"}

Of course, writing programs in assembly isn't exactly practical. We invented [macro assemblers]({% post_url 2022-06-07-how-i-learned-to-stop-worrying-and-love-macros %}) and high-level (compared to assembly) programming languages for this a long time ago, so let's do that here. I originally went with C, but quickly switched to Rust for the ease of use and powerful macro support (useful for a constrained environment like this one).

Rust (technically, _the reference compiler, rustc_) uses LLVM as a backend for compilation, so any target LLVM supports, Rust supports it to some extent. Here, I'm using the builtin target `thumbv6m-none-eabi` (ARM v6-M Thumb, no vendor or OS, embedded ABI), but there's a big constraint: my CPU is not a full ARM CPU.

Since not all instructions are supported (some are emulated by my homemade assembler), I can't just build ARM binaries and load them. I need to use my own assembler, so I'm calling the compiler directly and telling it to emit raw assembly code, which is then sent to my assembler that finally generates a loadable binary file.

Additionally, since I'm running code without an OS, without any external code, I can't use Rust's standard library. This is a perfectly supported use case (called `no_std`), and doesn't mean I can't use anything at all: it only means that instead of using the `std` crate (the usual standard library), I use the `core` crate that contains only the bare necessities and specifically does not depend on an operating system running underneath. The `core` crate however does not include anything that relies on heap allocations (such as `String` or `Vec`), these are found in the `alloc` crate that I don't use either for a number of complex reasons related to my build system.

Basically, I wrote my own standard library. I'm now able to write programs like:

```rust
fn main() {
    println!("Hello, world!");

    screen::circle(10, 10, 20, ColorSimple::Red);

    let x = fp32::from(0.75);
    let mut video = screen::tty::blank().offset(50, 50);
    println!("sin(", Blue.fg(), x, Black.fg(), ") = ", Green.fg(), x.sin(), => &mut video);
}
```

and get:

![](image-5.png){: width="175" height="128"}

![](image-16.png){: width="482" height="272"}

### Pitfalls

Using rustc's raw assembly output means that I can't rely on code from other crates than the one I'm building (that would require using the linker, which I am not using here). I can't even use the compiler's intrinsics: functions such as `memcpy` or `memclr` are often used to perform block copies, but they aren't present in the generated assembly, so I had to implement them myself (I borrowed some code from [Redox](https://www.redox-os.org/) here).

Another problem is that since I am emulating some instructions (by translating them into sequence of other, supported instructions), branch offsets can get bigger than what the compiler expected. Problem: conditional branches on Thumb take an 8-bit signed immediate, so if you try to jump more than 128 instructions ahead or behind, you can't encode that instruction.

In practice, this means that I often have to extract code blocks from functions to make them smaller, and that the whole codebase is sprinkled with `#[inline(never)]` to force the compiler to keep these blocks in separate functions.

Implementing a useable standard library is not the easiest task; ensuring that the whole thing is ergonomic and pleasant to use is even harder. I had to use many unstable (nightly-only) features, such as GATs, associated type defaults, and specializations, among others.

This whole project comforts my choice to use Rust for future low-level/embedded development projects. Doing a hundredth of this in C would have been orders of magnitude harder and the code wouldn't have been anywhere as readable as this one is.

## Showcase

### [Plotter](https://github.com/zdimension/parm_extended/blob/digital/code_rs/test/src/plotter.rs)

<video src="/assets/posts/2022-08-17-crabs-all-the-way-down/javaw_8FU7Np02mK.mp4" poster="https://img.spacergif.org/v1/322x274/0a/spacer.png" width="322" height="274" preload="metadata" style="background: transparent url('/assets/posts/2022-08-17-crabs-all-the-way-down/media-thumbnail-ember92.jpg') 50% 50% / cover no-repeat;" controls="" class="embed-video"></video>

This plotter uses the fixed-point (16.16) numeric library and the video display.

Trigonometric functions were implemented using Taylor series (I know, CORDIC, but I like pain).

### [BASIC interpreter](https://github.com/zdimension/parm_extended/blob/digital/code_rs/test/src/basic.rs)

This is a simple BASIC interpreter / REPL, similar to what was found on home computers of the 80s (e.g. C64). You can input programs line by line, display them, and run them. The supported instructions are `PRINT`, `INPUT`, `CLS`, `GOTO` and `LET`. The prompt supports `LIST`, `RUN`, `LOAD`, `ASM` and `ASMRUN`.

![](image-7.png){: width="289" height="223"}
_"Hello World" program_

Programs can also be loaded over the network (similar to cassette loading on the C64), with a program such as:

```bash
cat $1 <(echo) |	# read file, add newline
dos2unix |			# convert line ends to Unix (LF)
nc -N ::1 4567		# send to port
```

Here, `LOAD` starts listening and the received lines are displayed with a `#` prefix and read as if they were being typed by the user:

![](image-8.png){: width="289" height="425"}
_Fibonacci sequence, loaded over network_

Programs can also be compiled to Thumb assembly for higher performance:

<video src="/assets/posts/2022-08-17-crabs-all-the-way-down/javaw_ABdTnpRbRl.mp4" poster="https://img.spacergif.org/v1/408x544/0a/spacer.png" width="408" height="544" preload="metadata" style="background: transparent url('/assets/posts/2022-08-17-crabs-all-the-way-down/media-thumbnail-ember119.jpg') 50% 50% / cover no-repeat;" controls="" class="embed-video"></video>

In case you're wondering, here's how that part works:

*   each BASIC instruction and expression is converted (compiled) to a sequence of assembly instructions, for example `CLS` simply stores 12 (`\f`) in the address of the terminal output, while an expression simply sets up a little stack machine that evaluates the formula and stores the result in `r1`, and a `LET` instruction evaluates its expression and stores `r1` into the variable's memory cell
*   once the program has been compiled, it's executed like a function, like this:

```rust
let ptr = instructions.as_ptr();
let as_fn: extern "C" fn() -> () = unsafe { core::mem::transmute(ptr) };
as_fn();
```

*   a `bx lr` instruction is appended at the end of the instruction list, so when the program finishes, it gives the control back to the interpreter

### [Web server](https://github.com/zdimension/parm_extended/blob/digital/code_rs/test/src/parmweb.rs)

This program listens for HTTP requests, parses them, and processes them.

![screenshot of circuit, terminal display showing request contents, and Firefox showing the web page](image-9.png){: width="1037" height="917"}

### [Scheme](https://github.com/zdimension/parm_extended/blob/digital/code_rs/test/src/lisp.rs)

This is an REPL for a small but useable enough subset of R6RS. It supports most important primitive forms, many builtins and macros.

Supported datatypes are symbols, integers, booleans, strings, lists (internally stored as vectors), void and procedures (either builtin functions or user-defined closures).

![](image-10.png){: width="450" height="261"}
_addition and Fibonacci sequence_

As with the BASIC interpreter, programs can be loaded over the network:

![](image-11.png){: width="438" height="441"}
_macro creating the named-let form, allowing for easier loop definition_

![](image-12.png){: width="356" height="404"}
_function that creates a mutable accumulator, using closures_

### [Terminal emulator](https://github.com/zdimension/parm_extended/blob/digital/code_rs/test/src/telnet_video.rs)

This is a simple terminal emulator that supports a subset of the ANSI (VT) escape codes (enough to display pretty colors and move the cursor around).

It uses a 5x7 font borrowed from [here](https://github.com/noopkat/oled-font-5x7), and the ANSI decoding logic was written by hand (there are crates out there that do just that, but they support all the ANSI codes, whereas I only needed a very small subset for this program).

A script such as this one can be used to start a shell and pipe it to the circuit:

```bash
exec 3<>/dev/tcp/127.0.0.1/4567
cd ~
unbuffer -p sh -c 'stty echo -onlcr cols 80 rows 30 erase ^H;sh' <&3 1>&3 2>&3
```

![](image-15.png){: width="482" height="272"}

### [MIDI player](https://github.com/zdimension/parm_extended/blob/digital/code_rs/test/src/midi.rs)

Digital provides a MIDI output component, that supports pressing or releasing a key for a given instrument, so I wrote a simple program that uses midly to parse a MIDI file sent over network and then decodes useful messages to play the song.

Since channels are stored sequentially in a MIDI file, and since I only have one output anyway, I wrote an algorithm that merges channels together into a single message list. Events are already stored chronologically, so this is simply a "merge k sorted arrays" problem, that can be solved by recursively merging halves of the array (traditional divide-and-conquer approach) in $O(n k \log k)$ ($k$ arrays of $n$ items).

Here's the result:

<video src="/assets/posts/2022-08-17-crabs-all-the-way-down/javaw_vJd5RnPa6r-1.mp4" poster="https://img.spacergif.org/v1/1920x1080/0a/spacer.png" width="1920" height="1080" preload="metadata" style="background: transparent url('/assets/posts/2022-08-17-crabs-all-the-way-down/media-thumbnail-ember2136.jpg') 50% 50% / cover no-repeat;" controls="" class="embed-video"></video>

## Parting words
All in all, this was fun. ARM/Thumb is a good architecture to implement as a side project, since it's well-supported by compilers and a small enough subset of it can suffice to run interesting code. Logisim and Digital are both excellent tools for digital circuit simulation. Rust is nice for doing things and making stuff.

Repository available [here](https://github.com/zdimension/parm_extended). Don't look at the commit messages.
