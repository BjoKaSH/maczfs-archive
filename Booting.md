
---


---

# Project Root Camp #
## Booting XNU from non-HFS ##

---


---

## Situation report: "very do-able" -- non-HFS is virtually done -- ZFS is mostly done ##

[Current executive summary](https://groups.google.com/d/msg/zfs-macos/r754hewYsPs/f7q8QkxkE14J)

[Screenshot](http://i.imgur.com/NhzTY.jpg)

[Source code](https://github.com/meklort/xnu-fsroot)

This is the feasibility study for project Root Camp, a consortium of bootable filesystems for a post-HFS+ world.  Featuring ZFS, we'll document the strategies and challenges of booting without HFS+.  Someday, there might be ramdisk support for booting FUSE filesystems, but we are presently only targeting kernel space.  If it becomes bloated, we can call it Hippo Campus.

Root Camp is almost functional, and doesn't yet have any candidates other than ZFS.  Please inform us of any other kext-based filesystem drivers for XNU, which have free source code.


---


---

## Boot Loader Strategy ##

---


---

  * **boot.efi**
    * This has the benefit of being generally noninvasive.  Does it require a Mac, or will it work on a clone?
    * write/port a custom filesystem module for EFI, probably porting it from grub
    * interested parties: 'snare' in #mac-zfs, author of [the EFI rootkit presentation](http://ho.ax/posts/2012/07/black-hat-usa-2012/)
    * possibly employ some mac clone technologies like kext injection
  * **Chameleon**
    * This is native to PureDarwin installations and to Mac clones.  It can run with on Macs with an invasive change, but could maybe be adapted to be noninvasive on Macs.
    * write/port a custom ZFS driver for Chameleon, probably porting it from grub
    * interested parties: 'meklort' in #puredarwin
  * **grub**
    * This has the benefit of being generally noninvasive, on both Macs and clones.
    * grub supports ZFS and it supports XNU.  Mixed like chocolate and peanut butter?  Please test.
    * install grub as an EFI target, and then boot ZFS from that
  * **boot/root**
    * "You can boot into zfs using the same trick that raid (or universal restore) uses: create a hidden small partition to act as the boot volume with minimal kernel extensions (but enough to use zfs) then switch over the / to point to the main disk." -- alblue.  "It'd help for boot loader issues, but not for XNU issues.  XNU still needs to know how to mount it." -- Meklort.
    * Write a new kext to discover and enumerate the root device, and inform zfs.kext, which is the chosen strategy as listed below.
    * unionfs
      * Once we fix a kernel panic in the unionfs portion of XNU's VFS code, we'll be able to implement something not entirely unlike Linux's root pivot functionality.  Then, we can involve userspace, and thus boot from FUSE.  Because this is a bug in XNU's VFS, it can't be patched via a kext, and it must be patched via direct source code in XNU or via the realtime XNU patcher function of the Chameleon boot loader.  So it will only work on a stock Macintosh system once the boot loader is replaced, which is not terribly invasive.  Or else, we get Apple to patch Darwin.


---


---

## Root Filesystem Strategy ##

---


---

This segment was completed by Meklort on the first day, in part due to his previously work on the [ModCD](http://prasys.info/2010/10/nawcom-modcd-v0-3-is-out/) project.

As a precursor, for the reader's information, here's a discussion of the current methods by which XNU actually loads its root filesystem.

  * primary (preferred)
    * boot loader locates the root device
    * boot loader determines a UUID of the filesystem and sets the boot-uuid property in /chosen
    * XNU reads this and then scans the ioregistry for such a device and mounts it as root
  * secondary
    * XNU looks in the device tree to see if a ramdisk was set, by the boot loader
    * if so, it creates the /dev/md0 device to correspond to the ramdisk, and then acknowledges /dev/md0 as the root
      * if not, attempt a netboot
        * if not, tries to find an IOMedia entry in the registry with a filesystem type of Apple\_HFS to boot from
          * if not, prints "Still waiting for root device", and retries in a loop

Other than netbooting, there are two common things between the primary and secondary methods:
  * there must be an entry in the device tree
  * a BSD disk device must exist

Presently, MacZFS 74 does neither of those.  So either XNU must be modified to add another boot method, or some kext must be instructed to create a BSD device file.  Then, zfs.kext must then probe any BSD devices and inform XNU which ones are ZFS volumes.  We'd prefer not to hack the kernel, so here is the latter option.

  * dual-kext system
    * Write one new kext called ZFSRoot.cpp -- two at first, for testing purposes, where one provides symbols and one provides code -- and lightly modify the existing zfs.kext.  ZFSRoot.cpp serves to discover the desired ZFS root device, and to inform zfs.kext of this.  It looks like if you inject a function into the mountroot hook, it'll work.  zfsroot.kext hooks into mountroot, reads some kernel arguments, and tells zfs.kext to mount a volume to `/`.

And the symbol `ffffff80008c8940 S _mountroot` still exists.  Thus, we'll do this:
  * create a new kext which injects a function to replace mountroot
  * add a new kernel command line argument for the root ZFS pool (or a device tree entry), read out that entry, and mount it.  If the bootloader told it to net boot (or if it can't find anything) then it'll use that hook (if it exists) and we can inject it.

Notes:  Meklort would consider the unionfs option, kinda like Linux's pivot root.  Include a small /dev/md0 ramdisk, use that to mount and bypass the 60-second delay, then umount it, and remount root.  A really ugly hack.  IOFindBSDRoot doesn't actually mount root; it just finds it.  So if we can tell it to find one that exists, then switch it out later for ZFS, we're good.


---


---

## Challenges ##

---


---

  * [ZFS itself does not support hosting swap until a later revision of ZFS is achieved.](https://blogs.oracle.com/jimlaurent/entry/faq_using_zfs_for_swap)  The problem with swap on a Copy-on-Write filesystem is that actually writing to swap may require additional kernel memory to be allocated (since you can't just overwrite an existing sector); since memory pressure is the reason you're swapping in the first place, that can obviously be problematic.  We can definitely host it on a separate HFS+ partition, by editing the path in /etc/rc.netboot.  Or we can just do without swap.
  * case insensitivity
    * Does the OS itself require case insensitivity?  I don't think so.  I think it's just a problem with apps and app resources, which can be hosted on a DMG with HFS+.
    * relocate things via symlink trees, using this:
`/System/Library/PrivateFrameworks/PackageKit.framework/Versions/A/Resources/shove`
  * dumb installer apps
    * autodetect HFS+ volumes, exclude the rest
    * break when following symlinks
    * break when the target is not the root volume; attempt to do a rename() and fail across filesystems
    * file bugs with Apple and with other vendors


---


---

## Post-boot ##

---


---

  * launchd
    * If not booting from ZFS, then ensure that ZFS starts ASAP in the boot process.  We want to host home directories on ZFS, so it must simply start at some time prior to login, even if just by way of having no automatic login and having the user wait a little bit.  See /System/Library/LaunchDaemons/com.apple.nfsd.plist for an example of the 'keepalive/pathstate' which checks to make sure that the /etc/exports directory is present before starting (And conversely, killing it will stop the service).
    * Can a directory services plugin force login to wait?

## Resources ##
  * [booting with minimal HFS+ and maximal ZFS (startup/shutdown scripts)](https://groups.google.com/d/topic/zfs-macos/wQLUQh2fZ5Y/discussion)
  * [booting from ZFS](https://groups.google.com/d/topic/zfs-macos/x4ym1z3QbCI/discussion)
  * [GRUB2 as the only boot loader: it's possible!](http://www.insanelymac.com/forum/index.php?showtopic=189079)
  * [ModCD](http://prasys.info/2010/10/nawcom-modcd-v0-3-is-out/) by Nawcom and Meklort
  * [OVMF: Open Virtual Machine Firmware](http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=OVMF_FAQ), a project to enable support for UEFI within Virtual Machines.