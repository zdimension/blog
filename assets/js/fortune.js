---
---
const cowsay = require("cowsay");
const fs = require("fs");
const raw = fs.readFileSync("assets/data/computers.txt", "ascii").replace(/\r/g, "").split("\n%\n").slice(0, -1);
const literature = raw.filter(e => !e.includes("NORTH AMERICAN MALES"));
const random = literature[Math.floor(Math.random() * literature.length)];
//const random = literature.find(e => e.includes("programming systems"));
//const random = literature.find(e => e.includes("The FTC is conc"));
const wrap = require("word-wrap");

const block = window.fortune;

block.style.visibility = "hidden";

block.textContent = "A";

let cw = 1;

while (block.scrollWidth <= block.clientWidth && cw < 70) {
    block.textContent = "A".repeat(++cw);
}

const width = cw - 1 - 4;
const fakeTab = "\x01".repeat(4);
const text = wrap(random
                .replace(/([^.*\n)]|\.\.)\n[ \t]*([\w"])/g, "$1 $2") // don't ask
                .replace(/    |\t/g, fakeTab)
                .replace(/ +/g, " "), {indent: "", width}
            ).replaceAll(fakeTab, "    ");

block.textContent = cowsay.say(text, {nowrap: true});

block.style.visibility = "visible";