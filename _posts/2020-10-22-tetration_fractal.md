---
layout: post
title: "Tetration Fractal"
date:  2020-10-22 09:42:41 +0700
categories: [fractal, math, julia]
---

### Background

This post is motivated by this fantastic [video][video]. Here we visualize what's discussed in that video.

### Overview

[Tetration][tet-def] operator is based on repeated exponentiation `x ^ x ^ ...`. For example:
{% highlight julia %}
- 2 ↑↑ 1 = 2 ^ 2 = 4
- 2 ↑↑ 2 = 2 ^ (2 ^ 2) = 2 ^ 4 = 16
- 2 ↑↑ 3 = 2 ^ (2 ^ (2 ^ 2)) = 2 ^ 16 = 65,536
- 2 ↑↑ 4 = 2 ^ (2 ^ (2 ^ (2 ^ 2))) = 2 ^ 65,536 (~20,000 digits)
- 2 ↑↑ 5 = ...
{% endhighlight %}

As we see above, `2^2^2...` grows really quickly and `2 ↑↑ 5` would have way more digits than the number of atoms in the universe! Surprisingly, if you for example plug in `1.1` or `1.2` it ends up converging to some number (`1.1 ↑↑ ∞`).

Given a number, we can numerically check if it converges or not by repeatedly doing the exponentiation for say 100 iterations and see if it explodes. Here is an example code in JuliaLang:

{% highlight julia %}
function get_iters(c, mx, mx_iters)
    tot = c
    for iter in 1:mx_iters
        if (abs(tot) > mx) return iter end
        tot = c ^ tot
    end
    return mx_iters + 1
end
{% endhighlight %}

<br/>

### Complex Numbers

Now, what if we plug in a complex number? In other words, for what values of `c` would `c ↑↑ ∞` converge? In order to understand what it means to raise a complex number to the power of another complex number, you can read [this article][comp-pow]. However, in [Julia][julia] you can just write `c ^ x` and not worry about the implementation!

So, considering x-axis the real component and y-axis the imaginary part, we can try a lot of complex numbers and see how many iterations does it take for a given complex number to explode. We assign a color to each pixel based on the number of iterations it takes to go beyond a certain large number. Finally, we plot it, and we get a fractal known as the "Tetration Fractal". (screenshots at the bottom of this page)

<br/>

### Implementation

We can implement this in JuliaLang in less than 30 lines, and takes a few seconds on a usual laptop to generate an image with 4k pixels.

{% highlight julia %}
using ImageView, Images
using Plots
plotly()

N = 2000
MX, MX_ITERS = 1e4, 32
cx, cy, r = 0, 0, 5

function get_iters(c, mx, mx_iters)
    tot = c
    for iter in 1:mx_iters
        if (abs(tot) > mx) return iter end
        tot = c ^ tot
    end
    return mx_iters + 1
end

Y = range(cy-r, cy+r, length=N)
X = range(cx-r, cx+r, length=N)
z = zeros(RGBA{Float64}, N, N)
for (r_idx, r) ∈ enumerate(X), (i_idx, i) ∈ enumerate(Y)
    c = r + i * im
    iters = get_iters(c, MX, MX_ITERS)
    z[i_idx, r_idx] = cgrad(:default)[(MX_ITERS + 1 - iters)/(MX_ITERS + 1)]
end

ImageView.imshow(z)
save("tetration.png", z)
{% endhighlight %}

<br/>

### Tetration Fractal

<br/>

[![tet1]][tet1]

[![tet2]][tet2]

[![tet3]][tet3]

[![tet4]][tet4]

[![tet5]][tet5]





[tet-def]: https://en.wikipedia.org/wiki/Tetration
[comp-pow]: http://paulbourke.net/fractals/tetration/
[julia]: https://julialang.org/
[tet1]: {{ site.url }}/static/img/tetfrac/tet1.png
[tet2]: {{ site.url }}/static/img/tetfrac/tet2.png
[tet3]: {{ site.url }}/static/img/tetfrac/tet3.png
[tet4]: {{ site.url }}/static/img/tetfrac/tet4.png
[tet5]: {{ site.url }}/static/img/tetfrac/tet5.png
[video]: https://www.youtube.com/watch?v=elQVZLLiod4