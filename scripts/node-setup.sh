#!/usr/bin/env bash
# Author: Karl Delandsheere

set -e


# Get some basics
# ---------------

NODENAME=$(hostname)
NODEIP=$(ip -o -4 addr show eth0 | awk '{print $4}' | cut -d/ -f1)
GATEWAY=$(ip route | grep default | awk '{print $3}')


# Let's go
# --------

echo ""
echo "=================================================="
echo ""
echo " Proxmox installation script, let's go!"
echo ""
echo " This node is $NODENAME and its IP is $NODEIP"
echo ""


# Update apt and upgrade everything
# ---------------------------------

apt update -y && apt full-upgrade -y


# Edit /etc/hosts
# ---------------

# Check if we have them
if [[ -z "$NODENAME" || -z "$NODEIP" ]]; then
  echo "Error: Could not determine hostname or IP address."
  exit 1
fi

# Backup /etc/hosts before editing
cp /etc/hosts /etc/hosts.bak.$(date +%F_%T)

# Replace the IP address before the hostname (handles spaces or tabs)
sudo sed -i -E "s|^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+$NODENAME\$|$NODEIP\t$NODENAME|" /etc/hosts

echo "/etc/hosts updated: $NODENAME => $NODEIP"


# Set the root password (change that before launching the script)
# ---------------------

ROOTPW="root is the root password"
echo "root:$ROOTPW" | chpasswd


# Get the GPG key for Pxvirt's repo and add the sources, then update apt
# ----------------------------------------------------------------------

curl -L https://mirrors.lierfang.com/pxcloud/lierfang.gpg | sudo tee /usr/share/keyrings/lierfang.gpg > /dev/null

source /etc/os-release
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/lierfang.gpg] https://mirrors.lierfang.com/pxcloud/pxvirt $VERSION_CODENAME main" | sudo tee  /etc/apt/sources.list.d/pxvirt-sources.list
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/lierfang.gpg] https://mirrors.lierfang.com/pxcloud/pxvirt $VERSION_CODENAME ceph-squid" | sudo tee  /etc/apt/sources.list.d/pxvirt-ceph.list

apt update -y && apt full-upgrade -y


# Install ifupdown2 (needed for Proxmox)
# -----------------

rm /tmp/.ifupdown2-first-install || true # in case there's a previous install
apt install ifupdown2 -y


# Set the network interfaces up
# -----------------------------

# Backup existing interfaces file  before editing
cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%F_%T)

# Write new interfaces config
sudo tee /etc/network/interfaces > /dev/null <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual

auto vmbr0
iface vmbr0 inet manual
    address $NODEIP
    gateway $GATEWAY
    netmask 255.255.255.0
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0
EOF

echo "/etc/network/interfaces updated with IP $NODEIP and gateway $GATEWAY"

# Install Proxmox
# During Proxmox install, it prompts for overwriting some config files, nope.
# ---------------------------------------------------------------------------

DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" install -y proxmox-ve pve-manager qemu-server pve-cluster ceph


# Voilà
# -----

echo ""
echo "=================================================="
echo "That's it! After this node reboots, Proxmox should be accessible at:"
echo ""
echo "   https://$NODEIP:8006"
echo ""
echo "Connect to Proxmox and select Linux PAM as the realm."
echo ""

DELAY=10
echo "/!\ System will reboot in $DELAY seconds. Press Ctrl+C to cancel."
sleep "$DELAY"
reboot

#
# -----------------------------------------------------------------------------
