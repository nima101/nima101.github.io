---
layout: post
title: "Mirrors and Laser Puzzle"
date:  2022-07-27 00:03:05 +0700
categories: [puzzle, javascript, simulation]
---


## Puzzle

You are a single point in a square room and all the walls are mirrors. Someone in the room is trying to shoot you with a laser from another point in the room. No one is allowed to move but you can install single-point blockers to completely block the line and not reflect it. What is the minimum number of blockers you need to guarantee you'll be safe? Would that even be finite?

<br/>

![laser]{:height="30%" width="30%" .center-image}


<br/>

## Solution

This video does a great job explaining the solution:

[https://www.youtube.com/watch?v=jJ6FD59U0_E](https://www.youtube.com/watch?v=jJ6FD59U0_E)


<iframe width="560" height="315" src="https://www.youtube.com/embed/jJ6FD59U0_E" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<br/>

## Simulation

Here is a simulation I made with a few lines of html, js and css: 

[http://jsfiddle.net/nim_a101/mqypwuo3/132/](http://jsfiddle.net/nim_a101/mqypwuo3/132/)

<br/>

<div class="jsfiddle">
    <script async src="//jsfiddle.net/mqypwuo3/132/embed/result/dark/"></script>
</div>

<br/>

[laser]: {{ site.url }}/static/img/laser-puzzle/laser.png

