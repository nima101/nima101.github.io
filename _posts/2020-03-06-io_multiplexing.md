---
layout: post
title: "I/O Multiplexing (select vs. poll vs. epoll/kqueue)"
date:  2020-03-06 15:15:33 +0700
categories: [C, select, poll, kqueue, network, learning, linux, kernel]
---

> I/O multiplexing refers to the concept of processing multiple input/output events from a single event loop, with system calls like poll and select (Unix). --[Wikipedia][wiki-io]

### Introduction
[kqueue][kqueue] (on macOS) and [epoll][epoll] (on Linux) are kernel system calls for scalable I/O event notification mechanisms in an efficient manner. In simple words, you subscribe to certain kernel events, and you get notified when any of those events occur. These system calls are designed for scalable situations such as a webserver where `10,000` concurrent connections are being handled by one server.

epoll/kqueue are replacements for their deprecated counterparts [poll][poll] and [select][select]. Let's take a look at those two and see why they are not suitable for today's use cases.

<br/>

### select
In order to watch one file descriptor, say `777`, you need to write something like this in C:

{% highlight C %}
fd_set fds;
FD_ZERO(&fds);
FD_SET(777, &fds);
select(778, &fds, NULL, NULL, NULL);
{% endhighlight %}

When you call `select`, you pass `nfds = 778` which is the "number of file descriptors". What `select` does under the hood is, it simply loops through all the file descriptors from `0` to `nfds - 1`. It checks if you have set them and if the desired event occurred. So, the runtime is `O(n)` where `n` is the largest file descriptor you're watching!

This line of the man page, explains it well:
> The first nfds descriptors are checked in each set; i.e., the descriptors from 0 through nfds-1 in the descriptor sets are examined. (Example: If you have set two file descriptors "4" and "17", nfds should not be "2", but rather "17 + 1" or "18".)

Aside from performance, a bigger problem is, using `select` you may destroy your call stack and crash your process! Let's again look at how we set our desired file descriptor:

{% highlight C %}
fd_set fds;
FD_ZERO(&fds);
FD_SET(777, &fds);
{% endhighlight %}

`fds` is the set of file descriptors we want to watch, and according to the man page:
> The descriptor sets are stored as bit fields in arrays of integers.

It also later states that:
> The default size FD_SETSIZE (currently 1024) is somewhat smaller than the current kernel limit to the number of open files.

Now, if you try to watch file descriptor `2000`, `select` will loop over fds from `0` to `1999` and will read garbage. The bigger issue is when it tries to set results for a file descriptor past `1024` and tries to set that bit field in say `readfds`, `writefds` or `errorfds` field. At this point it will write something random on the stack eventually crashing the process and making it very hard to debug what happened since your stack is randomized.

<br/>

### poll
After the introduction of [select][select] in 1983, [poll][poll] was released in 1986 (and came to libc in linux in 1997) to address the shortcomings of select. poll solved the fd limit of 1024, introduced more flavours of events to watch and slight changes to the timeout in the api, such as using milliseconds instead of microseconds.

You can see that `poll`'s api makes a lot more sense:

{% highlight C %}
int poll(struct pollfd fds[], nfds_t nfds, int timeout);
{% endhighlight %}

You pass in the list of fds you're interested in, in a sparse format, and `ndfs` is actually the number of fds you are interested in. Here's the structure of `pollfd`:

{% highlight C %}
struct pollfd {
    int    fd;       /* file descriptor */
    short  events;   /* events to look for */
    short  revents;  /* events returned */
};
{% endhighlight %}

In order to watch fds `777` for read, you can simply do:

{% highlight C %}
pollfd pfd;
pfd.fd = 777;
pfd.events = POLLIN;
if (poll(&pfd, 1, -1)) {
    if (pfd.revents & POLLIN) { ... }
}
{% endhighlight %}

Although `poll` is an improvement to `select`, it still loops over the all the provided file descriptors hence runs in `O(n)` where `n` is the number of file descriptors we are watching.

<br/>

### Kqueue

[Kqueue][kqueue] is a scalable event notification interface introduced in 2000. It provides a standard API for applications to register their interest in various events/conditions and have their notifications delivered efficiently. It is designed to be scalable, flexible, reliable and correct.

In order to understand how to use kqueue, let's look at a few concepts.

<br/>

#### kevent structure
A **kevent** is identified by an `<ident, filter>` pair, where **ident** can be a file/socket descriptor and **filter** is the kernel filter used to process the respective event. There are some pre-defined system filters, such as `EVFILT_READ` or `EVFILT_WRITE`, that are triggered when data exists for read or write.

For example, if we want to be notified when there is data available for reading in a socket, we need to specify a kevent in the form of `<sckfd, EVFILT_READ>`.

{% highlight C %}
kevent ev;
EV_SET(&ev, sckfd, EVFILT_READ, EV_ADD, 0, 0, 0);
{% endhighlight %}

<br/>

#### flags
We use flags to add, delete, enable or disable a kevent from the queue (`EV_ADD`, `EV_DELETE`, `EV_ENABLE`, `EV_DISABLE`).

<br/>

#### kqueue
The kqueue holds all the events we are interested in. So, to start we can simply create an empty kqueue.

{% highlight C %}
int kq;
if ((kq = kqueue()) == -1) {
   perror("kqueue");
   exit(EXIT_FAILURE);
}
{% endhighlight %}

<br/>

#### kevent system call
We can use the `kevent(...)` system call to:
1. add/modify/delete events on the queue
2. wait/read occured events

It also allows for setting a timeout but for now we put in `NULL` which means no timeout (wait indefinitely).

Example usage:

{% highlight c %}
kevent(kq, &evSet, N, NULL, 0, NULL); /* adding/modifying N events to the queue */
kevent(kq, NULL, 0, &evList, N, NULL); /* waiting/reading events (up to N at a time) */
{% endhighlight %}

**Note:** re-adding an existing event will modify the parameters of the original event and won't result in a duplicate entry.

<br/>

#### event loop
After creating the queue and registering our events, we wait for the events in an infinite loop. Once they occur, the call to `kevent(...)` unblocks and we receive these events in `evList`. We can iterate over these events and handle them however we wish. For example, if we receive a new connection from a client, we can accept the connection or if we receive new data, we can read it from the socket.

{% highlight C %}
while (1) {
    int num_events = kevent(kq, NULL, 0, evList, N, NULL /* no timeout */);
    if (num_events == -1) {
        perror("kevent()");
        exit(EXIT_FAILURE);
    }
    for (i = 0; i < num_events; i++) {
        /* handle events */
    }
}
{% endhighlight %}

For a more practical use case, the next post [Streaming Server Using Kqueue]({% post_url 2020-03-10-kqueue_server %}) shows how to write a simple server using kqueue in only 100 lines in C!

[kqueue]: https://man.openbsd.org/kqueue
[epoll]: http://man7.org/linux/man-pages/man7/epoll.7.html
[poll]: http://man7.org/linux/man-pages/man2/poll.2.html
[select]: http://man7.org/linux/man-pages/man2/select.2.html
[wiki-io]: https://en.wikipedia.org/wiki/Multiplexing