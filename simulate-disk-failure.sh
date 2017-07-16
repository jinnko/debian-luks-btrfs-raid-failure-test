#!/bin/sh

set -x
set -e

# Simulate a failure
umount /storage
cryptdisks_stop crypt-btrfs1

mount /storage
btrfs filesystem show /storage

cryptdisks_start crypt-btrfs3
btrfs replace start 1 /dev/mapper/crypt-btrfs3 /storage

sleep 2

btrfs filesystem show /storage
dmesg | tail
