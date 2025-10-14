---
layout: post
title: "Streaming Server Using Kqueue"
date:  2020-03-10 22:09:33 +0700
categories: [C, kqueue, streaming, server, network, learning, linux, kernel]
---

I worked on this small project to better understand how [kqueue][kqueue] works. Let's implement a bidirectional streaming server using kqueue only in 100 lines (in C)!

Note: If you want to learn more about kqueue fundamentals, read [this post]({% post_url 2020-03-06-io_multiplexing %}) first.

<br/>

### Design

1. The server starts up on port `8080`
2. Enters the event loop where we handle:
    + New connections
    + Disconnections
    + Sending/receiving messages

<br/>

#### Starting the server
In order to start the server we need to:
1. **Create** a socket
2. **Bind** it to an address (`<localhost, port 8080>`)
3. **Listen** on the socket for incoming connections

{% highlight C %}
int create_socket_and_listen() {
    struct addrinfo *addr;
    struct addrinfo hints;
    memset(&hints, 0, sizeof hints);
    hints.ai_flags = AI_PASSIVE;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    getaddrinfo("127.0.0.1", "8080", &hints, &addr);
    int local_s = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol);
    bind(local_s, addr->ai_addr, addr->ai_addrlen);
    listen(local_s, 5);
    return local_s;
}
{% endhighlight %}

Next,
1. create an empty kqueue 
2. create an eventSet for READs on the socket
3. add evSet to the kqueue

Note: for (2), refer to the man page for [kevent][kqueue] (`EVFILT_READ` section):
> Sockets which have previously been passed to listen() return when there is an incoming connection pending.

{% highlight C %}
int main(int argc, char *argv[]) {
    int local_s = create_socket_and_listen();
    int kq = kqueue();
    struct kevent evSet;
    EV_SET(&evSet, local_s, EVFILT_READ, EV_ADD, 0, 0, NULL);
    kevent(kq, &evSet, 1, NULL, 0, NULL);
    run_event_loop(kq, local_s);
    printf("success\n");
    return EXIT_SUCCESS;
}
{% endhighlight %}

Then we enter the event loop where we handle incoming connections and send/receive messages.

<br/>

#### Accepting Connections

Each time we receive a new connection from a client, we [accept][accept] the connection. The `accept(..)` system call basically does the tcp 3-way handshake and creates a socket for further communication with that client and returns the file descriptor of that socket. We need to store these file descriptors for each client so we can communicate with them.

<br/>

#### Connection Pooling

Let's store an array of `client_data` (which contains the socket's fd), and initially all of them have `fd = 0`, which means "unused".

{% highlight C %}
struct client_data {
    int fd;
} clients[NUM_CLIENTS];
{% endhighlight %}

Operations:
1. **Lookup:** Given a fd, we can find the corresponding `client_data` by simply iterating over the array
2. **Add:** For new connections, we find the first free item (`fd = 0`) in the array to store the client's fd
3. **Delete:** When the connection is lost, we free that item in the array by setting its fd to `0`

Below is the code for these three operations:

{% highlight C %}
int get_conn(int fd) {
    for (int i = 0; i < NUM_CLIENTS; i++)
        if (clients[i].fd == fd)
            return i;
    return -1;
}

int conn_add(int fd) {
    if (fd < 1) return -1;
    int i = get_conn(0);
    if (i == -1) return -1;
    clients[i].fd = fd;
    return 0;
}

int conn_del(int fd) {
    if (fd < 1) return -1;
    int i = get_conn(fd);
    if (i == -1) return -1;
    clients[i].fd = 0;
    return close(fd);
}
{% endhighlight %}

<br/>

#### Event Loop

Now, we create an infinite loop where we call `kevent(..)` to receive incoming events and process them.

{% highlight C %}
while (1) {
    int num_events = kevent(kq, NULL, 0, evList, MAX_EVENTS, NULL);
    for (int i = 0; i < num_events; i++) {
        /* handle events */
    }
}
{% endhighlight %}

So far, we have registered to receive incoming connections on the main socket. When we receive such event, we [accept()][accept] the connection and store the new socket's fd in our connection pool. We also register for the incoming messages from that client (on the same kqueue). We also send them a welcome message on this new socket!

When a client disconnects, we receive an event where the `EOF` flag is set on the socket. We simply free up that connection in the pool and remove the event from kqueue (via `EV_DELETE`).

Finally, we handle incoming data from clients and receive their message.

{% highlight C %}
while (1) {
    int num_events = kevent(kq, NULL, 0, evList, MAX_EVENTS, NULL);
    for (int i = 0; i < num_events; i++) {
        // receive new connection
        if (evList[i].ident == local_s) {
            int fd = accept(evList[i].ident, (struct sockaddr *) &addr, &socklen);
            if (conn_add(fd) == 0) {
                EV_SET(&evSet, fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
                kevent(kq, &evSet, 1, NULL, 0, NULL);
                send_welcome_msg(fd);
            } else {
                printf("connection refused.\n");
                close(fd);
            }
        } // client disconnected
        else if (evList[i].flags & EV_EOF) {
            int fd = evList[i].ident;
            printf("client #%d disconnected.\n", get_conn(fd));
            EV_SET(&evSet, fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);
            kevent(kq, &evSet, 1, NULL, 0, NULL);
            conn_del(fd);
        } // read message from client
        else if (evList[i].filter == EVFILT_READ) {
            recv_msg(evList[i].ident);
        }
    }
}
{% endhighlight %}

<br/>

### Complete Code

{% highlight C %}
#include <err.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/event.h>
#include <sys/socket.h>
#include <unistd.h>

#define NUM_CLIENTS 10
#define MAX_EVENTS 32
#define MAX_MSG_SIZE 256

struct client_data {
    int fd;
} clients[NUM_CLIENTS];

int get_conn(int fd) {
    for (int i = 0; i < NUM_CLIENTS; i++)
        if (clients[i].fd == fd)
            return i;
    return -1;
}

int conn_add(int fd) {
    if (fd < 1) return -1;
    int i = get_conn(0);
    if (i == -1) return -1;
    clients[i].fd = fd;
    return 0;
}

int conn_del(int fd) {
    if (fd < 1) return -1;
    int i = get_conn(fd);
    if (i == -1) return -1;
    clients[i].fd = 0;
    return close(fd);
}

void recv_msg(int s) {
    char buf[MAX_MSG_SIZE];
    int bytes_read = recv(s, buf, sizeof(buf) - 1, 0);
    buf[bytes_read] = 0;
    printf("client #%d: %s", get_conn(s), buf);
    fflush(stdout);
}

void send_welcome_msg(int s) {
    char msg[80];
    sprintf(msg, "welcome! you are client #%d!\n", get_conn(s));
    send(s, msg, strlen(msg), 0);
}

void run_event_loop(int kq, int local_s) {
    struct kevent evSet;
    struct kevent evList[MAX_EVENTS];
    struct sockaddr_storage addr;
    socklen_t socklen = sizeof(addr);

    while (1) {
        int num_events = kevent(kq, NULL, 0, evList, MAX_EVENTS, NULL);
        for (int i = 0; i < num_events; i++) {
            // receive new connection
            if (evList[i].ident == local_s) {
                int fd = accept(evList[i].ident, (struct sockaddr *) &addr, &socklen);
                if (conn_add(fd) == 0) {
                    EV_SET(&evSet, fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
                    kevent(kq, &evSet, 1, NULL, 0, NULL);
                    send_welcome_msg(fd);
                } else {
                    printf("connection refused.\n");
                    close(fd);
                }
            } // client disconnected
            else if (evList[i].flags & EV_EOF) {
                int fd = evList[i].ident;
                printf("client #%d disconnected.\n", get_conn(fd));
                EV_SET(&evSet, fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);
                kevent(kq, &evSet, 1, NULL, 0, NULL);
                conn_del(fd);
            } // read message from client
            else if (evList[i].filter == EVFILT_READ) {
                recv_msg(evList[i].ident);
            }
        }
    }
}

int create_socket_and_listen() {
    struct addrinfo *addr;
    struct addrinfo hints;
    memset(&hints, 0, sizeof hints);
    hints.ai_flags = AI_PASSIVE;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    getaddrinfo("127.0.0.1", "8080", &hints, &addr);
    int local_s = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol);
    bind(local_s, addr->ai_addr, addr->ai_addrlen);
    listen(local_s, 5);
    return local_s;
}

int main(int argc, char *argv[]) {
    int local_s = create_socket_and_listen();
    int kq = kqueue();
    struct kevent evSet;
    EV_SET(&evSet, local_s, EVFILT_READ, EV_ADD, 0, 0, NULL);
    kevent(kq, &evSet, 1, NULL, 0, NULL);
    run_event_loop(kq, local_s);
    return EXIT_SUCCESS;
}
{% endhighlight %}

<br/>

### All Done!
1. This is a simple implementation just to demonstrate how kqueue works. It lacks many things including handling sys call failures, handling large messages correctly, etc.
2. As an exercise, add a feature where server can also read messages from `stdin` and broadcast them to all clients.
3. Everything seems rather efficient except the fact that the call to `accept` does a tcp 3-way handshake, which incurs an extra roundtrip. You may wonder if that's necessary and can we avoid that round trip fully or partially. While the 3-way handshake is necessary for tcp connections, [this external post][tcp-hand-shake] explains some alternatives such as TCP Fast Open (TFO) or QUIC (TLS over UDP).

<br/>

Below is a demo where I run the server on the lift and 4 clients on the right.

**Note:** For the client side, I use the linux utility [nc(netcat)][nc]. You can run `nc -l PORT` to listen on a port or run `nc HOST PORT` to connect to a server and send data (once connected, type your msg and press enter to send).

![gif]({{ site.url }}/static/img/tcp_server.gif){:height="100%" width="100%"}

<br/>


[kqueue]: https://man.openbsd.org/kqueue
[accept]: http://man7.org/linux/man-pages/man2/accept.2.html
[tcp-hand-shake]: https://pcarleton.com/2018/06/06/why-does-tcp-need-a-3-way-handshake-anyway/
[nc]: https://man.openbsd.org/nc.1