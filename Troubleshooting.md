
---


---

## Troubleshooting ##

---


---


Here are some key steps for troubleshooting a general problem with MacZFS.  This goes hand in hand with formulating a support request on the mailing list and/or a code ticket.

Every problem report can help to improve MacZFS, and we welcome general talk.  If you don't know enough to debug a kernel panic or to create an issue ticket, or to know whether those steps are warranted, then you might need to share your problem on the mailing list for group diagnosis.

However, just saying "my box panicked while...." is of limited use.  To find out what went wrong, we need more information.  A report of a Kernel Panic or other unresolved error should contain at least:

  * Did you read the [document on USB](http://code.google.com/p/maczfs/wiki/USB) and on [known issues](http://code.google.com/p/maczfs/wiki/KnownIssues)?

  * Did you try a scrub on another ZFS implementation?  You can boot an OpenIndiana or Illumos liveusb if they have enough drivers for your system, or you can boot Fedora liveusb and run 'yum install zfs-fuse', or you can get a FreeBSD system.  Run your scrub from there, run it again in MacZFS just to be sure, and any of the rare cases of stubbornly recurring errors will probably disappear.

  * Are you using substandard equipment, such as lower quality firewire devices or [almost any USB devices](http://code.google.com/p/maczfs/wiki/USB)?  You may have a hardware problem which HFS+ (and thus, your data) silently suffers through, but which ZFS refuses to tolerate.  Are you trying to hotplug it (plug or unplug such a device while the system is running, especially without exporting your zpools first)?

  * The type of hardware (Macintosh model, homebuilt motherboard, drive enclosures and controller chipset, etc) you are using

  * The operating system version.  Not the code name like "Lion", but the actual version, like "Mac OS 10.7.4" and maybe the output of `uname -a`

  * The architecture: PPC, i386 or x86\_64.  Mac OS 10.7 and higher can only run on x86\_64, so that's given.  For older operating system releases, check Activity Monitor, process list, then locate "kernel\_task".  It should say something like "Intel", "Intel (64-Bit)" or "PPC")

  * The amount of RAM

  * The version of MacZFS installed, which should generally be the current stable release

  * The output of `zpool status -v`, if you can obtain this without a new panic

  * The output of the 'zoink' command

  * Can you always duplicate this behavior?  Even after a fresh reboot?  Even with a different storage system, like HFS+, or another operating system?

  * What implementation of ZFS did you use to create this zpool?  Did you create it using the latest stable MacZFS, using the Getting Started guide?  Or was it made with another partition method, or using another version of ZFS?

  * The output of 'zfs list', if you can obtain this without a new panic

  * Especially if you have a performance problem, try this and paste it:
```
dd if=/dev/zero of=foo bs=1m count=20000
dd if=foo of=/dev/null bs=1m
rm foo
```

  * What you tried to do while the panic happened, and what you expected to happen.

Various Mac OS versions produce different kind of panic reports.  Run "Console.app" and look for things like "CrashReport" "DiagnosticReport" or similar.  If you find a file matching the time of your Kernel
Panic, attach it.  You may want to check and clean the content first using your favorite text editor.  These crash reports have all the information needed, except the output of zpool and zfs and what you were doing from above.

These crash reports look like this (this one is from ZEVO, because it can be easier to panic than MacZFS, although ZEVO has nothing to do with MacZFS and we are not officially ZEVO tech support):

```
-----------------
Interval Since Last Panic Report:  10794501 sec
Panics Since Last Report:          12
Anonymous UUID:                    036BFAD2-6CAF-415E-AD5B-6481662E4F9D

Tue Feb 21 01:07:27 2012
panic(cpu 1 caller 0x1ad754a):
"/Volumes/depot/repo/z410/src/uts/common/fs/zfs/arc.c:3270 Z-410
assertion failed:
BP_GET_DEDUP(zio->io_bp)"@/Volumes/depot/repo/z410/src/uts/darwin/os/printf.c:42
Backtrace (CPU 1), Frame : Return Address (4 potential args on stack)
0x83ec3b88 : 0x21b837 (0x5dd7fc 0x83ec3bbc 0x223ce1 0x0)
0x83ec3bd8 : 0x1ad754a (0x1baffb8 0x1bb1158 0xcc6 0x1bb1d68)
0x83ec3bf8 : 0x1ae4fca (0x1bb1d68 0x1bb1158 0xcc6 0x1ad3b91)
0x83ec3c68 : 0x1b98faa (0xb8cec7e8 0xc00 0x0 0x21)
```


---


---

## Kernel Panics ##

---


---


**Introduction**

Kernel panics which are produced by MacZFS are really no different from kernel panics in general, whether ZFS-related or not.  A panic means that the OS has halted the system to avoid the possibility of making a known problem worse by touching anything.  In other words, either ZFS or XNU have found a situation where it is not willing to risk moving forward, and it volunteered an emergency stop.  In this particular case, it's really a matter of functionality which had simply not been implemented at the time in which Apple had originally branched the ZFS code, rather than there being no safe way to proceed.

Although ZFS will keep the zpool itself in a consistent state in the case of a panic, there is still some potential for data loss (e.g. any dirty pages in memory will simply be discarded).  Thus, there is a risk that the contents of individual files, which were in the process of updates at the time of the panic, could be left in a partially updated state.  Other blocks and files are almost certainly fine.

In summary, kernel panics related to MacZFS are rare, and most users have probably never seen one unless they're [hotplugging their USB devices](http://code.google.com/p/maczfs/wiki/USB).  Do be aware of the special needs of your HFS+ volumes though, as they endure the crash.  Don't consider panics to be normal.

  * You need to download a [Kernel Debug Kit](http://developer.apple.com/hardwaredrivers/download/kerneldebugkits.html) which corresponds to your kernel (need to have a valid ADC account). It will be called something like `kernel_debug_kit_10.6.5_10h574.dmg`
  * Mount it with `hdiutil attach kernel_debug_kit_10.6.5_10h574.dmg` or by double-clicking on the image
  * Generate the symbol files for the installed kernel extension. You will need the first number as displayed in the kernel panic e.g. `com.bandlem.mac.zfs.fs(76.0.7)@0x34f56000->0x34fcffff` will give you `0x34f56000`
```
/Volumes/KernelDebugKit/createsymbolfiles -s /tmp /System/Library/Extensions/zfs.kext/
```
  * Debug into the kernel, specifying -arch i386 or -arch x86\_64 depending on kernel flavour:
```
gdb -arch i386 /Volumes/KernelDebugKit/mach_kernel
```
  * Load the kernel symbolic files:
```
set kext-symbol-file-path /tmp
add-kext /System/Library/Extensions/zfs.kext/
```
  * Look at the individual stack exceptions, as described with `x/i`
```
x/i 0x34f9eb45
0x34f9eb45 <zfs_log_write+654>:	add    %al,(%eax)
```

That will give you a clue as to where the problem is.

**Decoding**

To support easy debugging of panics (on Intel systems, currently) there is a tool in `support/decode-panic` which can generate a list of files, based on the below.

You can acquire a copy of this by doing:

```
curl https://github.com/alblue/mac-zfs/raw/untested/support/panic-decode > panic-decode
chmod a+x panic-decode
panic-decode
```

It will attempt to find the latest ZFS panic and generate the symbols from it. This should be attatched to an issue report for ease of debugging in the future.

Currently, it only works on Intel systems, and it does not check that the version of the kernel is the same as reported in the code. Caveat emptor.