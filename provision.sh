#!/bin/bash

set -x

if [ ! -d /etc/luks ]; then
  apt-get update
  apt-get install -y btrfs-tools zsh tmux cryptsetup vim
  apt-get upgrade -y
  apt-get dist-upgrade

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
