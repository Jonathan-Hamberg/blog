---
title: Tailscale Hosts
subtitle:
date: 2020-05-19
tags: ["wireguard", "vpn", "python"]
draft: false


---

# Tailscale Hosts

Last [post](https://jonathanhamberg.com/post/wireguard-using-tailscale/) I talked about how to set up a mesh network of WireGuard peers using a service called Tailscale.  One of my only complaints is that sometimes it's hard to keep track of the IP address assigned to all the peers.  Tailscale automatically keeps track of all the connected peers with their IP address and hostname.  This is where my program [tailscale-hosts](https://gitlab.com/jhamberg/tailscale-hosts) comes in.  It parses the output of the `tailscale status --json` command append the hostname and IP address to the /etc/hosts for easy access.  Here is an example of what information is included in the tailscale status command.

```shell
tailscale status
[ERwrT] linux   100.125.175.83  serenity           .
[MNw8B] linux   100.101.102.103 hello.ipn.dev      ...
[Ws5E9] windows 100.123.119.83  prometheus         ...
[ZZbvo] linux   100.76.104.117  awing              ...

```

The tailscale status command has all the information we need to be able to start using the human readable peer names.  Here you can see that all my PC are named after science fiction starship.  Below is an example of how the tailscale-hosts command works.

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

Right now only GNU/Linux is supported, because that's the only platform that has a tailscale client that programatically exposes the peers hostnames.  Eventually the tailscale-hosts package will get put on pip to make the instalation to new computers easier.

# Conclusion

tailscale-hosts makes it very simple to add human readable hostnames to access remote peers instead of hard coded IP addresses.  Which reduces the mental load needed to connect to these services.