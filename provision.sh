#!/bin/bash
#
# The logic here is split in three parts:
#
#  1) Enable jessie-backports and update the system, then reboot, resulting
#     in a 4.9 kernel and the latest BTRFS tools.
#  2) Set up the block devices and volumes.
#  3) Handle booting a configured systems

set -x
set -e

if uname -r | grep -E '^3\..*'; then
  echo "deb http://ftp.uk.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list
  cat <<-EOF > /etc/apt/preferences.d/backports-pin
# Stable
Package: *
Pin: release a=jessie
Pin-Priority: 500

# Backports
Package: *
Pin: release a=jessie-backports
Pin-Priority: 550
EOF
  apt-get update
  apt-get install -y btrfs-tools cryptsetup linux-headers-amd64 vim
  apt-get upgrade -y
  apt-get dist-upgrade -y
  apt-get autoremove -y

  set +x
  echo "The system will now be shut down.  You will need to issue the"
  echo "following command to power up and have the necessary guest"
  echo "additions installed."
  echo
  echo "    vagrant reload --provision"
  echo
  set -x

  shutdown -h now

elif [ ! -d /etc/luks ]; then

  mkdir /etc/luks
  chmod 700 /etc/luks
  umask 077
  head -c 128 /dev/urandom > /etc/luks/sdb.key
  head -c 128 /dev/urandom > /etc/luks/sdc.key
  head -c 128 /dev/urandom > /etc/luks/sdd.key

  cryptsetup luksFormat --key-file /etc/luks/sdb.key /dev/sdb
  cryptsetup luksFormat --key-file /etc/luks/sdc.key /dev/sdc
  cryptsetup luksFormat --key-file /etc/luks/sdd.key /dev/sdd

  umask 022
  cat <<-EOF > /etc/crypttab
crypt-btrfs1  /dev/sdb  /etc/luks/sdb.key  discard,luks,noearly,noauto
crypt-btrfs2  /dev/sdc  /etc/luks/sdc.key  discard,luks,noearly,noauto
crypt-btrfs3  /dev/sdd  /etc/luks/sdd.key  discard,luks,noearly,noauto
EOF

  cryptdisks_start crypt-btrfs1
  cryptdisks_start crypt-btrfs2

  mkfs.btrfs -d raid1 -m raid1 -L storage /dev/mapper/crypt-btrfs1 /dev/mapper/crypt-btrfs2

  cat <<-EOF >> /etc/fstab
LABEL=storage /storage btrfs noatime,nodiratime,autodefrag,noauto,compress=lzo,nofail,degraded 0 0
EOF

  [ -d /storage ] || mkdir /storage
  mount /storage
  cp -a /bin /storage/

else
  cryptdisks_start crypt-btrfs1
  cryptdisks_start crypt-btrfs2
  mount /storage
fi

btrfs filesystem show /storage

set +x
echo
echo "You may now simulate a disk failure and replacement:"
echo
echo "  sudo /vagrant/simulate-disk-failure.sh"
echo
set -x
