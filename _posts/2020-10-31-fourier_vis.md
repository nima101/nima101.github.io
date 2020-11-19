---
layout: post
title: "Complex Fourier Visualization"
date:  2020-10-31 17:53:34 +0700
categories: [fourier, math, julia]
---

### Motivation

This post is motivated by [a fantastic video][video] (by [3blue1brown][3b1b]) regarding complex Fourier series. Here I want to give a brief overview of how to do the Fourier transform for a complex function and also how to implement it in Julia with few lines of code. Furthermore, a few different ways to generate a parametric curve to use as an input for our program.

Before we dive in, I want to emphasize how interesting the outcome of this work is. Basically, given any 2D shape, we want to find `n` fixed length vectors, each rotating at a constant speed such that if we add them together, they draw the input shape. This is an example with 600 vectors, drawing the word `"hello"`:

![hello_600]{:height="70%" width="70%"}

<br/>

### Complex Functions

Let's think of a complex function `f(t)` which takes an input between 0 and 1 and outputs a complex number. We can visualize the output of this function on a 2D plane with x-axis being the real component and the y-axis being the imaginary component.

Complex numbers provide an elegant way to store the 2D coordinates with the additional benefit that `e ^ (i * t)` walks around a circle with a constant speed of one unit per second. For convenience, we can work with `e ^ (i * 2π * t)` instead, which loops exactly once around the circle as `t` goes from 0 to 1, as shown below.

![simple1]{:height="60%" width="60%"}

Note that `e ^ (2 * i * 2π * t)` goes twice as fast and `2 * e ^ (i * 2π * t)` walks around a circle twice bigger. Now, by combining different terms you can create interesting shapes, such as below.

![simple2]{:height="60%" width="60%"}

Here is the code in Julia to generate this animation:

{% highlight julia %}
using Plots
using Interact
using JSON
gr()

pw = (t, x) -> ℯ ^ (x * im * 2π * t)
func = t -> (0.1 - 0.5im) * pw(+1, t) +
            (1.0 + 0.5im) * pw(-1, t) +
            (0.0 + 0.5im) * pw(+2, t) +
            (0.5 + 1.0im) * pw(-2, t) +
            (1.0 - 0.5im) * pw(+3, t) +
            (0.3 + 0.5im) * pw(-3, t)

anim = Animation()
xs, ys = [], []

for i in 0:0.01:1
    plot([], [], legend=nothing, aspect_ratio=:equal, xlim=[-5, 5], ylim=[-5, 5], widen=true, framestyle = :origin)
    x = real(func(i))
    y = imag(func(i))
    annotate!(x * 1.2, y * 1.2, text("$i", :center, 10))
    append!(xs, x)
    append!(ys, y)
    plot!(xs, ys)
    quiver!([0], [0], quiver = ([x], [y]))
    frame(anim)
end

gif(anim, "complex.gif", fps = 15)
{% endhighlight %}

<br/>

### Complex Fourier Transform

Now, how would you combine these exponential terms to draw a given shape such as a bird, heart, handwriting, etc.? Also, is it always feasible to do so? Basically, given a function `f(t)` can you always represent it in terms of a summation of these exponential terms with some complex coefficients?

![form1]{:height="80%" width="80%"}

[Joseph Fourier][jbf] in 1800s [proved][fit] that it's always possible (under some basic conditions <sup>1</sup>). Let's look at a brief overview of how to do it. Suppose the transform exists and let's try to extract the coefficients `c_i`. Take an integral from 0 to 1 on both sides. Note that for any exponential term, if the power is a multiple of `2πt` and non-zero, as `t` varies from 0 to 1, it loops around a circle once, twice, thrice, or more. but it is important that it does full loops. so, the average of all these points (aka the integral from 0 to 1) will be zero. The only term that remains non-zero is `c_0`.

![form2]{:height="100%" width="100%"}

This is nice because it allows us to calculate `c_0` by integrating over `f(t)` from 0 to 1. Now, we can use a clever trick to calculate any `c_i` in the series. For example to calculate `c_2`, multiply both sides by `e ^ (-2 * 2πit)` and then take the integral. This time, all terms become zero except `c_2`.

![form3]{:height="100%" width="100%"}

So we can calculate each `c_n` using:

![form4]{:height="30%" width="30%" .center-image}

Which can be done using numerical integration:

{% highlight julia %}
# numerial integration
function c_n(f, n)
    dt = 1e-5
    return sum(f(t) * ℯ ^ (-n * 2π * im * t) * dt for t ∈ 0:dt:1)
end
{% endhighlight %}

Once we calculate all `c_n` terms for a given range of `n` (say from -10 to +10), we have our fourier transform. Here is the full code (~50 lines):

{% highlight julia %}
using Plots; gr()
using Interact

# heart shape
func = t -> 20sin.(2π*t).^3 + (20cos(2π*t) - 7cos(2*2π*t) - 2cos(3*2π*t) - cos(4*2π*t)) * im

# numerial integration
function c_n(f, n)
    dt = 1e-5
    return sum([f(t) * ℯ ^ (-n*2π*im*t) * dt for t ∈ 0:dt:1])
end

function eval_term(c, x, i)
    return c[i] * ℯ ^ (i * 2π * im * x)
end

function sum_terms(c, x)
    return sum(eval_term(c, x, i) for i ∈ c_range)
end

n = 100
c_range = -5:5
t = range(0, 1, length = n)
c = Dict([ (i, c_n(func, i)) for i in c_range ])

comb = x -> sum_terms(c, x)
z = comb.(t)
x = real.(z)
y = imag.(z)

anim = Animation()
xs, ys = [], []

idx = sort(collect(c_range), lt=(x,y) -> abs(x) < abs(y))
evs = [(i -> eval_term(c, t[i], j)) for j in idx]

for i in 1:n
    # draw shape
    plot(xs, ys, legend=nothing, aspect_ratio=:equal, widen=true, framestyle = :origin, xlim=[-25, 25], ylim=[-30, 25])
    append!(xs, x[i])
    append!(ys, y[i])

    # draw vectors
    u = [real(a(i)) for a in evs]
    v = [imag(a(i)) for a in evs]
    xx, yy = [0.0], [0.0]
    for i ∈ 1:length(evs)-1
        append!(xx, xx[i] + u[i])
        append!(yy, yy[i] + v[i])
    end
    quiver!(xx, yy, quiver=(u, v))
    frame(anim)
end
gif(anim, "test.gif", fps=15)
{% endhighlight %}

<hr/>
<sup>1</sup> <sub>It is always possible if both `f` and its Fourier transform are absolutely integrable and `f` is continuous. ([more details][fit])</sub> 

<br/>

### Input

In order to test our code, we need the mathematical representation of a 2D shape as a parametric curve. Below are a few different ways I achieved the parametric curve.

<br/>

#### Heart

I found this parametric representation of a heart shape on the internet.

{% highlight julia %}
x = 16 * sin(2π * t)^3
y = 19.5 * cos(2π * t) - 7.5 * cos(2 * 2π * t) - 3 * cos(3 * 2π * t) - 1.5 * cos(4 * 2π * t)
{% endhighlight %}

Here are the Fourier representations with [6, 20, 100] vectors:

![h6]{:height="32%" width="32%"}
![h20]{:height="32%" width="32%"}
![h100]{:height="32%" width="32%"}

<br/>

#### Sigma

I wrote a quick nodejs app where you can draw a shape, and it gives you an array of points. (connecting each point to the next point results in the shape we want to draw). An example drawing:

![sigma-nodejs]{:height="90%" width="90%"}

Then we need to convert the list of points to a parametric curve. This can be done fairly easily as well:

{% highlight julia %}
function interpol(p1, p2, t)
    return (p2 - p1) * t + p1
end

function param_curve(points, x)
    n = length(points)
    if (x == 1.0)
        return points[n-1]
    end
    s = trunc(Int, x * (n - 1)) + 1
    e = s + 1
    t = x * (n - 1) - (s - 1)
    return interpol(points[s], points[e], t)
end
{% endhighlight %}

<br/>

Finally, here are the Fourier transforms with 10, 100, and 1000 vectors:

![s10]{:height="60%" width="60%"}
![s100]{:height="60%" width="60%"}
![s1000]{:height="60%" width="60%"}

<br/>

#### Quaver

Unsatisfied with the difficulty of drawing using a mouse, I used my [Moleskine Notebook][moleskine] to draw the shape of a musical note (a quaver), exported it as "svg" (vector graphics) and wrote a small script to convert the svg to a parametric curve.

Here are the Fourier transforms with 6, 10, 20, 100, 400 and 1000 vectors:

![n6]{:height="33%" width="33%"}
![n10]{:height="33%" width="33%"}
![n20]{:height="33%" width="33%"}
![n100]{:height="33%" width="33%"}
![n400]{:height="33%" width="33%"}
![n1000]{:height="33%" width="33%"}

<br />

### Conclusion

[Julia][julia] makes it easy to work with complex numbers as it allows you to simply write code like `ℯ ^ (2π * im)`. It is also easy to create animations and generate gifs.


[simple1]: {{ site.url }}/static/img/fourier/simple1.gif
[simple2]: {{ site.url }}/static/img/fourier/simple2.gif


[form1]: {{ site.url }}/static/img/fourier/formula1.png
[form2]: {{ site.url }}/static/img/fourier/formula2.png
[form3]: {{ site.url }}/static/img/fourier/formula3.png
[form4]: {{ site.url }}/static/img/fourier/formula4.png

[hello_600]: {{ site.url }}/static/img/fourier/hello_600.gif

[h6]: {{ site.url }}/static/img/fourier/heart6.gif
[h20]: {{ site.url }}/static/img/fourier/heart20.gif
[h100]: {{ site.url }}/static/img/fourier/heart100.gif

[s10]: {{ site.url }}/static/img/fourier/sigma_10.gif
[s100]: {{ site.url }}/static/img/fourier/sigma_100.gif
[s1000]: {{ site.url }}/static/img/fourier/sigma_1000.gif

[n6]: {{ site.url }}/static/img/fourier/note_6.gif
[n10]: {{ site.url }}/static/img/fourier/note_10.gif
[n20]: {{ site.url }}/static/img/fourier/note_20.gif
[n100]: {{ site.url }}/static/img/fourier/note_100.gif
[n400]: {{ site.url }}/static/img/fourier/note_400.gif
[n1000]: {{ site.url }}/static/img/fourier/note_1000.gif

[qsvg]: {{ site.url }}/static/img/fourier/quaver-svg.png
[sigma-nodejs]: {{ site.url }}/static/img/fourier/sigma-nodejs.jpg

[jbf]: https://en.wikipedia.org/wiki/Joseph_Fourier
[fit]: https://en.wikipedia.org/wiki/Fourier_inversion_theorem
[video]: https://www.youtube.com/watch?v=r6sGWTCMz2k
[3b1b]: https://www.youtube.com/channel/UCYO_jab_esuFRV4b17AJtAw
[moleskine]: https://moleskine.com
[julia]: https://julialang.org/