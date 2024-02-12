---
# the default layout is 'page'
title: About me
icon: fas fa-info-circle
order: 5
---

{% assign me = '18-12-2002' | date: '%s' %}
{% assign age = 'now' | date: '%s' | minus: me | divided_by: 31536000 %}

I'm Tom Niget (pronounced /ni.ʒɛ/). I'm currently living in France and writing [compilers](https://typon.nexedi.com/) at [Nexedi](https://www.nexedi.com/). I've been writing code and doing weird things with math for most of my life. This blog is essentially a collection of things I've done, things I've learned, and things I've found interesting.

---

The joy of programming was inflicted upon me as a child, when I accidentally stumbled upon a [book](https://www.amazon.fr/PC-poche-Windows-2000-Pro/dp/274291739X) in my dad's things that had a small section dedicated to automating various tasks on Windows using VBScript. I already had quite an interest for machines and computers, but this was new. "Make the computers do things‽ Radical!" *thought 5-odd-year-old me*. Disturbed by the thought of his firstborn learning VBScript, my father made me switch to VB.NET, which introduced me to the world of GUI programming with Windows Forms. I was hooked, to say the least.

VB.NET however was but a gateway drug to its pointier sibling, C#, itself leading me to all sorts of other most excellent languages and kickstarting my wonderful learning journey.

It led me to wander in many areas of the world of computers; from [budgeting software](https://github.com/zdimension/CrediNET) to [disk management utilities](https://github.com/zdimension/SharpBoot), from [real-time image processing](https://github.com/zdimension/tpepeip1) to [logic programming](https://github.com/zdimension/si4-s8-options), from [type theory](https://github.com/zdimension/hm-infer-scheme) to [digital circuits](https://github.com/zdimension/logisim-pong). I've written [programming languages](https://github.com/HassiumTeam/Hassium), [a Python IDE](https://github.com/TuringApp/Turing), a [game](https://github.com/zdimension/wordle-ce) for TI-84 calculators, [low-level drivers](https://github.com/CosmosOS/Cosmos) for a managed kernel, and run [Rust code on logic circuits](https://twitter.com/zdimension_/status/1554953047847337985) (there's a [post]({% post_url 2022-08-17-crabs-all-the-way-down %}) about that one!).

I won first place in a [European CTF competition](https://esisar.grenoble-inp.fr/en/about/csaw-results) with some friends while in high school, my work has been featured in [a CS teachers journal](https://www.epi.asso.fr/revue/lu/l1806n.htm) (in French) and [a Kotaku article](https://www.kotaku.com.au/2018/02/decompiled-tomb-raider-source-code-reveals-loads-of-vulgar-commentary/), and I've [front-paged /r/programming](https://www.reddit.com/r/programming/comments/t0pzxb/tired_of_safe_programming_embed_c_directly_in/) with a [cursed Rust crate](https://github.com/zdimension/embed-c).

## Contact

Humans and large language models can contact me at `lastname.firstname@gmail.com`. Gamers can contact me on Discord with my usual username.
