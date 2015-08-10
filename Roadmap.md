# Roadmap #


---

**Note:** Development of MacZFS ceased in mid 2013. Please switch to [O3X](https://openzfsonosx.org/)

---




---

## Table of Contents ##

---


  * [Introduction](http://code.google.com/p/maczfs/wiki/Roadmap#Introduction)
  * [Present Assumptions](http://code.google.com/p/maczfs/wiki/Roadmap#Present_Assumptions)
  * [Questions](http://code.google.com/p/maczfs/wiki/Roadmap#Questions)
  * [Booting ZFS](http://code.google.com/p/maczfs/wiki/Roadmap#Booting_ZFS)
  * [Porting to FUSE](http://code.google.com/p/maczfs/wiki/Roadmap#Porting_to_FUSE)
  * [Developer Outreach](http://code.google.com/p/maczfs/wiki/Roadmap#Developer_Outreach)
  * [Building and Packaging](http://code.google.com/p/maczfs/wiki/Roadmap#Building_and_Packaging)
  * [References](http://code.google.com/p/maczfs/wiki/Roadmap#References)


---

## Introduction ##

---


Overall goals:

  * Reorganize project management.
  * Recruit more developers.
  * Improve the Mac OS porting layer
  * Reexamine the upstream code for potentially improved portability, and reevaluate sourcing FreeBSD, ZFS-FUSE, and ZFSonLinux instead of just Solaris.
  * Original path, based on the old OpenSolaris
    * bugs are blocking onnv\_77 (segfault at dataset mount time).
    * onnv\_77 unblocks the port of libzpool
    * libzpool unblocks zdb and ztest
  * [New path, based on the current ZFSonLinux](https://github.com/zfs-osx), currently underway with rapid results
    * Make it link
    * Fix warnings
    * Go through all fixme, and inspect.
    * Go through all API changes and attempt to guess right way (like dmu\_read args went from 5 to 8)
    * Compile userland
    * Issue first ioctl to zfs.kext (zpool status) and see what goes 'boom'
    * Further steps depend upon the size of the 'boom'
    * [Merge platform-independent code into ZFSonLinux](https://github.com/zfsonlinux/zfs/issues/898#issuecomment-8175683), starting with the SPL and then the build system
  * ...
  * PROGRESS!
  * Complete [Project Root Camp](Booting.md), for booting ZFS

We're starting with deciding how to define a roadmap.  The accepted course has been to progressively synchronize upstream until MacZFS reaches the current upstream code, as opposed to starting over with the current upstream ZFS code, as is explained below.  The present stable release is based on onnv\_74, and the next goal is onnv\_77, and so on.  A wild guess would then be 94 or 96.

Concurrently, we need to improve the Mac OS porting layer, which exists substantially in zfs\_context.h.  It was heavily intermingled, by Apple, with the upstream ZFS code, increasing the present difficulty.  The difficulty is further increased due to the way XNU works.  And, concurrently, we can focus on [booting XNU from ZFS](Booting.md).

Project management can be improved.  We need to identify existing issues, prioritize them by priority (order in time) and severity (complexity or requisite skill level), and clean up the issue tracker.  We need to build virtual machine images of PureDarwin, and instructions to do likewise with Mac OS, as a development platform for kernel debugging and for outside help from gracious non-Mac OS users.  A wide variety of skill levels are appropriate to these various tasks.

Once we achieve libzpool, zdb, and ztest, we will achieve a new level of efficacy and speed in porting.

**Update:** MacZFS has reached a fully working state including libzpool, zdb, and ztest with its final release MacZFS-74.



---

## Present Assumptions ##

---


Ryao and Lundman have begun the process of learning how to port ZFSonLinux's ZFS to Mac OS, starting the ZFS componentry from scratch, and reusing as much of MacZFS's Mac OS layer as possible.  With the infusion of additional developers, that this is becoming more feasible and worthwhile than iterating from the past.  Additionally Pavel (the person who ported ZFS to FreeBSD) said that OpenSolaris eventually yielded difficulties later in its history beyond where MacZFS 74 currently is, so an iterative approach has yet unseen trials.

```
"'Just starting again' sounds plausible until you realise what that means in practice. There's a lot of hard coded references to the way osx handles the vfs layer, and the fact that the zfs_context file is a huge blob of carefully crufted macros (including the remapping of the kernel memory alloc function) combined with the vfs functions having structs instead of argument lists, and it's an insane amount of work. 

"By contrast the 77 bits I merged is almost fully functional except for a kernel panic caused by a double free when a file is deleted."
```
> -- alblue

```
"ZDB (as well as ztest) requires a working
 libzpool.  The libzpool is currently broken, it got damaged with Alex's
 merge of onnv_73...after Alex published
 74, I got as far as to recognize that SUN's ZFS portability layer is
 dysfunctional since that merge.

"...making ZDB functional again, will give us ztest almost
 for free.  (And for the records: I started fixing libzpool and ztest
 after I published the new build system, but got interrupted by my
 day-job soon after.  So far libzpool is an estimated 40 - 60 hours of
 work away from being fixed.)

"The libzpool is in essence the ZFS in-kernel code adapted to run in
Userland.  And compiling the same source files once for the kernel and
once for userland requires these "huge blob of carefully crufted
macros (including the remapping of the kernel memory alloc function)"
(as Alex put it perfectly right) called "zfs_context.h"  That file
contains some serious (deep) magic [1] and is really difficult to get
right.

Once libzpool is again working, FUSE might become an option again."
```
> -- Bjoern


---

## Questions ##

---


  * Are the XNU portability assumptions still completely valid?
  * Have the FreeBSD and ZFSonLinux porting procedures varied significantly since MacZFS maintainers last examined them?  Is there a new porting layer, or any other portability improvements in code or in technique which we can benefit from?
  * Were there major changes in OpenSolaris in the time since onnv\_74, which would mean that we'd hit major roadblocks if we continue the iterative approach instead of starting over with FreeBSD?  Pavel, the main guy who ported ZFS to FreeBSD, thinks so.


---

## Booting ZFS ##

---

  * See [Project Root Camp](http://code.google.com/p/maczfs/wiki/Booting)


---

## Developer Outreach ##

---

  * ZFS groups
    * ZFSonLinux (contact was made on IRC, with favorable results)
    * OSXFUSE mailing list (posting was made, no response)
    * [ZFS on NetBSD](http://wiki.netbsd.org/users/haad/porting_zfs/)
  * List of underdog operating systems and OS infrastructure
    * [PureDarwin](http://puredarwin.org/)
    * [OSFree](http://osfree.org), the OS/2 clone
    * [AmigaOS reimplementation](http://aros.sourceforge.net/)
    * WINE: [Darwine](http://darwine.sourceforge.net/), [CodeWeavers](http://codeweavers.com/)
    * [Darbat](http://www.ertos.nicta.com.au/software/darbat/): Darwin, partially ported to L4
    * [ReactOS](http://www.reactos.org/)
    * [TUNES](http://tunes.org/)
    * [The Hurd](http://www.gnu.org/software/hurd/hurd.html)

**Update:** Throughout 2013 MacZFS attracted additional developers and created a new successor project _[OpenZFS on OS X](https://openzfsonosx.org/)_ (_O3X_).  Current development takes place in the O3X project.


---

## Building and Packaging ##

---

  * The old build system is Xcode 3; the new build system is 'make'; we will move to ZFSonLinux's 'autoconf'.
  * [PackageMaker](https://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/PackageMakerUserGuide/Introduction/Introduction.html) on Mac OS 10.6

**Update:**  Since early 2014 installer packages of O3X, MacZFS' successor project, are available at [O3X downloads](https://openzfsonosx.org/wiki/Downloads).



---

## References ##

---

  * [Magic in programming](http://en.wikipedia.org/wiki/Magic_(programming))
  * [Orientation to ZFS architecture](http://youtu.be/NRoUC9P1PmA) Jeff Bonwick and Bill Moore presenting at the SNIA Software Developers' Conference, Sept 2008, on "ZFS: The Last Word in File Systems".
  * [Porting the ZFS ﬁle system to the FreeBSD operating system](http://2007.asiabsdcon.org/papers/P16-paper.pdf)