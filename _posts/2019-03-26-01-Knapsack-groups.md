---
layout: post
title: "0/1 Knapsack (with groups)"
date:  2019-03-22 04:04:23 +0700
categories: [problems, dp, knapsack, codechef]
---

### Problem: [**SONGSHOP**][problem-link]

There are N songs. The `i`-th song costs `p[i]` to purchase and brings `v[i]` satisfaction to you if you buy it. Also, each song belongs to one album `album[i]` and you can buy all the songs in an album for `album_price[i]` (or you can buy all the songs individually). Given budget `B`, what is the maximum satisfaction you can buy?

### Observations
1. Without albums, this would be the classical 0/1 knapsack problem solvable with dynamic programming (`dp[index][budget]`).
2. When we consider paying `album_price[i]`, we have to make sure we don't pay for any individual song in that album.
3. The dp solution to knapsack problem works independent of the order of songs. This is an important degree of freedom we can benefit from!

### Solution
First we sort songs by their album. Now, `dp[i][b]` stores the maximum satisfaction we can get by using budget `b` on items `1..i`. Now, there are 3 cases:
- we don't take the song: `dp[i - 1][b]`
- we take the song: `dp[i - 1][b - p[i]] + v[i]`
- we take the whole album (we should consider this only on the last song of the album): `dp[ prev[i] ][ b - album_price[a] ] + album_v[a]`**<sup>1</sup>**.

**<sup>1</sup>** `prev[i]` returns the index of the last song from the previous album. In the image below, songs from the same album are colored with the same color.

![prev]({{ site.url }}/static/img/01knapsack-prev.png){:height="80%" width="80%"}

The code would look like this:

{% highlight python %}

# assume songs are already sorted by album

# for base case we need: dp[0][*] = 0, dp[*][0] = 0 
# but for simplicity we initialize everything with zero
dp = np.zeros( (N + 1, B + 1) )

# fill prev
prev = np.zeros(N + 1)
for i in range(2, N + 1):
    prev[i] = prev[i - 1] if album[i] == album[i - 1] else i - 1

# recursion formula
for i in range(1, N + 1):
    for b in range(1, B + 1):

        # skip song
        res = dp[i - 1][b]

        # buy song
        if b - p[i] >= 0:
            res = max(res, dp[i-1][b - p[i]] + v[i])

        # buy album
        a = album[i]
        if i == N or album[i] != album[i + 1]:
            res = max(res, dp[ prev[i] ][ b - album_price[a] ] + album_v[a])
            
        dp[i][b] = res

# print answer
print dp[N][B]
{% endhighlight %}

[problem-link]: https://www.codechef.com/COOK104A/problems/SONGSHOP