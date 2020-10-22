---
layout: post
title: "Find all prime numbers up to N"
date:  2019-03-27 22:15:02 +0700
categories: [prime, algorithm]
---

### Problem

Given `n`, find all prime numbers less than `n`.

<br/>
### Approaches

1. We can simply iterate over numbers and test if they are prime. A simple primality test would run in `O(sqrt(n))` and the fastest primality test algorithms run slower than `O(log(n))` <sup>1</sup>. This approach at best would result in an overall `O(nlog(n))` runtime complexity.

2. We can use the famous [Sieve of Eratosthenes](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes) and using `O(n)` memory, we can find all prime numbers in `O(nlog(log(n)))`. (the image is taken from Wikipedia)

<br/>
<div>
<div style="float:left; float:top; width: 45%; margin-left:5%; margin-right:5%">
{% highlight python %}
prime = [True] * (n + 1)
prime[0] = False
prime[1] = False

for i in range(2, n + 1):
    if prime[i]:
        for j in range(i * i, n + 1, i):
            prime[j] = False
{% endhighlight %}
</div>
<div style="">
<img src="https://upload.wikimedia.org/wikipedia/commons/b/b9/Sieve_of_Eratosthenes_animation.gif" style="width: 40%; height: 40%">
</div>
</div>
<br/>

<sup>1</sup> <sub>For example, [AKS Primality Test](https://en.wikipedia.org/wiki/AKS_primality_test) or [Miller-Rabin Primality Test](https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test) both run in <code>O(log<sup>O(1)</sup>(N))</code>.</sub> 

<br/>
### Why is "Sieve of Eratosthenes" slow?

The main issue with Sieve of Eratosthenes is that it marks each composite number from all of its prime factors. For example, number `60` is marked from `2`, `3` and `5` (`60 = 2*2*3*5`), while it would have been enough to just mark it from one of the prime factors, say `2`.

If we find a way to mark each composite number only from one of its prime factors, we will have a linear time solution.

<br/>
### Linear-time solution

In order to find all prime numbers up to `n`, we keep track of two arrays:
- `primes`: list of all prime numbers we have found so far.
- `lp[x]`: the smallest prime factor for integer `x`.

Now, imagine a composite number such as `3 * 5 * 7`. We need to mark such a number from its lowest prime factor `3` by setting `lp[3 * 5 * 7] = 3`. However, instead of marking it from `3`, we mark it from `5 * 7`.

In order to do so, when we are at `i = 5 * 7`, for each prime `p <= 5`, we mark `p * i`. Basically, we do:
- `lp[2 * 5*7] = 2`
- `lp[3 * 5*7] = 3`
- `lp[5 * 5*7] = 5`

More formally, for each `i`, we look at `lp[i]` and for all primes `p` less than or equal to `lp[i]`, we set `lp[p * i] = p`.

So, we start with `lp` initialized with `0`. We iterate over all numbers from `2` to `n`. If `lp[i] == 0`, it means `i` is prime, so we set `lp[i] = i`. Otherwise, `i` is a composite number and we have already stored its smallest prime factor in `lp[i]`. 

Now, using all prime numbers less than or equal to `lp[i]` we set some future composite numbers. (note that we do this where `i` is prime or composite)

#### Implementation

The code would look something like this:

{% highlight python %}
lp = [0] * (n + 1);
primes = []

for i in range(2, n + 1):
    if lp[i] == 0:
        lp[i] = i
        primes.append(i)

    for j in range(len(primes)):
        if primes[j] > lp[i] or primes[j] * i > n:
            break
        lp[primes[j] * i] = primes[j]
{% endhighlight %}
<br/>

#### Correctness

Suppose we arrive at a composite number `C` and `p` is the smallest prime factor in `C`. `C` is uniquely represented as: `C = p * X` for some number `X > 1`. Since `p` is the smallest prime factor in `C`, `p` is also smaller or equal to the smallest prime factor in `X`. This means we should have marked `C` when we arrived at `X` **<sup>**1**</sup>. 

<sup>**1**</sup> Remember that for each number `X` we mark all composites `p * X` for primes `p` smaller than or equal to the smallest prime factor in `X`.

#### Complexity

Every composite number `x` is uniquely represented as `x = lp[x] * y`. So, it will be visited from only one number `y`. And prime numbers will not be visited from any other number. So, in total we have `|composites|` visits + `n` for iterating over all numbers. In total: `O(n)`.

**Base Case:** For `i = 2`, `lp[i]` is zero, so we figure `2` is a prime and we set `lp[2] = 2`.

**Invariant:** For all numbers `i` up to `k`, 

#### Correctness (OLD

We can use proof by contradiction to prove we will always mark a composite number before arriving at it. 

Suppose not. Assume a **composite** number `C` is not marked when we arrive at it. we know that `C = lp[C] * X` for some `1 < X < C` and `lp[C]` is always prime. We also know that `lp[C]` is the smallest prime factor in `C`, so we know as well: `lp[C] <= lp[X]`. But this contradicts with the assumption of our algorithm since when we visited `X`, we should have marked `lp[C] * X` since `lp[C]` is a prime number less than or equal to the smallest prime factor of `X`.

#### Prime factorization

This linear-time algorithm not only gives us all the prime numbers up to `n` but also gives us the **prime factorization** for all numbers up to `n`! Using `lp`, we can recursively extract the lowest prime until no more primes left.

{% highlight python %}

def prime_factors(x):
    res = []
    while lp[x] > 0:
        res.append(lp[x])
        x /= lp[x]
    return res

{% endhighlight %}
<br/>


### Source

I read about this on [cp-algorithms](https://cp-algorithms.com/algebra/prime-sieve-linear.html).

<br/>