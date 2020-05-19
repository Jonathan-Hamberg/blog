---
title: Tailscale Hosts
subtitle:
date: 2020-05-16
tags: ["wireguard", "vpn", "python"]
draft: false


---

# Tailscale Hosts

```shell
pip install git+https://www.gitlab.com/jhamberg/tailscale-hosts.git
```

Tailscale automically keeps track of all the connected peers with their ip address and hostname.  Tailscale does not by default allow access to the devices by their hostname which can be a hassle.  This means that you always have to look up the Tailscale IP address of the peer in the network.  It would be nice to have a program to alloww access to the peers by their hostnames.

```shell
tailscale status
[ERwrT] linux   100.125.175.83  serenity           .
[MNw8B] linux   100.101.102.103 hello.ipn.dev      ...
[Ws5E9] windows 100.123.119.83  prometheus         ...
[ZZbvo] linux   100.76.104.117  awing              ...

```

The tailscale status command has all the information we need to be able to start using the human readable peer names.  Here you can see that all my PC are named after science fiction starships.



```shell
# here we can see that we are not able to connect to the peer by it's hostname
ping awing
ping: awing: Name or service not known

# Lets install the tailscale-hosts package
pip install git+https://www.gitlab.com/jhamberg/tailscale-hosts.git

# Update the hosts file with the tailscale peers
tailscale_hosts update

# Ping now successfully works with tailscale peer hostname
ping awing
PING awing (100.76.104.117) 56(84) bytes of data.
64 bytes from awing (100.76.104.117): icmp_seq=1 ttl=64 time=2.51 ms
64 bytes from awing (100.76.104.117): icmp_seq=2 ttl=64 time=1.73 ms

# Remove the tailscale peer hostnames from the hosts file.
tailscale_hosts remove

# Now we can see that the hostname no longer works.
ping awing
ping: awing: Name or service not known
```

Eventually I plan on putting tailscale-hosts on pip, but for now it's just a repo.