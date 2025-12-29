# Nuage: my RPI cluster on PXVIRT for a tiny home cloud
This repo is both my toolbox for my RPI5 based Proxmox cluster and a way of documenting the process so I don't tear the f***ing place down next time I make one from scratch. This is a work in progress (as all homelabs are) and things can change/break pretty much all the time. Also, most of the time I have no idea of what I'm doing exactly.

Any way, I'm welcoming feedback and ideas. I'm here to learn!

## First and foremost

Thanks to the communities who develop and maintain all the things that made it possible for people like me to pursue that kind of projects.

- [PXVIRT](https://github.com/jiangcuo/pxvirt)
- [Proxmox arm64 Install Scripts](https://github.com/asylumexp/Proxmox)
- And all the others that I'll add on the road

## Goals

My goals are:

- to selfhost a bunch of services to deGoogle/deApple as much as possible
- to learn some basics of networking
- to learn (the basics of) how a HA cluster works
- to move my dev VMs on a server and clean my laptop a bit

## Hardware

To create a stable Proxmox cluster, you need at least 3 nodes. If you get more, you'll want to have an odd number because it's what's best for getting a quorum. I decided to use RPI5 16GB as my nodes.

To reduce the amount of cables, I chose to PoE my nodes. I went with the Netgear GS308EPP which is reasonably priced, is manageable, very compact and comes with a comfortable 123W PoE budget. And for the PoE HATs, I got the Waveshare PoE HAT (H) because I already had active coolers on the RPIs.

### TLDR, for each node I use:

- 1 RPI5 16GB
- 1 PoE HAT (optional)
- 1 patch cable
- 1 micro SD (at least 32GB)
- 1 Pimoroni Duo NVMe base
- 2 NVMe disks (I went for 2x1TB, for now)

## Setup

### Network architecture

- TODO Isolate the cluster on a subnet
- TODO Create VLANs to logically separate traffic types

### Preparing the nodes

As there is no need to reinvent the wheel, I based my setup process on [this excellent tutorial from PiMyLifeUp](https://pimylifeup.com/raspberry-pi-proxmox/).

I'm running Proxmox VE 8.4 with Ceph 19.2 on Raspberry Pi OS Lite 12 (Bookworm). I tried with PVE9 and PiOS 13 but ended up every time with a SEGFAULT, and I'm out of my depth so until it's fixed by people way more technical than me, I'm staying in my lane.

For each node:

1. Flash the micro SD with Raspberry Pi OS Lite Bookworm
2. Reserve an IP address on the router
    - For clarity: *nameofcluster*01 → *xxx.xxx.xxx*.101
    - Also, be sure not to chose an already assigned ip address, or you'll lose a lot of time...
3. Load the micro SD and boot the RPI
4. SSH in and execute `sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/karldelandsheere/proxmox-rpi/refs/heads/main/scripts/node-setup.sh)"`
5. Create the cluster on the first node and join the others to it
6. Setup Ceph and add the disks (TODO List all the steps)

### Hosted services (non exhaustive)

#### Cloudflare-DDNS

I don't have a static IP, so I'm using Cloudflare DDNS Updater to update my headscale's CNAME.

1. Connect to Cloudflare and create an API Token
2. https://pimox-scripts.com/scripts?id=cloudflare-ddns

#### Headscale

I use Headscale to access my nodes securily without having to open my router's ports. As you can't have a tunnel behind a tunnel, this is the only service that needs to be exposed outside of Cloudflared. So after the LXC is up and running, you need to setup Cloudflare-DDNS for it.

1. https://pimox-scripts.com/scripts?id=headscale
2. Setup Cloudflare-DDNS for exposure
3. Don't forget to add SSL cert and key files
4. Edit /etc/headscale/config.yaml
	1. Add SSL paths
	2. Remove MagicDNS
5. Add each node to the tailnet
	1. `curl -fsSL https://tailscale.com/install.sh | sh`
	2. `tailscale up --login-server=... --accept-routes` or `tailscale login --login-server=...` if tailscale already has a server

Don't forget to add your device for remote access, otherwise it's pretty pointless...

#### Wireguard (TODO)

As a redundance for Headscale, I'll setup a Wireguard VPN. But that's for later.

#### Cloudflared

I'm using Cloudflare Tunnels (or cloudflared) to expose my services securily without opening my router's ports. It's quick, easy and free. So for now I'll use that, and maybe I'll do something less dependant later. Just follow the documentation for this one.

1. https://pimox-scripts.com/scripts?id=cloudflared
2. https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/

#### OpenCloud (TODO)

I'm chosing OpenCloud to host my files. But I'll do that later.

#### Home Assistant (TODO)

I'm going to add Home Assistant to manage my IoTs and monitor the consumption of my cluster. It's in progress but I'll document it later.

Cheers!
