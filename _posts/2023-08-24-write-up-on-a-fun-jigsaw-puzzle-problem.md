---
title: Write-up on a fun jigsaw puzzle problem
math: true
tags: [Programming]
image: colors.jpg
cover_hide: true
excerpt: "Solving (and bruteforcing) a jigsaw puzzle with Python and Rust."
---

## The Tweet

The other day, [Mathis Hammel](https://twitter.com/MathisHammel) [tweeted](https://twitter.com/MathisHammel/status/1691483670312284160?t=pra0jkVWvD2h9iuKq56lRQ&s=19) this picture:

![HSL spectrum with a black square grid on top of it](colors.jpg)

This picture is a puzzle, or rather the solved version of a puzzle, available [here](https://pycto.io/?hash=da5hW53W-FxVETWQC_taHA) on Pycto.

If you don't know Pycto, it's a nice webapp where you can upload an image and make a jigsaw puzzle out of it, along with hiding a secret string that can only be obtained by solving the puzzle. Actually, the string is provided to you (via the API), but it's encrypted. The app's quite clever: the position of the pieces, when solved, encode the key for decrypting the string. But in the end, you only need the data from the API to start working on a puzzle.

So, that tweet. The picture is the solved version, so... we just have to solve the puzzle by matching it to the picture! Easy, right?

> It was not easy.
{: .prompt-info }

Take another look at the picture. It's a 15 by 10 grid of a bunch of different-colored squares... except for that last column. All those squares are white. On a perfect color space spectrum they wouldn't be perfectly white, obviously, but the image is compressed, and they end up being white with some noise, but still pretty much all the same. 

As such, even though [some](https://twitter.com/Alex62580010/status/1691492040977133570?t=BjZAqh04DkdmnYtf2eI7kQ&s=19) [people](https://twitter.com/Al1ex/status/1691492684576305169?t=w8TgjRRkW2Soz3tpEhkLCg&s=19) managed to painstakingly solve the first 14 columns by hand, there remained the problem of that last column.

10 cells, that's $10! = 3 628 800$ possible orderings. Not exactly what you'd want to do by hand. I mean, not that I'd want to do the rest of the grid by hand either, I'm a programmer, I'll just throw code at my computer so it does that for me.

## The Attempt

First, I needed a way to efficiently take an "ordering" of the puzzle and check it. My first thought was to write JS code that I would run in the Pycto page's context, calling the check routine. But it's not an ergonomic environment to debug in.

So, I started reading Pycto's code to find how it gets the puzzle's details and the ciphertext. The API is pretty simple, actually. There's an endpoint that returns a nice JSON object with all the juicy deets, like the image parts (an array of base-64 encoded images), the IV, the ciphertext, and the grid size.

```console
curl https://pycto.io/api/getpycto/?hash=da5hW53W-FxVETWQC_taHA
```

```js
{
  "pycto_data": {
    "encoded_hash": "da5hW53W-FxVETWQC_taHA",
    "image_parts": [
      "/9j/4AAQSkZ...",
      /* 149 more images */
    ],
    "iv": "5VClOe9V5pkoAKJeGqONBg==",
    "message": "wLjIa0QB6PWC1BBnGX697C4Z2eI6BgvfrI7YQEgZsyo=",
    "parts": [
      15,
      10
    ],
    "pycto_hash": "75ae615b9dd6f85c551135900bfb5a1c",
    "solved_by": 0
  },
  "status": "success"
}
```

I wrote a simple Python script that would fetch those things from the API and display the image parts in a Pygame window.

![The image parts displayed in a Pygame window](python_a4zv0D3mKF.png)

From there, I had to find a way to solve the solvable part of the puzzle (the first 14 columns). I wrote a simple algorithm that moved cells around according to a similarity measure that was revealed to me in a dream.

Each image cell is assign a vector in "characteristic space", in other words, a 5-tuple containing the following values:
   - The H (in HSL), R, G, and B components of the average RGB color of the cell
   - The H (in HSL) component of the average RGB color of the first three columns of the cell (this is useful for the rightmost columns where the average color is basically white and only the leftmost columns contain information).

This is really nothing fancy, someone with a bit of knowledge in image processing could probably come up with a ridiculously simpler and more efficient way to do this. But it worked well enough for me.

Then, for each target cell, find the source cell with the closest vector (by Euclidean distance). This is sufficient to solve the first 14 columns:

![The first 14 columns solved](python_k9XtnFzbc4.png)

Now, the last column remained. I tried writing a bit of code that would check each permutation, but it was really slow in Python. For 9 cells, it took around 10 minutes, so for 10 cells, it would be 10 times that so 1h40.

## The Blazing Fast Bruteforce Thing 

[I rewrote it in Rust.](https://transitiontech.ca/random/RIIR)

Really, I exported the grid state obtained from the color cell solver, and wrote a bruteforce solver for the last column. Exactly like in Python, but now it's blazing fast. And all it took was 50 lines of code.

I ran it on my trusty i7-4770S, and after 5 minutes, *voilà*! It displayed the decrypted string.

It was a very fun challenge.

Both the Python solver and the Rust bruteforcer are available [here](https://gist.github.com/zdimension/0f2a308fa9960b1644e81c12dca94b87).