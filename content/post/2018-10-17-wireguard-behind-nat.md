---
title: Wireguard VPN behind NAT
subtitle: How to Setup VPN without Port Forwarding (Keep Alive Packets)
date: 2018-10-17
tags: ["encryption", "networking", "vpn"]
---
In this blog post I would like to show my setup on how I set a VPN to my work account without setting up port forwarding.  Currently I work at a small company that does not have a large IT infrastructure.  The building that we are leasing manages the network for us which means that we cannot customize the network to our needs.  My goal was to be able to ssh into my work PC in case I forget to push some code and didn't want to wait until the next time I came in the office.

# Wireguard

The VPN service I choose to use is called [WireGuard](https://www.wireguard.com/).  WireGuard is a new VPN software that is very small, modern, and simple to use.  The actual implementation is under 5 kLOC.  With WireGuard there is not necessarily a central server.  There are many peers and any peer can connect to any other peer assuming they have the correct authentication credentials. Every peer has a private and public key used to identify its self.

Below I show how to generate the private and public keys that are used to connect to other WireGuard peers.  A private and public key must be generated for every single peer in the network.

```sh
# Generate Private Key
wg genkey
# ANj/cYQOnkhFviLK70fvzK0f5s7IJSocANeTS11gwnE=

# Generate the Public Key from the Private Key.
echo "ANj/cYQOnkhFviLK70fvzK0f5s7IJSocANeTS11gwnE=" | wg pubkey
# xQhNm4o7P55RDuiF+rAcBhWdxKfVx0U/vC507ayvuT4=

# generate Private and Public Key at the same time using one command.
wg genkey | tee privatekey | wg pubkey > publickey
```



## Peer A Configuration

Configuration files should be located in the /etc/wireguard/wg0.conf directory to be used by the wg-quick helper program.

```sh
[Interface]
# Address of the local interface on the PC.
Address = 10.0.0.1/32
# Disable overwritting wg0.conf when wg-quick is used to shut down the interface.
SaveConfig = false
# Port to listen for incoming connections.
ListenPort = 8040
# Private key of the server.
PrivateKey = $PRIVATE_KEY

# Laptop
[Peer]
# Public Key of the peer device.
PublicKey = $PUBLIC_KEY
# Only allow peers with the following IP address.
AllowedIPs = 10.0.0.2/32

# Work PC
[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 10.0.0.3/32
Endpoint = external-ip-of-peer-b:8040
PersistentKeepalive = 25

```

## Peer B Configuration

```sh
[Interface]
Address = 10.0.0.3/32
SaveConfig = false
ListenPort = 8040
PrivateKey = $PRIVATE_KEY

[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 10.0.01/32
Endpoint = external-ip-of-peer-a:8040
PersistentKeepAlive = 25
```

All the information that is really needed to configure the WireGuard is the interface IPs, endpoint IPs, and keys.  One important setting to take notice of is the PersistentKeepAlive.  This setting will send a handshake to the endpoint every 25 seconds.  This is important because if the keep alive packets are not send to the endpoint, the client will not be able to establish a connection to the WireGuard server.  This is because the WireGuard is behind a Network Address Translation (NAT) table.  This is what converts an external connection to a IP address to IP address of the PC in the internal private network.  If the KeepAlive packets are sent out periodically, whenever a connection is established the route is configured in the NAT to the correct private IP address of the WireGuard server.

# Network Interface Creation

To start using WireGuard the wg-quick command can be used to lead the configuration files and automatically create the Linux network interface.  Just run the following command and then you can connect directly to the IP addresses specified in the network configuration files.

```sh
# Bring network interface up for the wg0.conf configuration file.
wg-quick up wg0

# Bring network interface down for the wg0.conf configuration file.
wg-quick down wg0

# Add wg-quick up command to run on start-up.
systemctl enable wg-quick@wg0

# Run the following command to allow ipv4 forward through the VPN.
# In file /etc/sysctl.conf uncommend the following line.
net.ipv4.ip_forward=1

# Run this command to make the change take effect.
sysctl -p
```

To show that you actually have a valid VPN connection try to connect to the remote peer using ssh.  Now you have a simple easy to use private VPN connection to another computer on another network.