
---


---

# Kernel Debugging #

---


---



## Virtualization ##
  * With VMware: [Reverse Engineering Mac OS X](http://reverse.put.as/2009/03/05/mac-os-x-kernel-debugging-with-vmware/)
  * With VMware: [VMware debugging II: "Hardware" debugging](http://ho.ax/tag/vmware/)
  * Please supply docs for use with free virtual machines, such as VirtualBox, Qemu, and Bochs

## Dual-Machine ##
You need two machines, both running exactly the same version of OSX (e.g. 10.5.8 and 10.5.8, or 10.6.2 and 10.6.2). It helps if they're the same architecture, but this isn't strictly necessary.

You'll need to download the OSX [Kernel Debug SDK](http://developer.apple.com/sdk/) for the OS version you're currently using/targeting. When mounted, it will show up as `/Volumes/KernelDebugKit` for whatever version you're using.

You need a mechanism for transferring files between the two computers. One way of doing this is to export a common directory over NFS; another is to use `rsync`. For the purposes of this document, I'll assume that you have a directory `/target` and that the machine is called `target` as well, so that `rsync -cav . target:/target` will copy your files across.

You need to have enabled your target box to go into a debug state upon a kernel panic, or upon the power button being depressed (usually used to put the machine to sleep). This only needs to be done once per machine, since it's stored in hardware status.

  * `sudo nvram boot-args="debug=0x14e"`

Alternatively, you can put it in the `/Library/Preferences/SystemConfiguration/com.apple.Boot.plist` under the `Kernel Flags` entry, which makes it suitable for virtual machines

  * `/usr/libexec/PlistBuddy -c 'set ":Kernel Flags" debug=0x14e' /Library/Preferences/SystemConfiguration/com.apple.Boot.plist`


## Debug Flags ##

What do the debug flags mean? Well, they can take one of several values; they're listed at [Apple's Kernel Programming](http://developer.apple.com/library/mac/documentation/Darwin/Conceptual/KernelProgramming/build/build.html#//apple_ref/doc/uid/TP30000905-CH221-BABDGEGF) documentation. Here is a succinct summary:

  * `0x01` - Halt at boot time and wait for debugger attach
  * `0x02` - Send kernel debugging printf output to console
  * `0x04` - Drop into debugger on non-maskable interrupt
  * `0x08` - Send kernel debugging kprintf to serial port
  * `0x10` - Make ddb(kdb) the default debugger
  * `0x20` - Output diagnostics to system log
  * `0x40` - Allow debugger to ARP and route
  * `0x80` - Support old versions of gdb on newer systems
  * `0x100` - Disable graphical panic dialog

These can be combined, so `0x14e` is Disable graphic + Allow ARP + Send data to serial + Drop on NMI + Send data to console. `0x144` is another common variant; that just has less logging printed.

## Non Maskable Interrupt ##

The non-maskable interrupt, also known as the programmer's button, is invoked by pressing the power switch on most macs. Note that by enabling the NMI the power switch loses its touch-to-sleep or touch-to-shutdown property. If you are using a Mac where there is no power switch, you can also send Command+PowerKey (e.g. if your keyboard has a power button) or Command+Option+Control+Shift+Escape.

By pressing the NMI you gain access to the debugger immediately, and is useful when booting a system normally and then wanting to attach a remote debugger.

## Steps ##

  1. `cd /path/to/maczfs`
  1. `rm -rf build`
  1. `xcodebuild -configuration Debug`
  1. `cd build/Debug`
  1. `ssh target sudo rm -rf /target/*`
  1. `rsync -cav . target:/target`
  1. `ssh target sudo chown -R root:wheel /target`
  1. `ssh target sudo kextload -s /target /target/zfs.kext`
  1. `rsync -cav target:/target/*.sym .`
  1. `gdb -arch i386 /Volumes/KernelDebugKit/mach_kernel`

The debugger can be set up as follows:

  1. `source /Volumes/KernelDebugKit/kgmacros`
  1. `target remote-kdp`
  1. `add-kext zfs.kext`

You're now good to go with debugging. You can attach to the remote target, print out the frame, and then debug to your heart's content.

  1. `attach target`
  1. ...
  1. `kdp-reboot`

If you want to cycle through running test cases, you'll need to add `/target` to your `PATH` and `DYLD_LIBRARY_PATH` variables. This is easy to do with `env` when running cases:

  1. `ssh target env PATH=/target DYLD_LIBRARY_PATH=/target zpool scrub`

# References #

  * [Developer References](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Developer_References)