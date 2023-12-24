---
title: "Calculator Review: Burroughs C3155 / Sharp QT-8D (1971)"
tags: [Hardware]
category: "Random stuff"
image: DSC02668.JPG
cover_responsive: true
cover_hide: true
---

This is the Burroughs C3155:

{% picture DSC02668.JPG --alt A dark grey calculator with a dark Nixie tube display on top showing zeroes, and a keyboard of thick plastic keys. --cover true %}

It's a charming old 1970s calculator rocking a Nixie tube display and an ostensibly 1970s design. It's also known, maybe more widely, as the Sharp QT-8D, of which it is a clone made by Burroughs for sale in the US. Both devices are pretty much identical, except for the layout of the operation keys.

## The Outside

The calculator's shape may feel unusual compared to the modern "TI-82" look that pretty much every handheld calculator has nowadays. Circuit miniaturization (which wasn't really a thing back then, as we'll see) and display technology constraints are the main culprits for that — it's really a desktop calculator in the sense that you're not carrying it around, it's almost 1.4 kg (3 lbs) and needs 220V AC power to run.

{% picture DSC02670.JPG --alt Tilted view of the calculator, showing both the top and the right side, with the power switch visible. %}

Let's have a quick look at the back:

{% picture DSC02669.JPG --alt The back of the calculator, with a serial number sticker, and a cleaning information sticker, with the power cable coming out on the left. The cleaning sticker says "Caution: When cleaning the cabinet, do not use a wet rag, or any fluid cleaning solutions. Use the silicone cloth provided.". The serial number sticker says (left to right, top to bottom) "Burroughs, 7 Watts, C3155 Series, 220 Volts, 0.040 Amps, 50/60 C/S, C-018784-101 Serial No. Made in Japan". %}

I unfortunately am not in possession of the provided silicone cloth, so I'll skip on cleaning the cabinet (?) for now.

It's funny to see that such a simple device needs a 7-watt power supply. For a rough back-of-the-envelope comparison, a TI-82 with its three 1.5V AAA batteries [only draws around 0.1 watts](https://www.cemetech.net/forum/viewtopic.php?t=11806&start=0).

Here are the Nixie tubes in all their glory:

{% picture PXL_20231222_184559122.jpg --alt A close-up of the nine Nixie tubes, showing the digits 1 to 8, followed by a decimal point and a minus sign. The environment is dark. The tubes glow a bright green tint. %}

Another even-closer close-up:

{% picture PXL_20231222_184738364.jpg --alt A close-up of the first three tubes, showing the digits 1 to 3. We can see the square grid in frond of the tubes, and with enough squinting, we can make out some of the non-lit wires. %}

## The Inside

The case is easily opened by removing five screws next to the rubber feet. You'll be happy to know that the calculator was assembled using ISO metric screws, bolts, and nuts:

{% picture DSC02674.JPG --alt A black sticker saying "ASSEMBLED USING ISO METRIC SCREWS, BOLTS & NUTS" in shiny metal-grey letters. %}

Here are the two halves of the device:

{% picture PXL_20231222_185727353.jpg --alt The lower and upper halves of the calculator; the first one contains the main circuit and the display, the second one contains the keyboard circuitry. %}

Close-up of the (dusty) Nixie tubes:

{% picture PXL_20231222_185929021.jpg --alt A close-up of the Nixie tube display, showing the metal front panel, the grid, and a few tubes. %}

The display assembly is mounted on the main circuit board using some sort of extension port, so it's easily removable:

{% picture PXL_20231222_190927517.jpg --alt View of the main circuit after removing the display assembly. We can see 4 LSI chips, a few resistors, a heatsink and other chips. %}

### Main circuit board

{% picture PXL_20231222_190720933.jpg --alt Top view of the main circuit board. %}

The first thing that jumped to my eyes was the peculiar wiring. It's quite common on old circuits, from before the days of automatic computerized routing and tracing.

Next, we have the four main LSI chips, clockwise:
- a [Rockwell NRD2256](https://wiki.calcverse.net/index.php/Rockwell_NRD2256) keypad decoder
- a [Rockwell DC2266](https://commons.wikimedia.org/wiki/File:DC2266.jpg) decimal point manager
- a [Rockwell AU2271](https://wiki.calcverse.net/index.php/Rockwell_AU2271) arithmetic unit/register store (the QT-8D used the AU2276)
- a [Rockwell AC2261](https://wiki.calcverse.net/index.php/Rockwell_AC2261) control logic unit (the QT-8D used the AC2266)

In the bottom left, we have:
- a Rockwell CG2341 clock generator with its star-shaped heatsink
- a [Hitachi HD3103](https://www.oldcalculatormuseum.com/t-hitachihd31xxdata.pdf) chip that provides 5 MOSFETs

Notice how the chips are packaged in ceramic instead of the nowadays more usual black plastic.

{% picture PXL_20231222_190214716.jpg --alt Close-up of one of the LSI chips, showing the white ceramic package and the pins. %}

The rest are passive components, no need to go into details.

### Display block

Here's the display block:

{% picture PXL_20231222_191111740.jpg --alt View of the display block removed from the main circuit, with the nine nixie tubes and the covering panel, plus some circuit thingies. %}

From the back:

{% picture PXL_20231222_191258760.jpg --alt View of the back of the display block, showing the glass cylinders of the tubes. %}

A close-up on the tubes themselves:

{% picture PXL_20231222_191801612.jpg --alt View of a few tubes, we can see the inner wires and the connectors going in each tube. %}

If funky old display tech is your thing, these videos are for you:
- [*VFD Displays* by Posy](https://www.youtube.com/watch?v=PkPSDOjhxwM)
- [*The Art of Making a Nixie Tube* by Dalibor Farný](https://www.youtube.com/watch?v=wxL4ElboiuA)
- [*These digital clocks aren't digital at all* by Technology Connections](https://www.youtube.com/watch?v=ZArBfxaPzD8)

### Keyboard

Not much to say about the keyboard, it's a simple matrix of switches:

{% picture PXL_20231222_192011509.jpg --alt Underside of the keyboard, showing bits of the inner mechanics of the switches with some wires soldered on top. %}

## Behavior and Simulator

You'll notice the function buttons are a bit... unusual. Basically, here's how to use the calculator:
- Enter the first operand using the keypad
- Choose an operation (using <kbd>−</kbd>, <kbd>+</kbd>, or <kbd>÷ ×</kbd>)
- Enter the second operand
- If you wanted to add, subtract, or multiply, press <kbd>=</kbd>, otherwise (if you wanted to divide), press the <kbd>≑</kbd> key (that's the key that also has <kbd>−</kbd>)

Once an operation has been evaluated, the calculator waits for another input. If you don't choose an operation, it defaults on addition/subtraction. In other words, <kbd>1</kbd> <kbd>+</kbd> <kbd>2</kbd> <kbd>=</kbd> <kbd>3</kbd> <kbd>=</kbd> will perform `1+2` and then perform `+3` on the result. <kbd>5</kbd> <kbd>−</kbd> <kbd>2</kbd> <kbd>=</kbd> <kbd>3</kbd> <kbd>=</kbd> will perform `5-2` and then perform `-3` on the result. 

The calculator doesn't handle negative numbers; it behaves as if the absolute value was taken after each computation. The only thing resembling negation is the subtraction mode, which is enabled using the <kbd>−</kbd> key.

Also, there's an indicator right above the minus sign in the shape of an uppercase "I" that I haven't managed to figure out the meaning of, or even to trigger. My first guess was "I" for "Infinite", but there's no operation on this basic calculator that could ever give something infinite-like (division by zero is properly handled and triggers an error state, and using numbers that are too large also triggers an error state). If you have any insight on this, please let me know!

Reverse engineering the calculator's internal logic was... interesting, to say the least. 

If the calculator stops responding (with a screen full of zeroes and dots) it means you're in the "invalid" state 

You can try the calculator with this simulator I made.

> Disclaimer: I tried my best to reproduce as faithfully as possible the behavior of the calculator, but I can't guarantee that it's 100% accurate. For example, I know there are weird things happening when you get a result that doesn't fit in the calculator's internal precision, and I haven't been able to reproduce all of them. This is the only bug I could find, however, so other "weird" behaviors should be those of the real calculator (which is admittedly quite peculiar to use).
{: .prompt-info }

*Thanks to [@mwichary](https://twitter.com/mwichary/status/886427020275535874) for recreating the Sharp EL-8 font in OTF format!*

<div id="calc">
  <div id="calc-display-container">
    <div id="calc-display">
      <div></div>
      <div></div>
      <div></div>
      <div></div>
      <div></div>
      <div></div>
      <div></div>
      <div></div>
      <div></div>
    </div>
  </div>
  <div id="calc-keyboard">
    <div id="calc-left">
      <div>
        <button>7</button><button>8</button><button>9</button>
        <button>4</button><button>5</button><button>6</button>
        <button>1</button><button>2</button><button>3</button>
      </div>
      <div>
        <button>0</button><button data-btn=".">·</button>
      </div>
    </div>
    <div id="calc-right">
      <button data-btn="-">−<br>&eDot;</button><button>C</button>
      <button data-btn="+">+<br>=</button><button data-btn="*">&div;<br>&times;</button>
    </div>
  </div>
</div>

<style>
@font-face {
  font-family: "Sharp EL-8";
  src: url("{{ '/assets/posts/' | append: page.name | remove: '.md' | append: '/Sharp EL-8 calculator font.otf' | relative_url }}") format("opentype");
}

#calc {
  --gap: 0.3cqw;
  container-type: inline-size;
  display: flex;
  flex-direction: column;
  width: 100%;
  border-radius: 1%;
  overflow: hidden;
}

#calc-display-container {
  aspect-ratio: 4.6;
  background: #222;
  padding: 3.6cqw 5cqw 2.1cqw 5cqw;
  width: 100%;
}

#calc * {
  grid-gap: var(--gap);
}

#calc button {
  font-size: 6cqw;
  border-radius: 1cqw;
  border: 1cqw outset #ddd;
  outline: none;
}

#calc button:active {
  --shift: 0.1cqw;
  --new-big: calc(1cqw + var(--shift));
  --new-small: calc(1cqw - var(--shift));
  border-width: var(--new-big) var(--new-small) var(--new-small) var(--new-big);
  border-style: inset;
}

#calc br {
  display: block;
  content: " ";
  margin-top: -2.5cqw;
}

#calc-keyboard {
  aspect-ratio: 1.42;
  padding: 7.2% 11.5% 9.4% 14.4%;
  background: #333;
  display: flex;
  width: 100%;
}

#calc-left {
  width: 53%;
  padding: var(--gap);
  display: flex;
  flex-direction: column;
}

#calc-left> :nth-child(1) {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: repeat(3, 1fr);
  height: 75%;
}

#calc-left> :nth-child(2) {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  height: 25%;
}

#calc-right {
  width: 36%;
  margin-left: auto;
  padding: var(--gap);
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-template-rows: repeat(2, 1fr);
}

#calc-right>button:first-child {
  background-color: red;
  color: white;
  border-color: #d00;
}

#calc-keyboard>* {
  background-color: #111;
  border-radius: 0.7cqw;
}

#calc-display {
  max-height: calc((100cqw / 4.6) - 5.7cqw);
  background: #111;
  display: grid;
  grid-template-columns: repeat(9, 1fr);
  grid-gap: 1cqw;
  width: 100%;
  height: 100%;
}

#calc-display>* {
  color: #02bb78;
  font-size: 13cqw;
  text-align: center;
  position: relative;
  top: -2.5cqw;
  height: calc(100% + 2.5cqw);
  text-shadow: 0 0 5cqw #02bb78;
  overflow: hidden;
}

#calc-display>*[comma="true"]::after {
  position: absolute;
  bottom: -7cqw;
  right: 0.5cqw;
  content: "⋅";
  font-family: "Arial";
  font-size: 90%;
}

#calc-display>*:not(:last-child) {
  font-family: "Sharp EL-8";
}

#calc-display>*:last-child {
  font-family: "Arial";
}

#calc-display>*[minus="true"]::before {
  position: absolute;
  left: 1.75cqw;
  content: "-";
}

#calc-display>*[infinite="true"]::after {
  position: absolute;
  left: 2cqw;
  top: 4cqw;
  content: "Ｉ";
  font-size: 4cqw;
}
</style>

<script>
document.addEventListener("DOMContentLoaded", function() {
  let display = $("#calc-display");
  let digits = display.children(":not(:last-child)");
  let indicator = display.children().last();

  const POWERON = {
    minus: true,

    display() {
      digits.text("0");
      digits.attr("comma", "true");
      indicator.attr("minus", state.minus);
    },

    onKey(key) {
      switch (key) {
        case "-":
          state.minus = !state.minus;
          indicator.attr("minus", state.minus);
          break;
        case "C":
          minus = false;
          setState(blankState());
          break;
      }
    }
  };

  function setState(newState) {
    state = newState;
    state.display();
  }

  function blankState() {
    const EMPTY = () => ({
      val: "",
      comma: null
    });
    let initial = EMPTY();
    return {
      minus: false,
      times: false,
      firstOperand: null,

      input: initial,
      displayedInput: initial,
      comma: null,
      commaStart: false,

      display() {
        let input = state.displayedInput;
        let padded = input.val.padStart(8, "0");
        let offset = 8 - input.val.length;
        let effectiveComma = (input.comma === null ? (input.val === "" ? null : input.val.length) : input.comma);
        digits.each(function(i, e) {
          $(e).text(padded.charAt(i)).attr("comma", i - offset + 1 === effectiveComma);
        });
        indicator.attr("minus", state.minus);
      },

      parse() {
        if (state.input.length === 0) {
          return 0.0;
        }
        let comma = state.input.comma === null ? 8 : state.input.comma;
        if (comma === 9) {
          return 10 * parseInt(state.input.val);
        }
        return parseFloat(state.input.val.substring(0, comma) + "." + state.input.val.substring(comma));
      },

      evaluate(result) {
        result = result.toString().split(".");
        state.input.val = result[0].substring(0, 8);
        if (result[0].length > 8) {
          state.input.comma = 9;
        } else if (result.length === 2) {
          state.input.val += result[1];
          state.input.val = state.input.val.substring(0, 8);
          state.input.comma = result[0].length;
        }
        state.firstOperand = state.parse();
        state.input = EMPTY();
      },

      operands() {
        return [state.firstOperand || 0, state.parse()];
      },

      onKey(key) {
        switch (key) {
          case "-":
            if (state.times) {
              if (state.input.length !== 0) {
                let [a, b] = state.operands();
                if (b == 0) {
                  POWERON.minus = state.minus;
                  setState(POWERON);
                  return;
                }
                state.times = false;
                /* a small value is added to reproduce the bug
                   when dividing numbers, the calculator always displays it to the left */
                state.evaluate(a / b + 0.00000001);
              } else {
                state.minus = !state.minus;
              }
            } else {
              state.minus = !state.minus;
              if (state.input.val.length !== 0) {
                state.firstOperand = state.parse();
              }
              state.input = EMPTY();
            }
            indicator.attr("minus", state.minus);
            break;
          case "C":
            state = blankState();
            break;
          case "+":
            if (state.input.val.length !== 0) {
              let [a, b] = state.operands();
              if (state.times) {
                state.evaluate(a * b);
                state.times = false;
              } else if (state.minus) {
                let result = a - b;
                if (result < 0) {
                  state.minus = false;
                  result = -result;
                }
                state.evaluate(result);
              } else {
                state.evaluate(a + b);
              }
            }
            break;
          case "*":
            if (state.input.val.length !== 0) {
              state.firstOperand = state.parse();
            }
            state.times = true;
            state.input = EMPTY();
            break;
          case ".":
            if (state.input.val === "") {
              state.commaStart = true;
            } else {
              state.input.comma = state.input.val.length;
            }
            break;
          default:
            if (key >= "0" && key <= 9) {
              if (state.input.val.length < 8) {
                if (state.commaStart) {
                  if (state.input.val.length === 0) {
                    state.input.val = "0";
                    state.input.comma = 1;
                  }
                  state.commaStart = false;
                }
                state.input.val += key;
              }
              state.displayedInput = state.input;
            }
            break;
        }
      }
    };
  }

  let state = POWERON;

  let buttons = $("#calc-keyboard button");

  buttons.click(function(e) {
    state.onKey($(this).data("btn") || $(this).text());
    state.display();
  });

  buttons.on("keypress", function(e) {
    if (e.which === 13) {
      e.preventDefault();
    }
  });

  state.display();

  $(document).on("keypress", function(e) {
    let kc = String.fromCharCode(e.which);
    let mapping = {
      "/": "*",
      "c": "C",
      "\r": "+",
      "=": "+"
    };
    state.onKey(mapping[kc] || kc);
    state.display();
  });
});
</script>
