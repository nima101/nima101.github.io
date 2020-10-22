---
layout: post
title: "Suffix Arrays"
date:  2019-04-14 16:37:14 +0700
categories: [algorithm, strings, dp]
---

### Introduction

Given a string, sort the suffixes of that string in ascending order. The resulting sorted list is called a *suffix array*.
For example, for `s = "banana"` the suffixes are:
{% highlight python %}
0. banana
1. anana
2. nana
3. ana
4. na
5. a
{% endhighlight %}

After sorting them we get:
{% highlight python %}
5. a
3. ana
1. anana
0. banana
4. na
2. nana
{% endhighlight %}

Therefore, `sa = [5, 3, 1, 0, 4, 2]` is the suffix array for `s`.

The naive solution would be to simply sort the strings using quick sort which takes `O(nlogn)`, and since each string comparison takes `O(n)`, overall the complexity would be <code>O(n<sup>2</sup>logn)</code>.

There are better algorithms to construct a suffix array and they typically run in `O(n)` or `O(nlogn)`. If you are interested in an `O(nlogn)` approach, read this post by [cp-algorithms](https://cp-algorithms.com/string/suffix-array.html) or the paper by [Manber and Myers](https://epubs.siam.org/doi/10.1137/0222058). Also in theory, suffix sorting can be done using [Suffix Trees](https://en.wikipedia.org/wiki/Suffix_tree) in `O(n)`. However, due to the large constant and high memory overhead, in practice suffix arrays are often preferred. In addition, suffix arrays can also be constructed in linear time (ex: [1](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.125.1794&rep=rep1&type=pdf) & [2](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.83.9781&rep=rep1&type=pdf)). However, a good `O(nlogn)` implementation of suffix arrays such as [qsufsort](http://www.larsson.dogma.net/qsufsort.c) is usually sufficient and in practice faster than most linear time implementations.

In the next section, we look at a relatively simple algorithm that creates the suffix array for a given string in <code>O(nlog<sup>2</sup>n)</code> using dynamic programming. 

<br/>
### Dynamic Programming
The idea of this algorithm is based on efficient suffix comparisons. Suppose `cmp(i, j, k)` compares the suffixes starting at `i` and `j` using only the first `k` characters of them. Now, in order to calculate `cmp` we look at the comparison of the first half (using the first `k/2` characters). If they are different, we know the answer. If they are equal, then we look at the comparison of the second half. psudo-code:

{% highlight python %}
# k is either 1 or an even number
cmp(i, j, k):
  # base case: compare using the first characters
  if k == 1:
    return s[i] - s[j]

  # recursion formula
  first_half = cmp(i, j, k/2)
  if first_half == 0:
    return first_half
  else:
    return cmp(i + k/2, j + k/2, k/2)
{% endhighlight %}

One problem with this recursion formula is that we need to store the comparison between all possible pairs of suffixes at each (`k`) to use it in the next round (`2 * k`), which would make the algorithm slow. The trick to solve this efficiently is to sort them using the comparison function in `O(nlogn)`, and then for each `i < j`, using the sorted array `sa`, we know the suffix starting at `sa[i]` is less than or equal to the suffix starting at `sa[j]`. In order to distinguish between `<` and `=`, we run a bucketization that simply walks over the sorted array and finds chunks of equal suffixes. Later, we use the bucket array to compute `cmp(i, j, k / 2) = bucket[i] - bucket[j]`.

For example, far `s = "banana"` and `k = 2`, sorting all suffixes using only their first 2 letters would be:

```
[a-]
[an] ana
[an] a
[ba] nana
[na] na
[na]
```

So, since `a- < an = an < ba < na = na`, the bucket array would be `[0, 1, 1, 2, 3, 3]`, and to compare two suffixes we can simply subtract their buckets!

<br/>
### Implementation

Here is my implementation of the <code>O(nlog<sup>2</sup>n)</code> algorithm in python:

{% highlight python %}

# compare suffixes starting at idx1 and idx2, using only the first k characters
def compare_suffixes(idx1, idx2, k, s, b):
    if k == 1:
        return ord(s[idx1]) - ord(s[idx2])
    
    if b[idx1] != b[idx2]: # first half
        return b[idx1] - b[idx2]
    else:
        k2 = k / 2
        b1 = b[idx1 + k2] if idx1 + k2 < len(s) else -1
        b2 = b[idx2 + k2] if idx2 + k2 < len(s) else -1
        return b1 - b2


def bucketize(sa, k, s, prev_buckets):
    b = [None] * len(s)
    bucket = 0
    for i in range(len(sa)):
        if i > 0 and compare_suffixes(sa[i], sa[i-1], k, s, prev_buckets) != 0:
            bucket += 1
        b[sa[i]] = bucket
    return b
    

def suffix_array(s):
    n = len(s)
    sa = range(n)
    buckets = None
    k = 1
    while k <= n:
        sa.sort(cmp=lambda i, j: compare_suffixes(i, j, k, s, buckets))
        buckets = bucketize(sa, k, s, buckets)
        k *= 2
    return sa

{% endhighlight %}

<br/>
Running it:

{% highlight python %}
>>> suffix_array('banana')
[5, 3, 1, 0, 4, 2]
{% endhighlight %}


<br/>
### Source

I learned this algorithm from [TopCoder Forums](https://apps.topcoder.com/forums/?module=Thread&threadID=627379&start=0&mc=39).



