# Set up a LUKS+BTRFS RAID1 storage, and simulate failure and replacement

This is an automated environment to set up LUKS + BTRFS RAID1 volume.  Once
that's configured you can then simulate a failure.

For this to work it's neccessary to use the jessie-backports 4.9 kernel and
btrfs-tools.  See the [[Kernel failure]] section below for what happens with
the stock 3.16 kernel.

## Usage

1. First, start the system with the base provisioning, then restart it so we
   have the latest kernel, then SSH in to the instance.

        vagrant plugin install vagrant-vbguest
        vagrant up
        vagrant reload --provision
        vagrant ssh

2. On the system simulate a disk failure and attempt to replace the failed
   disk.

        sudo /vagrant/simulate-disk-failure.sh

## Caveats

While debugging this the folks on irc:://freenode.net/#btrfs pointed me at
some valuable links for this scenario:

- Once only RW:
  https://btrfs.wiki.kernel.org/index.php/Gotchas#raid1_volumes_only_mountable_once_RW_if_degraded
- Incomplete chunk conversion:
  https://btrfs.wiki.kernel.org/index.php/Gotchas#Incomplete_chunk_conversion

## Kernel failure with stock debian jessie 3.16 kernel

In the stock debian jessie 3.16 kernel it is not possible to replace a missing
disk.  The failurel results in the following kernel NULL pointer dereference.


```
[ 1414.906892] BTRFS: open /dev/mapper/crypt-btrfs1 failed
[ 1414.907698] BTRFS info (device dm-1): enabling auto defrag
[ 1414.907701] BTRFS info (device dm-1): allowing degraded mounts
[ 1414.907702] BTRFS info (device dm-1): disk space caching is enabled
[ 1416.017128]  sdd: unknown partition table
[ 1416.098432] BTRFS: dev_replace from <missing disk> (devid 1) to /dev/mapper/crypt-btrfs3 started
[ 1416.174657] BTRFS: dev_replace from <missing disk> (devid 1) to /dev/mapper/crypt-btrfs3) finished
[ 1416.174699] BUG: unable to handle kernel NULL pointer dereference at 0000000000000088
[ 1416.174939] IP: [<ffffffffa0189acd>] btrfs_kobj_rm_device+0x1d/0x40 [btrfs]
[ 1416.175180] PGD 3c321067 PUD 37397067 PMD 0
[ 1416.175308] Oops: 0000 [#1] SMP
[ 1416.175409] Modules linked in: dm_crypt algif_skcipher af_alg dm_mod vboxsf(O) nfsd auth_rpcgss oid_registry nfs_acl nfs lockd fscache sunrpc crc32_pclmul ppdev evdev aesni_intel aes_x86_64 lrw gf128mul glue_helper ablk_helper cryptd serio_raw pcspkr parport_pc parport ac button battery video processor vboxvideo(O) drm thermal_sys vboxguest(O) autofs4 ext4 crc16 mbcache jbd2 btrfs xor raid6_pq sg sd_mod crc_t10dif crct10dif_generic ahci floppy libahci libata crct10dif_pclmul crct10dif_common psmouse e1000 i2c_piix4 i2c_core scsi_mod crc32c_intel
[ 1416.177002] CPU: 0 PID: 1173 Comm: btrfs Tainted: G           O  3.16.0-4-amd64 #1 Debian 3.16.43-2+deb8u2
[ 1416.177243] Hardware name: innotek GmbH VirtualBox/VirtualBox, BIOS VirtualBox 12/01/2006
[ 1416.177452] task: ffff88003d1ce210 ti: ffff88003cdfc000 task.ti: ffff88003cdfc000
[ 1416.177749] RIP: 0010:[<ffffffffa0189acd>]  [<ffffffffa0189acd>] btrfs_kobj_rm_device+0x1d/0x40 [btrfs]
[ 1416.178029] RSP: 0018:ffff88003cdffce0  EFLAGS: 00010286
[ 1416.178155] RAX: 0000000000000000 RBX: 0000000000000000 RCX: ffff880036e6a998
[ 1416.178539] RDX: ffff880036e5ac10 RSI: ffff880036c7b600 RDI: ffff88003c646280
[ 1416.178925] RBP: ffff88003cdffd58 R08: 000000000000000a R09: 00000000000001e7
[ 1416.179278] R10: 0000000000000000 R11: ffff88003cdffa2e R12: ffff88003bde7dc8
[ 1416.179635] R13: ffff88003aa36000 R14: ffff880036e5ac00 R15: ffff880036c7b600
[ 1416.179996] FS:  00007f0a213be8c0(0000) GS:ffff88003fc00000(0000) knlGS:0000000000000000
[ 1416.180542] CS:  0010 DS: 0000 ES: 0000 CR0: 000000008005003b
[ 1416.180841] CR2: 0000000000000088 CR3: 000000003c320000 CR4: 00000000000406f0
[ 1416.181429] Stack:
[ 1416.181805]  ffff88003bde7000 ffffffffa01df3f3 ffff88003bde7100 ffff88003bde7e38
[ 1416.182593]  0000000005400000 ffff88003c481800 ffffffffa0173b90 ffff88003d1ce210
[ 1416.183256]  0000000000000000 00ff88003cdffd20 ffff88003bde7000 ffff88003c481800
[ 1416.184034] Call Trace:
[ 1416.184420]  [<ffffffffa01df3f3>] ? btrfs_dev_replace_finishing+0x313/0x5b0 [btrfs]
[ 1416.185099]  [<ffffffffa0173b90>] ? start_transaction+0x90/0x5a0 [btrfs]
[ 1416.185541]  [<ffffffffa01df9fa>] ? btrfs_dev_replace_start+0x36a/0x440 [btrfs]
[ 1416.186396]  [<ffffffffa01a9d4e>] ? btrfs_ioctl+0x1ade/0x2b50 [btrfs]
[ 1416.186965]  [<ffffffff8116c0fc>] ? handle_mm_fault+0x63c/0x1150
[ 1416.187465]  [<ffffffff81058321>] ? __do_page_fault+0x1d1/0x4f0
[ 1416.187963]  [<ffffffff8109ea37>] ? put_prev_entity+0x57/0x350
[ 1416.188420]  [<ffffffff8109d846>] ? set_next_entity+0x56/0x70
[ 1416.189067]  [<ffffffff811bd54f>] ? do_vfs_ioctl+0x2cf/0x4b0
[ 1416.189469]  [<ffffffff811bd7b1>] ? SyS_ioctl+0x81/0xa0
[ 1416.189869]  [<ffffffff8151c4a8>] ? page_fault+0x28/0x30
[ 1416.190306]  [<ffffffff8151a48d>] ? system_call_fast_compare_end+0x10/0x15
[ 1416.190803] Code: 5b 5d 4c 89 e0 41 5c 41 5d 41 5e 41 5f c3 0f 1f 44 00 00 53 48 8b bf f0 09 00 00 48 85 ff 74 1f 31 db 48 85 f6 74 14 48 8b 46 78 <48> 8b 80 88 00 00 00 48 8b 70 38 e8 e3 2c 09 e1 89 d8 5b c3 bb
[ 1416.192635] RIP  [<ffffffffa0189acd>] btrfs_kobj_rm_device+0x1d/0x40 [btrfs]
[ 1416.193361]  RSP <ffff88003cdffce0>
[ 1416.193649] CR2: 0000000000000088
[ 1416.194995] ---[ end trace caa9c0215a900e44 ]---
```
