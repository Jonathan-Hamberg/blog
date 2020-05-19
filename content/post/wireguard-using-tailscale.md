---
title: Easy WireGuard setup using TailScale
subtitle:
date: 2020-05-16
tags: ["wireguard", "vpn"]
draft: false

---

# WireGuard



I'm pretty sure that most people have heard about the networking tool called [WireGuard](https://www.wireguard.com/).  It's become very popular in the past couple of years for good reason.  It is dead simple and only supports 1 encryption protocol.  This prevents security flaws by accidentally choosing the wrong encryption parameters, which is easy to do if the tool you are using offers many options.  It easily meets or exceeded the throughput of all other available VPN solutions.  It is also build in to the Linux Kernel as of version 5.6 so there is a likely change that you already have access to it on your computer.  These are just the basic.  If you want to learn more I would suggest a visit to their [website](https://www.wireguard.com/) which explains things much better then I can.

WireGuard has a very simple interface to setup compared to all the other VPN's I've tried using in the past.  Some parts can be considered tedious though.  For every client a new public/private key pair has to be generated.  Then for every preexisting WireGuard client the newly generated public key had to be manually added to the config file.  This was very time consuming and error prone if one of the other WireGuard endpoints was mis-configured.  Also for every new WireGuard endpoint a static IP had to be assigned which could have the possibility of colliding with a preexisting WireGuard endpoint.

# tailscale

This is where a new technology called [tailscale](https://tailscale.com/) comes in.  It allows a user to create a tailscale account using a Google or Microsoft account.  This account is then used to manage a network of tailscale clients which are essentially just WireGuard clients that can be used to communicate with all endpoints in the tailscale network.

Using tailscale removes a lot of the pain points of using WireGuard that I've experienced in the past.  Tailscale sets up the following thing automatically for WireGuard.

* Public/Private key pairs that are automatically synced between endpoints in the tailscale network
* Automatic key rotation which minimizes damage done by leaked private key
* Automatic firewall traversal using NAT Punching with [STUN](https://tools.ietf.org/html/rfc5389) and [ICE](https://tools.ietf.org/html/rfc8445)
* If firewall blocks WireGuard traffic a relay server called [DERP](https://github.com/tailscale/tailscale/tree/master/derp) is used to bypass firewall

Setting up a new tailscale client is as easy as downloading the executable and following the instructions to log on to your tailscale account and then everything else is automatically taken care of.  tailscale then provision a IP for the new client and displays the IPs of all the other clients in the tailscale network.

```sh
jhamberg@falcon ~> tailscale status
[ERwrT] linux   100.xxx.xxx.xxA  serenity           ...
[MNw8B] linux   100.101.102.103 hello.ipn.dev       ...
[Ws5E9] windows 100.xxx.xxx.xxB  prometheus         ...
[ZZbvo] linux   100.xxx.xxx.xxC  awing              ...
```

Here you can see all of my endpoints are accessible by the IP listed in the `tailscale status` command.  Tailscale is cross platform so you can have endpoints on Windows, Linux, Mac, iOS and soon Android.

I've glossed over some of the more advanced features of tailscale which include an audit trail for resource access.  tailscale also has a very detailed Access Control List (ACLs) which allows defined rules to determine which endpoints have access to other endpoints.  This would be very useful for a larger network that contains many different compute resources.

# Conclusion

Tailscale is the tool that I've wanted for a long time that fixes a lot of the paint points I've had with WireGuard in the past.  Tailscale builds of off WireGuard and makes a  network of interconnected clients a breeze to setup.  Right now it's free for individual users which has everything that I could need.