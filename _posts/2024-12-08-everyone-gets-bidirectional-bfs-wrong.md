---
title: "Everyone gets bidirectional BFS wrong"
description: "People really need to stop blindly copying code from algorithms websites."
tags: [Programming]
image: cover.svg
math: true
---

<style>
    div.content {
        svg {
            width: 100%;

            & .mono text {
                font-family: var(--bs-font-monospace) !important;
                font-size: 60%;
            }

            * {
                cursor: default;
            }

            & > .graph {
                & > path {
                    display: none;
                }

                & > * {
                    --lum-delta: -10;
                    --hover-fill: hsl(from var(--fill) h s calc(l + var(--lum-delta)));
                    --fill: var(--fill-base);
                    --border: var(--border-base);
                }

                & > * {
                    --fill-base: white;
                    --border-base: hsl(from var(--fill) h s calc(l - 80));
                }

                @container style(--theme: "dark") {
                    & > g {
                        --fill-base: #2d2d2d;
                        --border-base: hsl(from var(--fill) h s calc(l + 32));
                        --lum-delta: 5;
                    }
                }

                & .node > :not(text) {
                    stroke: var(--border);
                    fill: var(--fill);
                    transition: fill 0.1s, stroke 0.1s;
                }

                & .node:hover > :not(text) {
                    fill: var(--hover-fill);
                }

                & .edge path {
                    stroke: var(--border);
                    fill: var(--border);
                }
            }
        }
    }
</style>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        document.querySelectorAll("svg").forEach(function(svg) {
            svg.setAttribute("aria-hidden", "true");
        });
    });
</script>

This post is about graphs and graph algorithms. Specifically, it's about a common, simple algorithm that's somehow so hard to get right that the first few pages of Google results are filled with wrong implementations.

Most of the post is about what graphs are and how some pathfinding algorithms work. If you don't care about this, you can skip to the [namedropping section](#someone-is-wrong-on-the-internet) (but you'll miss out on some cool interactive visualizations).

## Graphs 101

A **graph** is a bunch of things (called **nodes** or **vertices**) that are connected by links (called **edges**). Here are a few graphs, free of charge:

<script type="graphviz" name="Directory tree">
digraph G {
  "C:\\" -> {"Program Files", "Users", "Windows"};
  "Program Files" -> {"Google", "Mozilla"};
  "Users" -> {"Alice", "Bob"};
  "Alice" -> "Documents"
}
</script>
<svg width="404pt" height="260pt" viewBox="0 0 403.51 260" xmlns="http://www.w3.org/2000/svg"><g class="graph" transform="translate(4 256)"><path fill="#fff" stroke="transparent" d="M-4 4v-260h403.51V4z"/><g class="node"><ellipse cx="248.46" cy="-234" rx="27" ry="18" fill="none" stroke="#000"/><text x="248.464" y="-229.8" font-family="Times,serif" font-size="14" text-anchor="middle">C:\</text></g><g class="node"><ellipse cx="131.46" cy="-162" rx="65.465" ry="18" fill="none" stroke="#000"/><text x="131.464" y="-157.8" font-family="Times,serif" font-size="14" text-anchor="middle">Program Files</text></g><g class="edge"><path d="m228.62-221.79-61.528 37.863" fill="none" stroke="#000"/><path stroke="#000" d="m168.79-180.86-10.35 2.26 6.69-8.22z"/></g><g class="node"><ellipse cx="248.46" cy="-162" rx="33.041" ry="18" fill="none" stroke="#000"/><text x="248.464" y="-157.8" font-family="Times,serif" font-size="14" text-anchor="middle">Users</text></g><g class="edge"><path d="M248.46-215.83v25.415" fill="none" stroke="#000"/><path stroke="#000" d="m251.96-190.41-3.5 10-3.5-10z"/></g><g class="node"><ellipse cx="347.46" cy="-162" rx="48.096" ry="18" fill="none" stroke="#000"/><text x="347.464" y="-157.8" font-family="Times,serif" font-size="14" text-anchor="middle">Windows</text></g><g class="edge"><path d="m267.08-220.46 49.847 36.252" fill="none" stroke="#000"/><path stroke="#000" d="m319.08-186.97 6.03 8.71-10.14-3.05z"/></g><g class="node"><ellipse cx="39.464" cy="-90" rx="39.427" ry="18" fill="none" stroke="#000"/><text x="39.464" y="-85.8" font-family="Times,serif" font-size="14" text-anchor="middle">Google</text></g><g class="edge"><path d="m109.66-144.94-42.07 32.925" fill="none" stroke="#000"/><path stroke="#000" d="m69.57-109.12-10.032 3.41 5.718-8.92z"/></g><g class="node"><ellipse cx="138.46" cy="-90" rx="41.147" ry="18" fill="none" stroke="#000"/><text x="138.464" y="-85.8" font-family="Times,serif" font-size="14" text-anchor="middle">Mozilla</text></g><g class="edge"><path d="m133.23-143.83 2.47 25.415" fill="none" stroke="#000"/><path stroke="#000" d="m139.19-118.71-2.52 10.3-4.45-9.62z"/></g><g class="node"><ellipse cx="242.46" cy="-90" rx="31.897" ry="18" fill="none" stroke="#000"/><text x="242.464" y="-85.8" font-family="Times,serif" font-size="14" text-anchor="middle">Alice</text></g><g class="edge"><path d="m246.95-143.83-2.118 25.415" fill="none" stroke="#000"/><path stroke="#000" d="m248.32-118.09-4.32 9.68-2.66-10.26z"/></g><g class="node"><ellipse cx="319.46" cy="-90" rx="27.268" ry="18" fill="none" stroke="#000"/><text x="319.464" y="-85.8" font-family="Times,serif" font-size="14" text-anchor="middle">Bob</text></g><g class="edge"><path d="m264.22-146.02 32.966 33.43" fill="none" stroke="#000"/><path stroke="#000" d="m299.71-115.02 4.53 9.58-9.52-4.66z"/></g><g class="node"><ellipse cx="242.46" cy="-18" rx="55.036" ry="18" fill="none" stroke="#000"/><text x="242.464" y="-13.8" font-family="Times,serif" font-size="14" text-anchor="middle">Documents</text></g><g class="edge"><path d="M242.46-71.831v25.415" fill="none" stroke="#000"/><path stroke="#000" d="m245.96-46.413-3.5 10-3.5-10z"/></g></g></svg>

<label>A directory tree.</label>

<script type="graphviz" name="Daily routine">
digraph G {
    layout="twopi";
    ranksep=2.2
    
    root=CENTER
    edge [style=invis]
    CENTER [style=invis]
    node[shape=box, style=rounded]
    CENTER -> {
        "Eat breakfast"
        "Wake up"
        "Sleep"
        "Go home"
        "git commit -m \"wip\""
        "Drink coffee"
        "Write code"
        "Go to work"
    }
    edge [style=solid]
    "Wake up" -> "Eat breakfast" -> "Go to work" -> "Write code" -> "Drink coffee" -> "git commit -m \"wip\"" -> "Go home" -> "Sleep" -> "Wake up";
    "git commit -m \"wip\"" [class="mono"];
}
</script>
<svg width="548" height="337pt" viewBox="0 0 411.43 336.69" xmlns="http://www.w3.org/2000/svg"><g class="graph" transform="translate(4 332.685)"><path fill="#fff" stroke="transparent" d="M-4 4v-336.685h411.428V4H-4z"/><g class="node"><path fill="none" stroke="#000" d="M391.658-242.96H325.74c-6 0-12 6-12 12v12c0 6 6 12 12 12h65.918c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="358.699" y="-220.76" font-family="Times,serif" font-size="14">Eat breakfast</text></g><g class="node"><path fill="none" stroke="#000" d="M294.117-328.685H251.83c-6 0-12 6-12 12v12c0 6 6 12 12 12h42.288c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="272.974" y="-306.485" font-family="Times,serif" font-size="14">Wake up</text></g><g class="node"><path fill="none" stroke="#000" d="M166.74-328.685h-30c-6 0-12 6-12 12v12c0 6 6 12 12 12h30c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="151.739" y="-306.485" font-family="Times,serif" font-size="14">Sleep</text></g><g class="node"><path fill="none" stroke="#000" d="M87.726-242.96H44.301c-6 0-12 6-12 12v12c0 6 6 12 12 12h43.425c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="66.014" y="-220.76" font-family="Times,serif" font-size="14">Go home</text></g><g class="node mono"><path fill="none" stroke="#000" d="M120.042-121.725H11.986c-6 0-12 6-12 12v12c0 6 6 12 12 12h108.056c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="66.014" y="-99.525" font-family="Times,serif" font-size="14">git commit -m &quot;wip&quot;</text></g><g class="node"><path fill="none" stroke="#000" d="M183.362-36h-63.245c-6 0-12 6-12 12v12c0 6 6 12 12 12h63.245c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="151.739" y="-13.8" font-family="Times,serif" font-size="14">Drink coffee</text></g><g class="node"><path fill="none" stroke="#000" d="M299.774-36h-53.601c-6 0-12 6-12 12v12c0 6 6 12 12 12h53.6c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="272.974" y="-13.8" font-family="Times,serif" font-size="14">Write code</text></g><g class="node"><path fill="none" stroke="#000" d="M386.464-121.725h-55.53c-6 0-12 6-12 12v12c0 6 6 12 12 12h55.53c6 0 12-6 12-12v-12c0-6-6-12-12-12"/><text text-anchor="middle" x="358.699" y="-99.525" font-family="Times,serif" font-size="14">Go to work</text></g><g class="edge"><path fill="none" stroke="#000" d="M358.699-206.81v74.59"/><path stroke="#000" d="m362.199-131.999-3.5 10-3.5-10h7z"/></g><g class="edge"><path fill="none" stroke="#000" d="m291.154-292.505 42.197 42.197"/><path stroke="#000" d="m335.949-252.659 4.596 9.546-9.546-4.597 4.95-4.949z"/></g><g class="edge"><path fill="none" stroke="#000" d="M178.947-310.685h50.649"/><path stroke="#000" d="m229.809-314.185 10 3.5-10 3.5v-7z"/></g><g class="edge"><path fill="none" stroke="#000" d="m84.194-243.14 42.197-42.197"/><path stroke="#000" d="m124.039-287.935 9.546-4.596-4.596 9.546-4.95-4.95z"/></g><g class="edge"><path fill="none" stroke="#000" d="M66.014-121.875v-74.59"/><path stroke="#000" d="m62.514-196.685 3.5-10 3.5 9.999-7 .001z"/></g><g class="edge"><path fill="none" stroke="#000" d="M133.56-36.18 91.361-78.377"/><path stroke="#000" d="m88.764-76.025-4.596-9.546 9.546 4.596-4.95 4.95z"/></g><g class="edge"><path fill="none" stroke="#000" d="M233.947-18h-28.393"/><path stroke="#000" d="m205.318-14.5-10-3.5 10-3.5v7z"/></g><g class="edge"><path fill="none" stroke="#000" d="m340.519-85.545-42.197 42.197"/><path stroke="#000" d="m300.673-40.75-9.546 4.596 4.597-9.546 4.949 4.95z"/></g></g></svg>

<label>A daily routine.</label>

<script type="graphviz" name="Cities">
graph G {
    splines=false; 
    overlap = false;
    start=6
    node[shape=box, style=rounded];
    "Paris" -- {"Berlin", "Rome", "Madrid", "Brussels"};
    "Berlin" -- {"Warsaw", "Prague", "Rome", "Brussels"};
    "Rome" -- {"Milan", "Naples"};
    "Madrid" -- {"Barcelona", "Lisbon"};
    "Warsaw" -- {"Prague", "Vienna", "Minsk", "Kiev"};
    "Milan" -- {"Naples"};
    "Bucarest" -- {"Vienna"};
    "Kiev" -- {"Bucarest"};
}
</script>
<svg width="494pt" height="420" viewBox="0 0 493.98 315.2" xmlns="http://www.w3.org/2000/svg"><g class="graph" transform="translate(4 311.204)"><path fill="#fff" stroke="transparent" d="M-4 4v-315.204h493.983V4H-4z"/><g class="node"><path fill="none" stroke="#000" d="M213.838-193.428h-54v36h54v-36z"/><text text-anchor="middle" x="186.838" y="-171.228" font-family="Times,serif" font-size="14">Paris</text></g><g class="node"><path fill="none" stroke="#000" d="M291.864-185.277h-54v36h54v-36z"/><text text-anchor="middle" x="264.864" y="-163.077" font-family="Times,serif" font-size="14">Berlin</text></g><g class="edge"><path fill="none" stroke="#000" d="m214.128-172.577 23.594 2.464"/></g><g class="node"><path fill="none" stroke="#000" d="M236.356-119.589h-54v36h54v-36z"/><text text-anchor="middle" x="209.356" y="-97.389" font-family="Times,serif" font-size="14">Rome</text></g><g class="edge"><path fill="none" stroke="#000" d="m192.404-157.176 11.45 37.545"/></g><g class="node"><path fill="none" stroke="#000" d="M141.697-232.246H84.276v36h57.421v-36z"/><text text-anchor="middle" x="112.987" y="-210.046" font-family="Times,serif" font-size="14">Madrid</text></g><g class="edge"><path fill="none" stroke="#000" d="m159.758-189.662-17.956-9.438"/></g><g class="node"><path fill="none" stroke="#000" d="M261.509-251.346h-63.875v36h63.875v-36z"/><text text-anchor="middle" x="229.571" y="-229.146" font-family="Times,serif" font-size="14">Brussels</text></g><g class="edge"><path fill="none" stroke="#000" d="m200.125-193.436 16.02-21.714"/></g><g class="edge"><path fill="none" stroke="#000" d="m249.402-148.98-24.667 29.191"/></g><g class="edge"><path fill="none" stroke="#000" d="m255.22-185.33-16.016-29.984"/></g><g class="node"><path fill="none" stroke="#000" d="M379.512-199.489H317.8v36h61.712v-36z"/><text text-anchor="middle" x="348.656" y="-177.289" font-family="Times,serif" font-size="14">Warsaw</text></g><g class="edge"><path fill="none" stroke="#000" d="m292.3-171.93 25.375-4.304"/></g><g class="node"><path fill="none" stroke="#000" d="M346.563-108.127h-54.745v36h54.745v-36z"/><text text-anchor="middle" x="319.19" y="-85.927" font-family="Times,serif" font-size="14">Prague</text></g><g class="edge"><path fill="none" stroke="#000" d="m277.739-148.994 28.669 40.715"/></g><g class="node"><path fill="none" stroke="#000" d="M280.749-36h-54V0h54v-36z"/><text text-anchor="middle" x="253.749" y="-13.8" font-family="Times,serif" font-size="14">Milan</text></g><g class="edge"><path fill="none" stroke="#000" d="m218.988-83.451 25.147 47.349"/></g><g class="node"><path fill="none" stroke="#000" d="M121.063-55.546H66.321v36h54.742v-36z"/><text text-anchor="middle" x="93.692" y="-33.346" font-family="Times,serif" font-size="14">Naples</text></g><g class="edge"><path fill="none" stroke="#000" d="m182.238-86.574-60.794 33.662"/></g><g class="node"><path fill="none" stroke="#000" d="M72.62-210.029H.127v36H72.62v-36z"/><text text-anchor="middle" x="36.373" y="-187.829" font-family="Times,serif" font-size="14">Barcelona</text></g><g class="edge"><path fill="none" stroke="#000" d="m84.022-205.847-11.15 3.233"/></g><g class="node"><path fill="none" stroke="#000" d="M109.128-307.204H54.352v36h54.776v-36z"/><text text-anchor="middle" x="81.74" y="-285.005" font-family="Times,serif" font-size="14">Lisbon</text></g><g class="edge"><path fill="none" stroke="#000" d="m105.423-232.391-16.08-38.576"/></g><g class="edge"><path fill="none" stroke="#000" d="M342.834-163.44 325-108.14"/></g><g class="node"><path fill="none" stroke="#000" d="M452.708-222.746h-56.856v36h56.856v-36z"/><text text-anchor="middle" x="424.28" y="-200.546" font-family="Times,serif" font-size="14">Vienna</text></g><g class="edge"><path fill="none" stroke="#000" d="m379.852-191.083 16.211-4.986"/></g><g class="node"><path fill="none" stroke="#000" d="M434.242-131.724h-54v36h54v-36z"/><text text-anchor="middle" x="407.242" y="-109.524" font-family="Times,serif" font-size="14">Minsk</text></g><g class="edge"><path fill="none" stroke="#000" d="m364.356-163.33 27.143 31.396"/></g><g class="node"><path fill="none" stroke="#000" d="M403.766-278.671h-54v36h54v-36z"/><text text-anchor="middle" x="376.766" y="-256.471" font-family="Times,serif" font-size="14">Kiev</text></g><g class="edge"><path fill="none" stroke="#000" d="M355.176-199.854c4.54-12.792 10.572-29.782 15.106-42.552"/></g><g class="edge"><path fill="none" stroke="#000" d="M226.597-21.316 121.245-34.18"/></g><g class="node"><path fill="none" stroke="#000" d="M485.971-294.276h-64.953v36h64.953v-36z"/><text text-anchor="middle" x="453.495" y="-272.076" font-family="Times,serif" font-size="14">Bucarest</text></g><g class="edge"><path fill="none" stroke="#000" d="m404.034-266.217 16.766-3.41"/></g><g class="edge"><path fill="none" stroke="#000" d="M446.123-258.226c-4.395 10.76-9.96 24.384-14.371 35.187"/></g></g></svg>

<label>A fictional rail network between European cities.</label>

If we look closely, these three graphs can be characterized by two important properties: 
- the first two are directed, meaning the edges have an intrinsic direction (e.g. "Eat breakfast" comes after "Wake up"), while the third is undirected, meaning the edges don't have a direction (e.g. "Paris" is connected to "Berlin" and vice-versa).
- the last two contain cycles, meaning you can start at a node and follow the edges to come back to the same node, while the first doesn't. 

Additionally, the first one is a tree, or more pedantically a directed tree. In a tree, there exists at most one path between any two nodes.

## Doing Stuff

A useful thing to do with graphs of things is to find **paths** between things, or more usefully, the **shortest path** between two things. 

For example, in the first graph, this would be somewhat equivalent to trying to find a folder named "Documents" that is located somewhere on the disk (but whose exact location we do not know). The path would be the sequence of folders you need to go through to reach "Documents", here <kbd>C:\</kbd> → <kbd>Users</kbd> → <kbd>Alice</kbd> → <kbd>Documents</kbd>, or written as an (aptly-named) path, <code>C:\Users\Alice\Documents</code>. We would say that path has a **length** of 3, since we had to go down three levels to find our target. It's easy to see, for this small graph, that this is the shortest path, and that it is unique.

Finding a path in the second graph is not really interesting since it's just a circle. The shortest path between two nodes always consists of simply going around the circle from the first node to the second.

In the third graph, finding a path would be like finding a **train route** between two cities. For example, to go from Paris to Milan, you could take the train from Paris to Rome, then from Rome to Milan. The path would be <code>Paris → Rome → Milan</code>. This path has a length of 2. Of course, you could also go through Brussels and Berlin, that would be a valid path, but it would not be the shortest.

In real life, graphs can contain a multitude of additional information, like the cost of going from one node to another (which, here, could be the time it takes to travel between two cities, or the amount of fuel needed, or the cost of a train ticket, etc), in which case the graph is said to be **weighted**, and the shortest path ends up not simply being the path that has the fewest edges, but the one that has the smallest sum of costs.

In any case, here, we'll mostly be interested in undirected, unweighted graphs, such as the third one here (so, assume this is what "graph" means from now on). TODO ??

## Searches & Traversals

An interesting (to me, hopefully to you) question we can ask ourselves about a given graph is: what are the possible ways to visit all the nodes in the graph? This is called a **traversal**.

There are two common ways to traverse a graph, which are kind of each other's dual: **depth-first search** (DFS) and **breadth-first search** (BFS).

<style>
    .algo-viewer-inner {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;

        & > div {
            @media (min-width: 800px) {
                width: 50%;
            }
        }

        svg {
            height: auto;
            margin: 10pt auto;
        }

        .algo-title {
            position: absolute;
            margin-top: 16pt;
            color: var(--text-color);
            background-color: rgba(128, 128, 128, 0.3);
            border-radius: 4pt;
            padding: 3pt;
            line-height: normal;
        }
    }

    .algo-viewer {   
        & svg {
            .node {
                &.queued {
                    --border: red;
                }

                &.visited {
                    --fill: #4fdd4f;
                    @container style(--theme: "dark") {
                        & {
                            --fill: #123b12;
                        }
                    }
                }

                &.current {
                    --fill: #9bd1ff;
                    @container style(--theme: "dark") {
                        & {
                            --fill: #102b43;
                        }
                    }
                }

                &.found {
                    --fill: #ed52ed;
                    @container style(--theme: "dark") {
                        & {
                            --fill: #4b004b;
                        }
                    }
                }
            }
        }
    }

    .algo-controls {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 1rem;
        max-width: 500px;
    }

    .algo-controls-container {
        place-items: center;
        padding: 4pt 0;
    }

    .algo .nav {
        width: 100%;

        & > li { 
            @media (min-width: 800px) {
                flex: 1;
            }
            
            text-align: center;

            & > a {
                color: var(--text-muted-color) !important;
                border-bottom: 1px solid currentColor !important;
            }

            a:hover {
                color: var(--toc-highlight) !important;
                border-bottom-width: 3px !important;
            }

            &.active a {
                color: var(--toc-highlight) !important;
                font-weight: 600;
                border-bottom-width: 3px !important;
            }
        }

        &:has(li:only-child) {
            display: none;
        }
    }
</style>

<template id="algo-viewer">
    <div class="algo">
        <ul class="nav">
        </ul>

        <div class="algo-viewer">
            <div class="algo-viewer-inner">
            </div>
        </div>

        <div class="algo-controls-container">
            <div class="algo-controls">
                <button class="btn btn-primary algo-controls-prev">Previous</button>
                <span class="slider-bound">0</span>
                <input class="form-range" type="range" min="0" max="100" value="0">
                <span class="slider-bound"></span>
                <button class="btn btn-primary algo-controls-next">Next</button>
            </div>
        </div>
    </div>
</template>

<div id="traversal">
    <!--
    digraph G {
    "Legend:" [shape=none];
    "Visited" [class="visited"];
    "Current" [class="current"];
    "Queued" [class="queued"];
    }
    -->
    <svg xmlns="http://www.w3.org/2000/svg" width="365pt" height="44pt" viewBox="0 0 365 44"><g class="graph" transform="translate(4 40)"><path fill="#fff" d="M-4 4v-44h365V4H-4z"/><g class="node"><text text-anchor="middle" x="30.93" y="-13.8" font-family="Times,serif" font-size="14">Legend:</text></g><g class="node visited"><ellipse fill="none" stroke="#000" cx="118.93" cy="-18" rx="38.93" ry="18"/><text text-anchor="middle" x="118.93" y="-13.8" font-family="Times,serif" font-size="14">Visited</text></g><g class="node current"><ellipse fill="none" stroke="#000" cx="215.93" cy="-18" rx="40.54" ry="18"/><text text-anchor="middle" x="215.93" y="-13.8" font-family="Times,serif" font-size="14">Current</text></g><g class="node queued"><ellipse fill="none" stroke="#000" cx="315.93" cy="-18" rx="41.07" ry="18"/><text text-anchor="middle" x="315.93" y="-13.8" font-family="Times,serif" font-size="14">Queued</text></g></g></svg>   
</div>

<script>
    /**
     * Parses a graphviz adjacency list from a string.
     * @param {string} dot The graphviz dot string.
     * @returns {Object<string, string[]>} The adjacency list.
     */
    function parseAdjacency(dot) {
        const lines = dot.split("\n");
        const adjList = {};
        function edge(a, b, bidi) {
            if (a in adjList) {
                adjList[a].push(b);
            } else {
                adjList[a] = [b];
            }
            if (bidi) {
                edge(b, a, false);
            }
        }
        for (const line of lines) {
            if (!/(->|--)/.test(line) || !/"/.test(line))
                continue;
            // quick and dirty graphviz tokenization
            let tokens = JSON.parse("[" + line.trim()
                .replace(/->/g, ',false,').replace(/--/g, ',true,')
                .replace(/;/g, "")
                .replace(/\{/g, "[").replace(/\}/g, "]")
                .replace(/ \s+/, " ")
                + "]");
            while (true) {
                let [head, op, next, ...rest] = tokens;
                if (Array.isArray(next)) {
                    for (const val of next) {
                        edge(head, val, op);
                    }
                } else {
                    edge(head, next, op);
                }
                if (rest.length === 0)
                    break;
                tokens = [next, ...rest];
            }
        }
        if (Object.keys(adjList).length === 0) {
            throw new Error("No edges found in graph.");
        }
        return adjList;
    }

    /**
     * Enables or disables a class on a node.
     * @param {Element} node The node to modify.
     * @param {string} cls The class to add or remove.
     * @param {boolean} add Whether to add or remove the class.
     */
    function setClass(node, cls, add) {
        if (add) {
            node.classList.add(cls);
        } else {
            node.classList.remove(cls);
        }
    }

    function createGraphNode(origSvg, adj, title) {
        const svg = origSvg.cloneNode(true);
        const div = document.createElement("div");
        if (title) {
            const label = document.createElement("span");
            label.classList.add("algo-title");
            label.textContent = title;
            div.appendChild(label);
        }
        div.appendChild(svg);
        const nodeMap = Object.fromEntries(svg.querySelectorAll(".node").values().map(node => [node.querySelector("text").textContent, {svgNode: node}]));

        return {
            node: div,
            nodeMap: nodeMap
        };
    }

    function getState(states, idx) {
        return states[Math.min(states.length - 1, idx)];
    }

    function initAlgo(elemId, {algos, postInit, fixedStep}, graphs=null) {
        const result = document.getElementById(elemId);
        let templ = document.getElementById("algo-viewer").content.cloneNode(true);
        const main = templ.querySelector(".algo");
        const viewer = main.querySelector(".algo-viewer");
        const svg = result.querySelector("svg");
        viewer.appendChild(svg);

        if (fixedStep !== undefined) {
            main.querySelector(".algo-controls").style.display = "none";
        }

        const container = main.querySelector(".algo-viewer-inner");
        const slider = main.querySelector("input[type='range']");

        main.querySelector(".algo-controls-prev").addEventListener("click", function() {
            slider.value = Math.max(0, parseInt(slider.value) - 1);
            updateView();
        });

        main.querySelector(".algo-controls-next").addEventListener("click", function() {
            slider.value = Math.min(parseInt(slider.value) + 1, slider.max);
            updateView();
        });


        let algoStates = null;

        function initStates(svg, adj, rec=0) {
            if (rec > 10000) {
                debugger;
                return;
            }
            let oldState = algoStates;

            container.innerHTML = "";
            let nodes = Object.entries(algos).map(([name, {name: algoName, states}]) => {
                let node = createGraphNode(svg, adj, algoName);
                container.appendChild(node.node);
                return [name, [node, states(adj, main)]];
            });

            slider.value = 0;
            slider.max = Math.max(...nodes.map(([name, [node, states]]) => states.length - 1));
            slider.nextSibling.textContent = slider.max;

            if (fixedStep !== undefined) {
                slider.value = fixedStep;
            }

            algoStates = Object.fromEntries(nodes);

            if (JSON.stringify(oldState) !== JSON.stringify(algoStates)) {   
                for (const [key, state] of Object.entries(algoStates)) {
                    algos[key].customGraphUpdate?.(main, state, () => initStates(svg, adj, rec+1));
                } 
            }

            updateView();
        }
        
        function updateView() {
            let idx = parseInt(slider.value);

            main.querySelector(".algo-controls-prev").disabled = idx === 0;
            main.querySelector(".algo-controls-next").disabled = idx == slider.max;

            main.querySelectorAll(".queue-index").forEach(el => el.remove());
            
            for (const [key, algoState] of Object.entries(algoStates)) {
                const [graph, states] = algoState;
                const state = getState(states, idx);
                for (const [node, {svgNode}] of Object.entries(graph.nodeMap)) {
                    setClass(svgNode, "visited", state.visited.has(node));
                    setClass(svgNode, "current", state.current.includes(node));
                    setClass(svgNode, "queued", state.queue.includes(node));

                    const queueIndex = state.queue.indexOf(node);
                    if (queueIndex !== -1) {
                        const {x, y, width, height} = svgNode.getBBox();
                        const origText = svgNode.querySelector("text");
                        const newText = document.createElementNS("http://www.w3.org/2000/svg", "text");
                        newText.textContent = queueIndex + 1;
                        newText.setAttribute("x", x + width);
                        newText.setAttribute("y", y + height / 2 + origText.getBBox().height / 2);
                        newText.setAttribute("text-anchor", "end");
                        newText.setAttribute("font-size", origText.getAttribute("font-size"));
                        newText.classList.add("queue-index");
                        svgNode.appendChild(newText);
                    }
                }
                algos[key].customNodeUpdate?.(algoState, idx);
            }
        }
        
        slider.addEventListener("input", updateView);

        const nav = main.querySelector(".nav");
        graphs ||= document.querySelectorAll("script[type='graphviz']:not(.skip)");

        const aboveSvg = result.querySelector(".above-svg");

        if (aboveSvg !== null) {
            main.insertBefore(aboveSvg, viewer);
        }
        for (const graph of graphs) {
            const name = graph.getAttribute("name");
            const svg = graph.nextElementSibling;
            const adj = parseAdjacency(graph.textContent);

            const li = document.createElement("li");
            li.classList.add("nav-item");
            li.innerHTML = `<a class="nav-link" href="#" onclick="return false;">${name}</a>`;
            nav.appendChild(li);

            let handler = function() {
                for (const item of nav.children) {
                    item.classList.remove("active");
                }
                li.classList.add("active");
                initStates(svg, adj);
            };

            li.addEventListener("click", handler);
        }

        if (postInit) {
            postInit(main);
        }

        result.appendChild(templ);

        main.querySelector(".nav li:first-child a").click();
    }

    /**
     * Runs a traversal algorithm on a graph.
     * @param {Object<string, string[]>} adj The adjacency list.
     * @param {(queue: string[]) => string} succ The successor function.
     * @param {(neighb: string[]) => string[]} neighb The neighbor list processing function.
     * @returns {Object[]} The traversal states.
     */
    function initTraversal(adj, startNode, {succ, neighb}) {
        neighb ||= nb => nb;

        let state = {
            queue: [startNode],
            visited: new Set(),
            current: [],
            pred: {}
        };
        let states = [{
            queue: [startNode],
            visited: new Set(),
            current: [],
            pred: state.pred
        }];
        const step = () => {
            if (states.length > 1000) {
                // something happened
                console.error("Too many states");
                return false;
            }
            while (state.queue.length > 0) {
                let node = succ(state.queue);
                if (state.visited.has(node)) {
                    continue;
                }
                state.visited.add(node);
                state.current = [node];
                const nbs = neighb(adj[node] || [], state, node);
                if (nbs === null) {
                    states.push({
                        ...state,
                        current: [],
                    }); 
                    return {newState: states[states.length - 1], continue: false};
                }
                for (const edge of nbs) {
                    if (!state.visited.has(edge)) {
                        state.pred[edge] = node;
                        state.queue.push(edge);
                    }
                }
                states.push({
                    ...state,
                    queue: state.queue.slice(),
                    visited: new Set(state.visited),
                    current: [node]
                });
                return {newState: states[states.length - 1], continue: true};
            }
            states.push({
                ...state,
                current: [],
            }); 
            return {newState: states[states.length - 1], continue: false};
        };
        return {
            states,
            step
        };
    }

    function runTraversal(adj, startNode, extra) {
        const {states, step} = initTraversal(adj, startNode, extra);
        while (step().continue) {}
        return states;
    }

    document.addEventListener("DOMContentLoaded", function() {   
        initAlgo("traversal", {
            algos: {
                bfs: {
                    name: "BFS",
                    states(adj) { return runTraversal(adj, Object.keys(adj)[0], {succ: queue => queue.shift()}); }
                },
                dfs: {
                    name: "DFS",
                    states(adj) { return runTraversal(adj, Object.keys(adj)[0], {succ: queue => queue.pop(), neighb: nb => nb.toReversed()}); }
                }
            }
        });
    });
</script>

<!--Say you're looking for any node that matches a condition. The first file with a name starting with "X". The first city with sunny weather. You could just pick a node randomly, check if it matches the condition, and if it doesn't, just pick another node at random again. With infinite time, you would eventually find a node that matches the condition, if such a node exists, but you would agree that this is probably not the most efficient way to do it. The most obvious pain point is that you would most likely visit the same nodes multiple times, which is a waste of time.-->

Try playing with the above demo to get a feel for how these two algorithms work. You can see that DFS explores the graph by going as deep as 
possible along each branch, before backtracking ("climbing back up the tree") and exploring another branch. BFS, on the other hand, explores the graph by visiting all the nodes at a given depth before moving on to the next depth.

Even for graphs that contain cycles, such as the cities one, all nodes will be visited exactly once, because the algorithms keep a set of visited nodes to avoid visiting the same node multiple times.

Both of these algorithms have their uses, the DFS for example can be used to efficiently detect cycles or solve mazes.

## Finding Paths

As surprising as it may be, there is actually a quite simple algorithm to find the shortest path between two nodes in a graph: the BFS. 

Think about it, the BFS visits the source node, then its neighbors, then its neighbors' neighbors, and so on: one level of depth at a time. This means that to find the shortest path from the source to a destination, we just have to run a BFS starting from the source, and stop as soon as we reach the destination. The path we followed to reach the destination is necessarily the shortest.

If the nodes $a$ and $b$ are at a distance $D$ from each other, and we run a BFS from $a$, we'll visit nodes at depth 0 (that's just $a$), then nodes at depth 1 ($a$'s neighbors), and so on, and when we reach $b$, the depth we are currently visiting is the distance between $a$ and $b$, that is: $D$.

Seen from the other way around, it's impossible to reach $b$ in more than $D$ levels, because if it we're at some level $L>D$, it means we've already visited the entirety of level $D$, which includes $b$.

Here's a demo. If no node is highlighted and no path is displayed at the end, then it means no path exists between the two nodes. 

<style>
    .computed-path path {
        fill: none;
        stroke: rgba(255, 0, 255, 0.7);
        stroke-width: 5;
    }
</style>

<template id="shortestpath-template">
    <div class="above-svg row">
        <div class="col-sm-6 col-12 mt-2">
            <div class="input-group">
                <label class="input-group-text">Source</label>
                <select class="form-select">
                </select>
            </div>
        </div>
        <div class="col-sm-6 col-12 mt-2">
            <div class="input-group">
                <label class="input-group-text">Destination</label>
                <select class="form-select">
                </select>
            </div>
        </div>
    </div>
        <!--
    digraph G {
    "Legend:" [shape=none];
    "Visited" [class="visited"];
    "Current" [class="current"];
    "Queued" [class="queued"];
    "Found" [class="found"];
    }
    -->
    <svg xmlns="http://www.w3.org/2000/svg" width="455pt" height="44pt" viewBox="0 0 454.66 44"><g class="graph" transform="translate(4 40)"><path fill="#fff" d="M-4 4v-44h454.66V4H-4z"/><g class="node"><text text-anchor="middle" x="30.93" y="-13.8" font-family="Times,serif" font-size="14">Legend:</text></g><g class="node visited"><ellipse fill="none" stroke="#000" cx="118.93" cy="-18" rx="38.93" ry="18"/><text text-anchor="middle" x="118.93" y="-13.8" font-family="Times,serif" font-size="14">Visited</text></g><g class="node current"><ellipse fill="none" stroke="#000" cx="215.93" cy="-18" rx="40.54" ry="18"/><text text-anchor="middle" x="215.93" y="-13.8" font-family="Times,serif" font-size="14">Current</text></g><g class="node queued"><ellipse fill="none" stroke="#000" cx="315.93" cy="-18" rx="41.07" ry="18"/><text text-anchor="middle" x="315.93" y="-13.8" font-family="Times,serif" font-size="14">Queued</text></g><g class="node found"><ellipse fill="none" stroke="#000" cx="410.93" cy="-18" rx="35.72" ry="18"/><text text-anchor="middle" x="410.93" y="-13.8" font-family="Times,serif" font-size="14">Found</text></g></g></svg>
</template>

<div id="shortestpath">
</div>

<script>
    function pathGraphUpdate(node, algoState, refresh, defSrc=null, defDst = null) {
        let [src, dst] = node.querySelectorAll("select");
        const adj = algoState[0].nodeMap;

        let oldSrc = src.value;
        src.innerHTML = "";

        let srcClone = src.cloneNode(true);
        src.parentNode.replaceChild(srcClone, src);
        src = srcClone;

        const nodeList = Object.keys(adj);
        nodeList.sort();

        for (const name of nodeList) {
            const opt = document.createElement("option");
            opt.value = name;
            opt.textContent = name;
            src.appendChild(opt);
        }

        if (oldSrc in adj) {
            src.value = oldSrc;
        } else {
            src.value = defSrc || Object.keys(adj)[0];
        }

        function recalc() {
            refresh();      
        }

        function updateDst() {
            const start = src.value;
            let oldDst = dst.value;
            dst.innerHTML = "";
            let dstClone = dst.cloneNode(true);
            dst.parentNode.replaceChild(dstClone, dst);
            dst = dstClone;
            for (const name of nodeList) {
                if (name === start) {
                    continue;
                }
                const opt = document.createElement("option");
                opt.value = name;
                opt.textContent = name;
                dst.appendChild(opt);
            }
            if (oldDst in adj && oldDst !== start) {
                dst.value = oldDst;
            } else {
                dst.value = defDst || Object.keys(adj)[nodeList.length - 1];
            }
            dst.addEventListener("change", recalc);
            recalc();
        }

        src.addEventListener("change", updateDst);

        updateDst();
    }

    function pathNodeUpdate(algoState, idx, path) {
        const [graph, states] = algoState;
        const state = getState(states, idx);
        for (const [node, {svgNode}] of Object.entries(graph.nodeMap)) {
            setClass(svgNode, "found", state.found === node);
        }

        const svgRoot = graph.node.querySelector("svg > g");

        svgRoot.querySelector(".computed-path")?.remove();

        if (path?.length > 1) {
            const pathNode = document.createElementNS("http://www.w3.org/2000/svg", "g");
            pathNode.classList.add("computed-path");
            svgRoot.insertBefore(pathNode, svgRoot.firstChild);

            function getPos(node) {
                const nodeTag = graph.nodeMap[node].svgNode.querySelector(":not(text)");
                const {x, y, width, height} = nodeTag.getBBox();
                return [x + width / 2, y + height / 2];
            }

            for (const [current, next] of path.slice(1).map((val, idx) => [path[idx], val])) {
                const edge = document.createElementNS("http://www.w3.org/2000/svg", "path");
                edge.setAttribute("d", `M${getPos(current).join(" ")} ${getPos(next).join(" ")}`);
                pathNode.appendChild(edge);
            }
        }
    }

    function bfsNodeUpdate(algoState, idx) {
        const [graph, states] = algoState;
        const state = getState(states, idx);
        let current = state.found;
        const path = [current];
        if (current) {
            let next;
            while ((next = state.pred[current]) !== undefined) {
                current = next;
                path.push(next);
            }
        }
        pathNodeUpdate(algoState, idx, path);
    }

    function bfsPathStates(adj, node) { 
        const [src, dst] = node.querySelectorAll("select");
        return runTraversal(adj, src.value, {
            succ: queue => queue.shift(), 
            neighb(nb, state, node) {
                if (nb.includes(dst.value)) {
                    state.pred[dst.value] = node;
                    state.found = dst.value;
                    return null;
                }
                return nb;
            }
        });
    }

    document.addEventListener("DOMContentLoaded", function() {   
        document.getElementById("shortestpath").appendChild(document.getElementById("shortestpath-template").content.cloneNode(true));
        initAlgo("shortestpath", {
            algos: {
                bfs: {
                    name: "BFS",
                    states: bfsPathStates,
                    customNodeUpdate: bfsNodeUpdate,
                    customGraphUpdate: pathGraphUpdate
                }
            }, 
            
        });
    });
</script>

## Finding Paths, Faster

The BFS is a great algorithm to find the shortest path between two nodes. So great, in fact, that it's the **optimal algorithm** for the general case. That's right. "But what about all those fast algorithms I've heard about, like Dijkstra's or A*?" you might ask. Well, two things:

- Dijkstra's algorithm is a BFS. It's a generalized BFS, that handles giving different costs/weights to edges. 
- The A* algorithm relies on the programmer providing a **heuristic** function that estimates the cost of reaching the destination from a given node. If the heuristic is well-chosen, A* will be faster than BFS, sure, but for a lot of cases, that's a big if. This is why I specifically said "general case": for a given graph $G$ that you know nothing about, BFS is the best you can do. A* is for when you know more about the graph, and can exploit that knowledge to make the search faster.

My use case (large social graphs) doesn't have good, fast to compute cost functions that can be used as heuristics for algorithms such as A*, so I'm sticking with BFS. So, is BFS the fastest we can do? There is actually a slight variation of BFS that can be a lot faster in some cases: the **bidirectional BFS**. 

A bidirectional search, as the name suggests, is simply a search that is performed from both the source and the destination nodes at the same time. The idea is that the two searches will meet somewhere in the middle, and the path between the two meeting points will be the shortest path between the two nodes.

Formally, when we study graphs, we can introduce a measure called the **branching factor**, which is the average outgoing number of nodes from a given node in the graph. In a binary tree, the branching factor is 2, because each node has at most 2 children. 

<style>
    svg {
        .cluster > path {
            stroke-dasharray: 5;
            stroke: #4d58ff;

            @container style(--theme: "dark") {
                & {
                    stroke: #4b53cf;
                }
            }
        }
    }
</style>

<!--
digraph G {
  rankdir=LR;
  A -> {B1, B2};
  B1 -> {C1, C2};
  B2 -> {C3, C4};
  {C1,C2,C3,C4} -> D [style=invis];
  subgraph cluster_0 {
      A;
      label = "0"
  }
  subgraph cluster_1 {
      B1, B2;
      label = "1";
  }
  
  subgraph cluster_2 {
      C1, C2, C3, C4;
      label = "2"
  }
  subgraph cluster_3 {
      D [shape=none,label=<2<sup>N</sup> nodes>];
      label = "N";
  }
}
-->
<svg xmlns="http://www.w3.org/2000/svg" width="379pt" height="263pt" viewBox="0 0 379.27 263"><g class="graph" transform="translate(4 259)"><path fill="#fff" d="M-4 4v-263h379.27V4H-4z"/><g class="cluster"><path fill="none" stroke="#000" d="M8-89v-77h70v77H8z"/><text text-anchor="middle" x="43" y="-149.4" font-family="Times,serif" font-size="14">0</text></g><g class="cluster"><path fill="none" stroke="#000" d="M98-62v-131h70v131H98z"/><text text-anchor="middle" x="133" y="-176.4" font-family="Times,serif" font-size="14">1</text></g><g class="cluster"><path fill="none" stroke="#000" d="M188-8v-239h70V-8h-70z"/><text text-anchor="middle" x="223" y="-230.4" font-family="Times,serif" font-size="14">2</text></g><g class="cluster"><path fill="none" stroke="#000" d="M278-89v-77h85.27v77H278z"/><text text-anchor="middle" x="320.64" y="-149.4" font-family="Times,serif" font-size="14">N</text></g><g class="node"><ellipse fill="none" stroke="#000" cx="43" cy="-115" rx="27" ry="18"/><text text-anchor="middle" x="43" y="-110.8" font-family="Times,serif" font-size="14">A</text></g><g class="node"><ellipse fill="none" stroke="#000" cx="133" cy="-88" rx="27" ry="18"/><text text-anchor="middle" x="133" y="-83.8" font-family="Times,serif" font-size="14">B1</text></g><g class="edge"><path fill="none" stroke="#000" d="M68.05-107.62c8.92 2.74 19.24 5.9 28.94 8.88"/><path stroke="#000" d="m98-102.09 8.54 6.28-10.59.41 2.05-6.69z"/></g><g class="node"><ellipse fill="none" stroke="#000" cx="133" cy="-142" rx="27" ry="18"/><text text-anchor="middle" x="133" y="-137.8" font-family="Times,serif" font-size="14">B2</text></g><g class="edge"><path fill="none" stroke="#000" d="M68.05-122.38c8.92-2.74 19.24-5.9 28.94-8.88"/><path stroke="#000" d="m95.95-134.6 10.59.41-8.54 6.28-2.05-6.69z"/></g><g class="node"><ellipse fill="none" stroke="#000" cx="223" cy="-34" rx="27" ry="18"/><text text-anchor="middle" x="223" y="-29.8" font-family="Times,serif" font-size="14">C1</text></g><g class="edge"><path fill="none" stroke="#000" d="M153.53-76.02c11.62 7.14 26.58 16.32 39.55 24.27"/><path stroke="#000" d="m194.54-54.96 6.69 8.22-10.35-2.25 3.66-5.97z"/></g><g class="node"><ellipse fill="none" stroke="#000" cx="223" cy="-88" rx="27" ry="18"/><text text-anchor="middle" x="223" y="-83.8" font-family="Times,serif" font-size="14">C2</text></g><g class="edge"><path fill="none" stroke="#000" d="M160.4-88h23.8"/><path stroke="#000" d="m184.1-91.5 10 3.5-10 3.5v-7z"/></g><g class="node"><ellipse fill="none" stroke="#000" cx="223" cy="-142" rx="27" ry="18"/><text text-anchor="middle" x="223" y="-137.8" font-family="Times,serif" font-size="14">C3</text></g><g class="edge"><path fill="none" stroke="#000" d="M160.4-142h23.8"/><path stroke="#000" d="m184.1-145.5 10 3.5-10 3.5v-7z"/></g><g class="node"><ellipse fill="none" stroke="#000" cx="223" cy="-196" rx="27" ry="18"/><text text-anchor="middle" x="223" y="-191.8" font-family="Times,serif" font-size="14">C4</text></g><g class="edge"><path fill="none" stroke="#000" d="M153.53-153.98c11.62-7.14 26.58-16.32 39.55-24.27"/><path stroke="#000" d="m190.88-181.01 10.35-2.25-6.69 8.22-3.66-5.97z"/></g><g class="node"><text x="294" y="-111.8" font-family="Times,serif" font-size="14">2</text><text x="301" y="-111.8" font-family="Times,serif" baseline-shift="super" font-size="14">N</text><text x="311.11" y="-111.8" font-family="Times,serif" font-size="14"> nodes</text></g></g></svg>

The total number of nodes in such a graph is approximated by $b^d$, where $b$ is the branching factor and $d$ is the depth of the tree.

When a standard BFS goes through a graph with branching factor $b$, it recursively visits all the neighbors of all the nodes, level by level. At level 0, it visits 1 node (the source). At level 1, it visits all the neighbors of the source, that is, $b$ (on average). At level 2, all the neighbors' neighbors, that is, $b^2$. At level $L$, it visits $b^L$ nodes. In total, if you're trying to find the path between two nodes that are, say, 10 edges apart, the BFS will visit $1 + b + b^2 + \ldots + b^{10}$ nodes, which is in the order of $b^{10}$. For a binary tree, that would be $2^{10} = 1024$ nodes.

Let's say, now, that we're starting one BFS from the source, and one from the destination, and at each level we advance one step in each. The two BFS will meet at some point, and they must meet exactly in the middle, because they advance at the same speed (and the shortest path between two points is the sum of the path from the source to the middle, and the path from the middle to the destination). If the source and destination are $D$ edges apart, the two BFS will meet after $D/2$ steps, and the total number of nodes visited by each BFS will be $1 + b + b^2 + \ldots + b^{D/2}$, which is in the order of $b^{D/2}$. For a binary tree, that would be $2^5 = 32$ nodes (by each BFS, so, $64$ visited nodes in total).

We got from $1024$ to $64$ visited nodes, that's something! Specifically, from $O(b^{D})$ to $O(b^{D/2})$, which is an exponential speedup.

As a reference, finding the path between two nodes ~10 edges apart in my 2M nodes graph previously took about 2 seconds with a standard BFS, and only takes 8ms with a bidirectional BFS. That's a 250x speedup.

Here, play with it:

<div id="bidi1">
</div>

<script>
    function interleave(q1, q2, swap) {
        const newQueue = [];
        let [a, b] = [q1.slice(), q2.slice()];
        if (swap) {
            [a, b] = [b, a];
        }
        while (a.length > 0 || b.length > 0) {
            if (a.length > 0) newQueue.push(a.shift());
            if (b.length > 0) newQueue.push(b.shift());
        }
        return newQueue;
    }

    function bidiStates(adj, node, corrected=false) { 
        const [src, dst] = node.querySelectorAll("select");
        const backAdj = {};
        for (const [src, dsts] of Object.entries(adj)) {
            for (const dst of dsts) {
                if (dst in backAdj) {
                    backAdj[dst].push(src);
                } else {
                    backAdj[dst] = [src];
                }
            }
        }
        const {states: statesSrc, step: stepSrc} = initTraversal(adj, src.value, {succ: queue => queue.shift()});
        const {states: statesDst, step: stepDst} = initTraversal(backAdj, dst.value, {succ: queue => queue.shift()});
        const states = [{
            queue: statesSrc[0].queue.concat(statesDst[0].queue),
            visited: new Set(),
            current: statesSrc[0].current.concat(statesDst[0].current),
        }];
        let bothStates = [statesSrc[0], statesDst[0]];
        let found = null;

        const processQueues = corrected ? (q1, q2) => q1.concat(q2) : interleave;

        let curId = 0;
        let untilToggle = [bothStates[0].queue[0], bothStates[1].queue[0]];
        while (true) {
            const step = [stepSrc, stepDst][curId];
            const curState = step();
            bothStates[curId] = curState.newState;
            if (corrected) {
                let newState = curState.newState;
                let newQueueLen = newState.queue.length;
                if (newState.current[0] === untilToggle[curId]) {
                    untilToggle[curId] = newState.queue[newQueueLen - 1];
                    curId = 1 - curId;
                }
            } else {
                curId = 1 - curId;
            }

            const [stateSrc, stateDst] = bothStates;

            let inter = Object.keys(adj).find(node => 
                (stateSrc.visited.has(node) || stateSrc.queue.includes(node)) &&
                (stateDst.visited.has(node) || stateDst.queue.includes(node)));
            if (inter) {
                found = inter;
                break;
            }

            const newQueue = processQueues(stateSrc.queue, stateDst.queue, states.length % 2 === 1);

            states.push({
                queue: newQueue,
                visited: new Set([...stateSrc.visited, ...stateDst.visited]),
                current: stateSrc.current.concat(stateDst.current)
            });

            if (!curState.continue) {
                break;
            }


        }
        const [lastSrc, lastDst] = [statesSrc[statesSrc.length - 1], statesDst[statesDst.length - 1]];
        const last = {
            queue: processQueues(lastSrc.queue, lastDst.queue, states.length % 2 === 1),
            visited: new Set([...lastSrc.visited, ...lastDst.visited]),
            current: lastSrc.current.concat(lastDst.current),
            predSrc: lastSrc.pred,
            predDst: lastDst.pred,
            found
        };
        states.push(last);
        return states;
    }

    function bidiUpdate(algoState, idx) {
        const [graph, states] = algoState;
        const state = getState(states, idx);
        let current = state.found;
        const path = [current];
        if (current) {
            let next;
            while ((next = state.predSrc[current]) !== undefined) {
                current = next;
                path.push(next);
            }
            path.reverse();
            current = state.found;
            while ((next = state.predDst[current]) !== undefined) {
                current = next;
                path.push(next);
            }
        }

        pathNodeUpdate(algoState, idx, path);
    }

    document.addEventListener("DOMContentLoaded", function() {   
        document.getElementById("bidi1").appendChild(document.getElementById("shortestpath-template").content.cloneNode(true));
        initAlgo("bidi1", {
            algos: {
                bidiBfs: {
                    name: "BidiBFS",
                    states: bidiStates,
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate: pathGraphUpdate
                }
            }, 
        });
    });
</script>

## Finding the Wrong Path

My explanation of the bidirectional BFS might sound like it's correct, and the demo might look like it's working, but there's actually a small, minuscule, tiny mistake that makes it all wrong. Well, not all wrong, it works for the demo! But it can give the wrong answer, *sometimes*. Here, try it with this pathological case:

<style>
    script.bidi2 + svg {
        display: none;
    }

    #bidi2 div.above-svg {
        display: none;
    }
</style>
<script type="graphviz" name="Pathological case" class="bidi2 skip">
digraph G {
  rankdir=LR;
  node[ shape=circle];
  "S" -> "a1" -> "a2" -> "a3" -> "T";
  "S" -> "b1" -> "b2" -> "T";
  subgraph cluster_x {
      b1, a2;
      style=invis
  }
}
</script>
<svg xmlns="http://www.w3.org/2000/svg" width="347pt" height="140pt" viewBox="0 0 347.08 140"><g class="graph" transform="translate(4 136)"><path fill="#fff" d="M-4 4v-140h347.08V4H-4z"/><g class="node"><circle fill="none" stroke="#000" cx="18" cy="-66" r="18"/><text text-anchor="middle" x="18" y="-61.8" font-family="Times,serif" font-size="14">S</text></g><g class="node"><circle fill="none" stroke="#000" cx="92.15" cy="-93" r="20.15"/><text text-anchor="middle" x="92.15" y="-88.8" font-family="Times,serif" font-size="14">a1</text></g><g class="edge"><path fill="none" stroke="#000" d="M35.37-72.13c7.92-2.96 17.67-6.61 26.8-10.02"/><path stroke="#000" d="m60.8-85.38 10.6-.23-8.14 6.79-2.46-6.56z"/></g><g class="node"><circle fill="none" stroke="#000" cx="169" cy="-37" r="20.69"/><text text-anchor="middle" x="169" y="-32.8" font-family="Times,serif" font-size="14">b1</text></g><g class="edge"><path fill="none" stroke="#000" d="M36.09-62.67c24.67 4.8 70.66 13.75 101.28 19.71"/><path stroke="#000" d="m137.64-46.47 9.15 5.34-10.48 1.53 1.33-6.87z"/></g><g class="node"><circle fill="none" stroke="#000" cx="169" cy="-96" r="20.15"/><text text-anchor="middle" x="169" y="-91.8" font-family="Times,serif" font-size="14">a2</text></g><g class="edge"><path fill="none" stroke="#000" d="M112.43-93.77c7.53-.3 16.36-.66 24.74-.99"/><path stroke="#000" d="m136.88-98.26 10.13 3.1-9.85 3.9-.28-7z"/></g><g class="node"><circle fill="none" stroke="#000" cx="246.38" cy="-96" r="20.15"/><text text-anchor="middle" x="246.38" y="-91.8" font-family="Times,serif" font-size="14">a3</text></g><g class="edge"><path fill="none" stroke="#000" d="M189.41-96h24.92"/><path stroke="#000" d="m214.26-99.5 10 3.5-10 3.5v-7z"/></g><g class="node"><circle fill="none" stroke="#000" cx="321.08" cy="-66" r="18"/><text text-anchor="middle" x="321.08" y="-61.8" font-family="Times,serif" font-size="14">T</text></g><g class="edge"><path fill="none" stroke="#000" d="M265.35-88.58c8.58 3.54 19.02 7.84 28.47 11.74"/><path stroke="#000" d="m294.98-80.14 7.91 7.05-10.58-.58 2.67-6.47z"/></g><g class="node"><circle fill="none" stroke="#000" cx="246.38" cy="-37" r="20.69"/><text text-anchor="middle" x="246.38" y="-32.8" font-family="Times,serif" font-size="14">b2</text></g><g class="edge"><path fill="none" stroke="#000" d="M189.8-37h24.14"/><path stroke="#000" d="m213.93-40.5 10 3.5-10 3.5v-7z"/></g><g class="edge"><path fill="none" stroke="#000" d="M266.1-44.47c8.38-3.34 18.4-7.34 27.52-10.98"/><path stroke="#000" d="m292.14-58.62 10.58-.46-7.99 6.96-2.59-6.5z"/></g></g></svg>

<div id="bidi2">
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {   
        document.getElementById("bidi2").appendChild(document.getElementById("shortestpath-template").content.cloneNode(true));

        initAlgo("bidi2", {
            algos: {
                bidiBfs: {
                    name: "BidiBFS",
                    states: bidiStates, 
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate(node, algoState, refresh) {
                        pathGraphUpdate(node, algoState, refresh, "S", "T");
                    }
                },
                bfs: {
                    name: "BFS",
                    states: bfsPathStates,
                    customNodeUpdate: bfsNodeUpdate
                },
            }
        }, document.querySelectorAll("script.bidi2[type='graphviz']"));
    });
</script>

For this graph, the bidirectional BFS finds a correct path... but not a minimal one; it's one edge longer than the shortest path. 

The problem, specifically, is at this step:

<style>
    #bidi3 {
        div.above-svg, .algo-viewer > svg:last-child {
            display: none;
        }
    }
</style>

<div id="bidi3">
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {   
        document.getElementById("bidi3").appendChild(document.getElementById("shortestpath-template").content.cloneNode(true));

        initAlgo("bidi3", {
            algos: {
                bidiBfs: {
                    name: null,
                    states: bidiStates, 
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate(node, algoState, refresh) {
                        pathGraphUpdate(node, algoState, refresh, "S", "T");
                    }
                }
            },
            fixedStep: 2
        }, document.querySelectorAll("script.bidi2[type='graphviz']"));
    });
</script>

At the next step, the node <kbd>a1</kbd> will be visited. This will add <kbd>a2</kbd> to the queue, and then <kbd>a3</kbd> will be visited, which will stop the algorithm since <kbd>a2</kbd> will be found to already have been seen (since it'll already be in the queue at that point). The resulting path will be one node too long.

What happened here?

Well, to find the shortest path, it would have had to visit either <kbd>b1</kbd> or <kbd>b2</kbd> before visiting <kbd>a2</kbd>. At first glance, this may look like an ordering problem: should we visit a nodes' neighbors in a certain order? How would we sort them? 

No, the problem is deeper. The two keys to understanding the issue are:
- "[...] one level of depth at a time. This means that to find the shortest path from the source to a destination, we just have to run a BFS starting from the source, and stop as soon as we reach the destination. The path we followed to reach the destination is necessarily the shortest."
- "The two BFS will meet at some point, and they must meet exactly in the middle, because they advance at the same speed."

The BFS works because it visits all the nodes at a given depth before moving on to the next depth. This isn't what our bidirectional BFS is doing! It's stopping right after seeing <kbd>a2</kbd> without having had the chance to see the edge between <kbd>b1</kbd> and <kbd>b2</kbd>. We're getting a wrong result because our algorithm is wrong.

I wrote this in the previous section, while describing the bidirectional BFS:

> Let's say, now, that we're starting one BFS from the source, and one from the destination, and at each level we advance one step in each. 

This sounds sensible, but I didn't define what a "step" means. In the regular BFS, a step is just visiting the next node in the queue. But here, we need to consider a higher-level step: each BFS shouldn't advance one node at a time, but one level of nodes/depth at a time:

<!--
digraph G {
  rankdir=LR;
  node[ shape=circle];
  S -> a1 -> a2 -> a3 -> T;
  S -> b1 -> b2 -> T;
  subgraph cluster_0 {
      S
      label="0"
  }
  subgraph cluster_2 {
      a2
      label="2"
  }
  subgraph cluster_1 {
      b1, a1;
      #style=invis
      label="1"
  }
  subgraph cluster_3 {
      a3, b2;
      label = "1"
  }
  subgraph cluster_4 {
      T
      label = "0"
  }
}
-->
<svg xmlns="http://www.w3.org/2000/svg" width="379pt" height="220" viewBox="0 0 379.08 165"><g class="graph" transform="translate(4 161)"><path fill="#fff" d="M-4 4v-165h379.08V4H-4z"/><g class="cluster"><path fill="none" stroke="#000" d="M8-40v-77h52v77H8z"/><text text-anchor="middle" x="34" y="-100.4" font-family="Times,serif" font-size="14">0</text></g><g class="cluster"><path fill="none" stroke="#000" d="M157.39-68v-81h56.3v81h-56.3z"/><text text-anchor="middle" x="185.54" y="-132.4" font-family="Times,serif" font-size="14">2</text></g><g class="cluster"><path fill="none" stroke="#000" d="M80-8v-141h57.39V-8H80z"/><text text-anchor="middle" x="108.69" y="-132.4" font-family="Times,serif" font-size="14">1</text></g><g class="cluster"><path fill="none" stroke="#000" d="M233.69-8v-141h57.39V-8h-57.39z"/><text text-anchor="middle" x="262.38" y="-132.4" font-family="Times,serif" font-size="14">1</text></g><g class="cluster"><path fill="none" stroke="#000" d="M311.08-40v-77h52v77h-52z"/><text text-anchor="middle" x="337.08" y="-100.4" font-family="Times,serif" font-size="14">0</text></g><g class="node"><circle fill="none" stroke="#000" cx="34" cy="-66" r="18"/><text text-anchor="middle" x="34" y="-61.8" font-family="Times,serif" font-size="14">S</text></g><g class="node"><circle fill="none" stroke="#000" cx="108.69" cy="-96" r="20.15"/><text text-anchor="middle" x="108.69" y="-91.8" font-family="Times,serif" font-size="14">a1</text></g><g class="edge"><path fill="none" stroke="#000" d="M51.13-72.66c8.18-3.37 18.36-7.57 27.82-11.48"/><path stroke="#000" d="m77.58-87.36 10.58-.58-7.91 7.05-2.67-6.47z"/></g><g class="node"><circle fill="none" stroke="#000" cx="108.69" cy="-37" r="20.69"/><text text-anchor="middle" x="108.69" y="-32.8" font-family="Times,serif" font-size="14">b1</text></g><g class="edge"><path fill="none" stroke="#000" d="M51.13-59.56c8.06 3.21 18.06 7.2 27.4 10.93"/><path stroke="#000" d="M79.64-51.96 87.63-45l-10.58-.46 2.59-6.5z"/></g><g class="node"><circle fill="none" stroke="#000" cx="185.54" cy="-96" r="20.15"/><text text-anchor="middle" x="185.54" y="-91.8" font-family="Times,serif" font-size="14">a2</text></g><g class="edge"><path fill="none" stroke="#000" d="M128.97-96h24.74"/><path stroke="#000" d="m153.56-99.5 10 3.5-10 3.5v-7z"/></g><g class="node"><circle fill="none" stroke="#000" cx="262.38" cy="-96" r="20.15"/><text text-anchor="middle" x="262.38" y="-91.8" font-family="Times,serif" font-size="14">a3</text></g><g class="edge"><path fill="none" stroke="#000" d="M205.81-96h24.75"/><path stroke="#000" d="m230.4-99.5 10 3.5-10 3.5v-7z"/></g><g class="node"><circle fill="none" stroke="#000" cx="337.08" cy="-66" r="18"/><text text-anchor="middle" x="337.08" y="-61.8" font-family="Times,serif" font-size="14">T</text></g><g class="edge"><path fill="none" stroke="#000" d="M281.35-88.58c8.58 3.54 19.02 7.84 28.47 11.74"/><path stroke="#000" d="m310.98-80.14 7.91 7.05-10.58-.58 2.67-6.47z"/></g><g class="node"><circle fill="none" stroke="#000" cx="262.38" cy="-37" r="20.69"/><text text-anchor="middle" x="262.38" y="-32.8" font-family="Times,serif" font-size="14">b2</text></g><g class="edge"><path fill="none" stroke="#000" d="M129.84-37h100.68"/><path stroke="#000" d="m230.12-40.5 10 3.5-10 3.5v-7z"/></g><g class="edge"><path fill="none" stroke="#000" d="M282.1-44.47c8.38-3.34 18.4-7.34 27.52-10.98"/><path stroke="#000" d="m308.14-58.62 10.58-.46-7.99 6.96-2.59-6.5z"/></g></g></svg>

Here's the same graph as above with a corrected algorithm:

<style>
    script.bidi4 + svg {
        display: none;
    }

    #bidi4 div.above-svg {
        display: none;
    }
</style>
<script type="graphviz" name="Pathological case" class="bidi4 skip">
digraph G {
  rankdir=LR;
  node[ shape=circle];
  "S" -> "a1" -> "a2" -> "a3" -> "T";
  "S" -> "b1" -> "b2" -> "T";
  subgraph cluster_0 {
      S
      style=invis
  }
  subgraph cluster_2 {
      a2
      style=invis
  }
  subgraph cluster_1 {
      b1, a1;
      style=invis
  }
  subgraph cluster_3 {
      a3, b2;
      style=invis
  }
  subgraph cluster_4 {
      T
      style=invis
  }
}
</script>
<svg xmlns="http://www.w3.org/2000/svg" width="379pt" height="140pt" viewBox="0 0 379.08 140"><g class="graph" transform="translate(4 136)"><path fill="#fff" d="M-4 4v-140h379.08V4H-4z"/><g class="node"><circle fill="none" stroke="#000" cx="34" cy="-66" r="18"/><text text-anchor="middle" x="34" y="-61.8" font-family="Times,serif" font-size="14">S</text></g><g class="node"><circle fill="none" stroke="#000" cx="108.69" cy="-96" r="20.15"/><text text-anchor="middle" x="108.69" y="-91.8" font-family="Times,serif" font-size="14">a1</text></g><g class="edge"><path fill="none" stroke="#000" d="M51.13-72.66c8.18-3.37 18.36-7.57 27.82-11.48"/><path stroke="#000" d="m77.58-87.36 10.58-.58-7.91 7.05-2.67-6.47z"/></g><g class="node"><circle fill="none" stroke="#000" cx="108.69" cy="-37" r="20.69"/><text text-anchor="middle" x="108.69" y="-32.8" font-family="Times,serif" font-size="14">b1</text></g><g class="edge"><path fill="none" stroke="#000" d="M51.13-59.56c8.06 3.21 18.06 7.2 27.4 10.93"/><path stroke="#000" d="M79.64-51.96 87.63-45l-10.58-.46 2.59-6.5z"/></g><g class="node"><circle fill="none" stroke="#000" cx="185.54" cy="-96" r="20.15"/><text text-anchor="middle" x="185.54" y="-91.8" font-family="Times,serif" font-size="14">a2</text></g><g class="edge"><path fill="none" stroke="#000" d="M128.97-96h24.74"/><path stroke="#000" d="m153.56-99.5 10 3.5-10 3.5v-7z"/></g><g class="node"><circle fill="none" stroke="#000" cx="262.38" cy="-96" r="20.15"/><text text-anchor="middle" x="262.38" y="-91.8" font-family="Times,serif" font-size="14">a3</text></g><g class="edge"><path fill="none" stroke="#000" d="M205.81-96h24.75"/><path stroke="#000" d="m230.4-99.5 10 3.5-10 3.5v-7z"/></g><g class="node"><circle fill="none" stroke="#000" cx="337.08" cy="-66" r="18"/><text text-anchor="middle" x="337.08" y="-61.8" font-family="Times,serif" font-size="14">T</text></g><g class="edge"><path fill="none" stroke="#000" d="M281.35-88.58c8.58 3.54 19.02 7.84 28.47 11.74"/><path stroke="#000" d="m310.98-80.14 7.91 7.05-10.58-.58 2.67-6.47z"/></g><g class="node"><circle fill="none" stroke="#000" cx="262.38" cy="-37" r="20.69"/><text text-anchor="middle" x="262.38" y="-32.8" font-family="Times,serif" font-size="14">b2</text></g><g class="edge"><path fill="none" stroke="#000" d="M129.84-37h100.68"/><path stroke="#000" d="m230.12-40.5 10 3.5-10 3.5v-7z"/></g><g class="edge"><path fill="none" stroke="#000" d="M282.1-44.47c8.38-3.34 18.4-7.34 27.52-10.98"/><path stroke="#000" d="m308.14-58.62 10.58-.46-7.99 6.96-2.59-6.5z"/></g></g></svg>

<div id="bidi4">
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {   
        document.getElementById("bidi4").appendChild(document.getElementById("shortestpath-template").content.cloneNode(true));

        initAlgo("bidi4", {
            algos: {
                bidiBfs: {
                    name: "Good BidiBFS",
                    states(bidiAdj, node) {
                        return bidiStates(bidiAdj, node, true);
                    },
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate(node, algoState, refresh) {
                        pathGraphUpdate(node, algoState, refresh, "S", "T");
                    }
                },
                bidiBfsWrong: {
                    name: "Bad BidiBFS",
                    states(bidiAdj, node) {
                        return bidiStates(bidiAdj, node, false);
                    },
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate(node, algoState, refresh) {
                        pathGraphUpdate(node, algoState, refresh, "S", "T");
                    }
                },
                bfs: {
                    name: "BFS",
                    states: bfsPathStates,
                    customNodeUpdate: bfsNodeUpdate
                },
            }
        }, document.querySelectorAll("script.bidi4[type='graphviz']"));
    });
</script>

And with the example graphs (though for these, there are no cases I could find where the bad algorithm breaks):

<div id="bidi5">
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {   
        document.getElementById("bidi5").appendChild(document.getElementById("shortestpath-template").content.cloneNode(true));
        initAlgo("bidi5", {
            algos: {
                bidiBfs: {
                    name: "Good BidiBFS",
                    states(bidiAdj, node) {
                        return bidiStates(bidiAdj, node, true);
                    },
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate: pathGraphUpdate
                },
                bidiBfsWrong: {
                    name: "Bad BidiBFS",
                    states(bidiAdj, node) {
                        return bidiStates(bidiAdj, node, false);
                    },
                    customNodeUpdate: bidiUpdate,
                    customGraphUpdate: pathGraphUpdate
                },
            }, 
        });
    });
</script>

## Someone is Wrong on the Internet

![XKCD 386: guy at computer won't go to bed because "Someone is WRONG on the Internet"](https://imgs.xkcd.com/comics/duty_calls.png)
<label><https://xkcd.com/386/></label>

While working on [a project of mine](https://github.com/zdimension/graphrust) where I needed to implement some sort of pathfinding feature, I ended up wanting to implement the bidirectional BFS algorithm to replace the regular BFS I was using. A BFS is simple enough to implement, but I went the lazy route and just googled ["bidirectional bfs implementation"](https://www.google.com/search?q=bidirectional%20bfs%20implementation). I clicked on a random legit-sounding link, translated the implementation to Rust, and it worked! And it was **a lot** faster, like I said earlier, so I was happy. 

Days passed, but then, while fiddling with my project, I ended up stumbling upon a case where the path was *wrong*. Like, *one node* wrong — exactly the bug we just studied. I compared my code with the site I copied from, and I couldn't see any mistake. Well, then, I googled again, and copied from another site. Different code structure, but same bug. So I googled again, and again. Same bug, everywhere. I started to suspect that reality was playing a prank on me. *How could everyone be wrong?*

I started methodically testing every bidirectional BFS implementation I could find. Most were wrong, a few were right. Among the wrong ones, quite a few were actually just copying code from a well-known CS website (and removing comments, and renaming variables, to make it look like their own... which is nothing more than plain old **plagiarism**), while some others were original-looking code, but with the same bug.

Here are the **wrong** results I found, along with date of the earliest archive.org crawl (which is a good enough approximation of when the code was first published). All of these were found on the first or second page of Google results. **All of the links below contain wrong code**:

- (C++, Java, Python, C#, JS) [GeeksforGeeks](https://www.geeksforgeeks.org/bidirectional-search/) (~2016)
    - (C++) [The Algorists](https://www.thealgorists.com/Algo/TwoEndBFS) (plagiarizing, 2020), also hosted on their [old WordPress blog](https://efficientcodeblog.wordpress.com/2017/12/13/bidirectional-search-two-end-bfs/)
    - (Python) [AskPython](https://www.askpython.com/python/examples/bidirectional-search-in-python) (plagiarizing, 2022)
    - (Python) [Educative](https://www.educative.io/answers/how-to-use-bidirectional-search-implementation-in-python) (plagiarizing, 2022)
    - (Java) [Naukri Code 360](https://www.naukri.com/code360/library/bidirectional-search-in-graph) (plagiarizing, 2024)
    - (C++) [Educba](https://www.educba.com/bidirectional-search/) (plagiarizing, 2020)
    - (C++) An [undergrad paper](https://informatika.stei.itb.ac.id/~rinaldi.munir/Stmik/2019-2020/Makalah/Makalah-Stima-2020-022.pdf) that unfortunately ended up using GeeksforGeeks' implementation (with credits, 2020)
    - (C++) [At least 17 GitHub repositories](https://github.com/search?q=BFS%28%26s_queue%2C+s_visited&type=code) (including some advertising themselves as CS/DSA lesson material, most with no credits)
    - (Python) [At least 31 GitHub repositories](https://github.com/search?q=.bfs%28direction+%3D&type=code) (same as above)
- (JS) [Zachary Freeman](https://medium.com/@zdf2424/discovering-the-power-of-bidirectional-bfs-a-more-efficient-pathfinding-algorithm-72566f07d1bd) on Medium (2023)
- (Java) [OpenGenus](https://iq.opengenus.org/bidirectional-search/) (similar to GeeksforGeeks, 2020)

For fun, I also tested a few easily available LLMs with simple prompts. All of those I tested generated wrong (albeit original) code:
- (Python) [ChatGPT 4o](https://chatgpt.com/share/67550123-0afc-8010-9981-dd7223315c38) (has our bug)
- (C++) [ChatGPT 4o](https://chatgpt.com/share/67550276-27e0-8010-a0cb-e3c6475c8dc7) (has our bug)
- (Python) [Claude Haiku](https://claude.site/artifacts/b9dbb721-e274-47f8-8ce9-fe31146d3393) (has our bug, but also returns a completely wrong path sometimes)
- [GitHub Copilot (Codex) guessed the wrong path](Code_FMO0G8FpsJ.png) [twice](Code_tRU7i0IK7k.png) while trying to help me write this blogpost

If you want to run tests yourself, here is the pathological graph (both the one in the post and a symmetrical version) and the correct path:
- `[(0, 1), (0, 2), (1, 3), (3, 4), (4, 6), (2, 5), (5, 6)]`: correct path is `0, 2, 5, 6`, wrong path is `0, 1, 3, 4, 6`
  - or, in adjacency list form: `{ 0: [1, 2], 1: [0, 3], 2: [0, 5], 3: [1, 4], 4: [3, 6], 5: [2, 6], 6: [4, 5] }`
- `[(0, 1), (0, 2), (1, 4), (2, 3), (3, 5), (4, 6), (5, 6)]`: correct path is `0, 1, 4, 6`, wrong path is `0, 2, 3, 5, 6`
  - or, in adjacency list form: `{ 0: [1, 2], 1: [0, 4], 2: [0, 3], 3: [2, 5], 4: [1, 6], 5: [3, 6], 6: [4, 5] }`

And here are those I could find who implemented it correctly (at least, as far as I know):
- (Python) [shawnlyu](https://shawnlyu-official.medium.com/bfs-and-bi-directional-bfs-98cd4e6ad080) on Medium (2020)
- (Python) [Andrew McDowell](https://stackoverflow.com/questions/54437905/bidirectional-search/54440577#54440577) on StackOverflow (2019)
- (C++) [Rafael Glikis](https://github.com/rafaelglikis/bdbfs-leda/blob/master/src/bdbfs.cpp) on GitHub (2018)
- (Pseudocode) [Baeldung CS](https://www.baeldung.com/cs/bidirectional-search) (2022)

I only went up to page 5 of Google results, but other implementations may appear with different search keywords.

## Finding the Right Path, Faster

There's an additional easy optimization we can add on top of bidirectional BFS. Right now, each side is advancing one level at a time. But instead of alternating between sides, it appears that advancing on whichever side has visited the fewest nodes yet accelerates the algorithm in a lot of cases. The intuition behind is that:
- if a path exists, both sides will end up meeting at a midpoint that is on the shortest path
- advancing one level, no matter how many nodes we visit, will always get us closer to the midpoint by exactly one level
- if we're getting one level closer, we might as well advance on the side that has visited the fewest nodes, since that means we'll have less nodes to visit in the future (while still getting closer to the midpoint as fast as possible, but with less work)

On my test graph, this sped up some long paths by about 100 times: without the optimization, most paths take about 3-4ms but very long paths (>10 edges) can take up to 400ms. With the optimization, all queries take about 3-4ms.

## I Like Drawing Graphs

All the graphs in this post were pre-rendered to SVG using Graphviz, and then animated and made interactive using vanilla JS code you can inspect by viewing the source code of this post here