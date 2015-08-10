
---


---

# Table of Contents #

---


---


  * [Repositories](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Repositories)
  * [Development Tasks](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Development_Tasks)
  * [Building](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Building)
  * [Manual Installation](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Manual_Installation)
  * [Release Guidelines](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Release_Guidelines)
  * [Developer References](http://code.google.com/p/maczfs/wiki/DevelopmentOverview#Developer_References)


---


---

# Repositories #

---


---


If you are working on development, please publish your work and cc the [maczfs-devel](http://groups.google.com/group/maczfs-devel) mailing list as much as possible.  Do your diligence to get your work tested and merged with the official repository on Google Code.  If you're interested in the status of development, subscribe to the mailing list and to these repositories.

## Experimental Generation ##
  * https://github.com/zfs-osx Currently underway with rapid results.

## Stable Generation ##

### Official Release ###

http://code.google.com/p/maczfs/source/checkout

### Distributed Forks ###

Alex Blewitt:
http://github.com/alblue/mac-zfs
```
git clone git://github.com/alblue/mac-zfs.git

Current work (execute inside your clone):
git checkout untested
```

Björn Kahl:
Activity Overview: https://github.com/BjoKaSH
```
git clone git://github.com/BjoKaSH/mac-zfs.git

Current work (execute inside your clone):
git checkout maczfs_74-3-release
git checkout maczfs_74-3-Mavericks-Tests
git checkout linear_78b
```

Dustin Sallings (the original post-Apple source code, deprecated pending his return):
Web View: http://github.com/dustin/mac-zfs
```
git clone git://github.com/dustin/mac-zfs.git
```


---


---

# Development Tasks #

---


---


  * [Issue Tracker](http://code.google.com/p/maczfs/issues/list)
  * [Porting Notes](http://code.google.com/p/maczfs/wiki/PortingNotes)
  * [Roadmap](http://code.google.com/p/maczfs/wiki/Roadmap)
  * [Wishlist](http://code.google.com/p/maczfs/wiki/WishList)


---


---

# Building #

---


---


## Target ##
The default build host (the system it's built on) has been Mac OS 10.6 and XCode 3.  The build targets have been 10.5 and 10.6, Intel and PowerPC.  The 10.6 package is then installed on 10.6 and higher.

[This document](http://catacombae.blogspot.com/2011/07/installing-xcode-326-in-mac-os-x-lion.html) says that we can manually install XCode 3 on Mac OS 10.7, so please let us know if this works or if 10.8 works.

## Host ##
You can easily install your unmodified retail Mac OS 10.6 DMG image or DVD disc in a virtual machine such as VirtualBox, as your build host.  You can acquire XCode 3 using a free-of-charge [Mac Dev](http://developer.apple.com/) account.  If its package certificate is expired for you, you can either temporarily reset your build host's system clock to Februrary of 2012, or [permanently convert the package](http://managingosx.wordpress.com/2012/03/24/fixing-packages-with-expired-signatures/).  There is a new build system, based on 'make', in Bjoern's repository.  More info is coming soon.


---


---

# Manual Installation #

---


---


The tar ball will extract a “build” directory. After you’ve made a backup of your currently installed MacZFS:

  * /usr/sbin/zfs
  * /usr/sbin/zpool
  * /usr/lib/libzfs.dylib
  * /System/Library/Extensions/zfs.kext
  * /System/Library/Filesystems/zfs.fs

```
cd /
sudo gnutar cvO usr/sbin/zfs usr/sbin/zpool usr/lib/libzfs.dylib System/Library/Extensions/zfs.kext System/Library/Filesystems/zfs.fs > ~/maczfs_backup.tar
```

you can:

```
sudo cp build/Leopard_Release/zfs /usr/sbin/zfs
sudo cp build/Leopard_Release/zpool /usr/sbin/zpool
sudo cp build/Leopard_Release/libzfs.dylib /usr/lib/libzfs.dylib
```

Not sure about cp(1) semantics, so we blow the existing directories away

```
sudo /bin/rm -rf /System/Library/Filesystems/zfs.fs /System/Library/Extensions/zfs.kext

sudo cp -R build/Leopard_Release/zfs.fs /System/Library/Filesystems/zfs.fs
sudo cp -R build/Leopard_Release/zfs.kext /System/Library/Extensions/zfs.kext
```

Also, make sure that all the files are owned by root:wheel after you have copied them over. If not you can do:

```
sudo chown -R root:wheel /System/Library/Extensions/zfs.kext
sudo chown -R root:wheel /System/Library/Filesystems/zfs.fs
sudo chown -R root:wheel /usr/sbin/zpool
sudo chown -R root:wheel /usr/sbin/zfs
sudo chown -R root:wheel /usr/lib/libzfs.dylib
```

Then reboot.


---


---

# Release Guidelines #

---


---


Packages can be made using PackageMaker, downloadable with a free-of-charge [Apple Developer Connection](http://developer.apple.com/) account.  Log in, visit [here](http://developer.apple.com/downloads/index.action), search for "PackageMaker", and download "Auxiliary Tools for XCode".

```
- All releases produced by members of the community and originating
  from a common code base, but not considered official should carry
  the label "MacZFS-<version>-<feature_or_author>"  in the filename
  of the release archive

- All such releases must include a readme.txt detailing the author
  creating the releases, identifying the newest official release it
  is based on, and the changes compared to the official release it is
  based on.

- All such releases must use a custom bundle identifier for the kext,
  either completely custom by the author, or in the form of
  "org.maczfs.<author>.zfs"

- The bundle identifiers "org.maczfs.stable.*", "org.maczfs.devel.*",
  "org.maczfs.pre.*", "org.maczfs.testing.*" and "org.maczfs.beta.*"
  are reserved.

- It goes without saying, that no-one should ever abuse someone else
  identifier, including the "com.bandlem.*" identifiers currently
  used by Alex for his releases and kind of hard-coded into the sources
  as found in the alblue/mac-zfs repository at Github and in the
  repository at code.google.com/p/maczfs.

- The community will maintain the notion of an official release,
  prepared by a senior contributor or small team and selected based on
  technical merit, long standing contribution, custom and consensus.
  Currently and for the foreseeable future these are Alex and his
  releases.

- The official releases will use the bundle identifier
  "org.maczfs.stable.*"

- All executables, be it in official or unofficial releases, must
  report in their "help" message or, if supported, in their response
  to a "version" command of what ever kind, the release they are part
  of.  This report must include at least the bundle identifier and the
  version number.  It should include a git commit ID identifying from
  which revision they are build.

- An executable that links against libzfs or libzpool should also
  report the bundle identifier and version of the library used in that
  specific invocation.
```


---


---

# Porting #

---


---


## Introduction ##

There are a number of differences between OSX and OpenSolaris that make porting more of a challenge than in other environments (including FreeBSD).

## vnode\_t ##

Mac OSX defines a `vnode_t` to be a pointer to a `struct vnode *`; but in OpenSolaris, a `vnode_t` is a pointer to a `struct vnode`. This was previously handled by [Issue 27](http://code.google.com/p/maczfs/issues/detail?id=27) and a set of `#ifdef` around the types - but this grows to be a porting problem generally.

To solve this problem, `zfs_context.h` defines a `#def` to replace `vnode_t` on the fly with `struct vnode`. That way, we're source compatible at the point of use. However, this then breaks Mac OSX libraries like `ubc.h` and `mount.h` which (understandably) need to use the right type.

This means we need to (conditionally) replace any system headers, including:

| **Original code** | **Replacement** |
|:------------------|:----------------|
| `#include <sys/mount.h>` | `#include <maczfs/maczfs_mount.h>` |
| `#include <sys/file.h>` | `#include <maczfs/maczfs_file.h>` |
| `#include <sys/ubc.h>` | `#include <maczfs/maczfs_ubc.h>` |
| `#include <libc.h>` | `#include <maczfs/maczfs_libc.h>` |

For ease of subsequent modification, the code should be conditioned as follows:

```
#ifdef __APPLE__
#include <maczfs/maczfs_mount.h>
#else
#include <sys/mount.h>
#endif /* __APPLE__ */
```

## `ZFS_IOC_` not defined ##

For various weird and whacky reasons, MacZFS needs to have `zfs_cmd_t` defined before the IOCs are defined (see IOCTL). The net effect of this is any import that uses `libzfs_impl.h` needs to have `libzfs_ioctl.h` before it (assuming it uses the `ZFS_IOC_` constants). See [Issue 57](http://code.google.com/p/maczfs/issues/detail?id=57).

In other words, this:

```
#include "libzfs_impl.h"
...
#ifdef __APPLE__
#include "libzfs_ioctl.h"
#endif
```

needs to become this:

```
#ifdef __APPLE__
#include "libzfs_ioctl.h"
#endif

#include "libzfs_impl.h"
...
```

## `IO_APPEND` vs `FAPPEND` ##

Mac OS X uses IO\_APPEND in the kernel to denote appending, instead of FAPPEND. So various `#ifdef` are set up to call with the same parameters but a switch of flag name.

## VFS Flags ##

Instead of using bitwise flags (like `z_vfs->vfs_flag & VFS_RDONLY`) OSX uses functions in `mount.h` to achieve the same thing.

  * `z_vfs->vfs_flag & VFS_RDONLY` is replaced with `vfs_isrdonly(z_vfs)`
  * `z_vfs->vfs_flag &= ~VFS_RDONLY` is replaced with `vfs_clearflags(z_vfs, MNT_RDONLY` (t steflags, where appropriate)


---


---

## Developer References ##

---


---

A collection of references to MacOSX kernel/fs dev

  * [KernelDebugging](http://code.google.com/p/maczfs/wiki/KernelDebugging), our own wiki
  * [KernelPanic](http://code.google.com/p/maczfs/wiki/KernelPanic), our own wiki
  * [Troubleshooting MacZFS](http://code.google.com/p/maczfs/wiki/Troubleshooting), our own wiki
  * [PortingNotes for MacZFS](http://code.google.com/p/maczfs/wiki/PortingNotes), our own wiki
  * ["XNU, the kernel"](http://www.puredarwin.org/developers/xnu) by PureDarwin (kinda old)

  * [Kext debugging](http://developer.apple.com/mac/library/DOCUMENTATION/Darwin/Conceptual/KEXTConcept/KEXTConceptDebugger/hello_debugger.html) from developer.apple.com
  * [TN2063](http://developer.apple.com/mac/library/technotes/tn2002/tn2063.html) understanding kernel panic logs
  * [Search the Mac Dev downloads](https://developer.apple.com/downloads/index.action) for "kernel debug kit"
  * [Debugging a kernel panic](http://blob.inf.ed.ac.uk/sxw/2010/01/17/debugging-a-mac-os-x-kernel-panic/) by Simon, which suggests that a EDX containing 0x0 is symptomatic of a null dereference.
  * [Inside the Mac OS X Kernel](http://events.ccc.de/congress/2007/Fahrplan/attachments/986_inside_the_mac_osx_kernel.pdf)
  * [enable serial console on Mac OS](http://www.club.cc.cmu.edu/~mdille3/doc/mac_osx_serial_console.html)

Kernel
  * http://developer.apple.com/mac/library/documentation/Darwin/Conceptual/NKEConceptual/intro/intro.html
  * [list of Darwin bootloader flags](http://www.insanelymac.com/forum/topic/99891-osx-flags-list-for-darwin-bootloader-kernel-level/)

IO Kit
  * http://developer.apple.com/mac/library/documentation/DeviceDrivers/Conceptual/WritingDeviceDriver/Introduction/Intro.html

Debugging drivers
  * http://developer.apple.com/mac/library/documentation/DeviceDrivers/Conceptual/WritingDeviceDriver/DebuggingDrivers/DebuggingDrivers.html#//apple_ref/doc/uid/TP30000701-BBCFBJJI

Other
  * http://osxbook.com/ is a very good book which covers earlier releases of OS X, which is written by the author of [MacFUSE](http://code.google.com/p/macfuse/).