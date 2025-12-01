---
layout: post
title: "Static Site, Persistent State"
date:  2025-11-29 00:07:07 +0700
categories: []
---

<br/>

<p style="text-align: center;"> <i> <b> Persisting state on a static site, for free. </b> </i> </p>

### Motivation

Most “dynamic” sites repeat the same choreography: pick a datastore, wrap it with an API, wrap that with a framework, then deploy everything across services you’ll eventually forget to clean up. All I wanted was a little interactivity on an otherwise static site, without signing up for another monthly bill. A simple 10×10 grid of checkboxes that anyone could flip on or off (motivated by [one-million-checkboxes](https://onemillioncheckboxes.com/)).

It turns out you can borrow someone else’s persistence layer. [GitHub Discussions](https://docs.github.com/en/discussions), of all things.

This experiment was motivated by [giscus](https://giscus.app/) and [utterances](https://utteranc.es/), which helped me gain my freedom from Disqus, after it flooded my blog with ads.

<br/>

### The idea

A discussion thread is a list of comments. A comment can have reactions. Reactions can be added or removed through the GitHub API. That’s enough to store a Boolean.

So each cell in the grid corresponds to a specific comment. If the comment has a 👍 reaction, the cell appears “on.” If not, it’s “off.” Everyone shares the same board. No accounts, no sessions, no state to host.

And this trick generalizes. Given that you can store arbitrary text in comments, you could serialize an entire SQLite database, encrypt it if you care, and persist it through GitHub as well. Not efficient. But possible. And that possibility is the point.

<br/>

### Demo

<div class="jsfiddle-dyn-state">
    <script async src="//jsfiddle.net/nim_a101/u7j20hbk/5/embed/result/"></script>
</div>

I could've wired it up with websockets for real-time updates, but this was just a proof of concept and I didn’t feel like chasing perfection. :)

<br/>

### The architecture

The system ends up looking like this:

![Architecture diagram]({{site.url}}/static/img/dyn-state/diag.png){:height="50%" width="50%" .center-image}

The static site never sees credentials. It calls a Worker endpoint for `/state` and `/toggle`. The Worker uses a GitHub App to mint short-lived installation tokens and patch reactions on the corresponding comments.

This gives you durable, globally shared state backed by GitHub’s infrastructure. For free.

<br/>

### Why it’s interesting

It feels oddly satisfying to have a tiny multiplayer surface built on top of a static site, with GitHub acting as the database, which needs no maintenance. 
It flips the usual dependency stack inside out. Instead of building a backend to support a toy UI, the UI piggybacks on someone else’s collaboration primitives.

You get:
- global state persistence
- no database to provision
- no servers to maintain

For small experiments, prototypes, or playful public boards, it’s enough. And it’s fun!
