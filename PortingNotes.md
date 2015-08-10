
---


---

# Table of Contents #

---


---



  * [Introduction](http://code.google.com/p/maczfs/wiki/PortingNotes#Introduction)
  * [vnode\_t](http://code.google.com/p/maczfs/wiki/PortingNotes#vnode_t)
  * [ZFS\_IOC\_ not defined](http://code.google.com/p/maczfs/wiki/PortingNotes#ZFS_IOC__not_defined)
  * [IO\_APPEND vs FAPPEND](http://code.google.com/p/maczfs/wiki/PortingNotes#IO_APPEND_vs_FAPPEND)
  * [VFS Flags](http://code.google.com/p/maczfs/wiki/PortingNotes#VFS_Flags)
  * [IOCTL Introduction](http://code.google.com/p/maczfs/wiki/PortingNotes#IOCTL_Introduction)
  * [IOCTL Kernelspace](http://code.google.com/p/maczfs/wiki/PortingNotes#IOCTL_Kernelspace)
  * [IOCTL Summary](http://code.google.com/p/maczfs/wiki/PortingNotes#IOCTL_Summary)
  * [Porting to FUSE](http://code.google.com/p/maczfs/wiki/PortingNotes#Porting_to_FUSE)


---


---

# Introduction #

---


---


There are a number of differences between OSX and OpenSolaris that make porting more of a challenge than in other environments (including FreeBSD).


---


---

# vnode\_t #

---


---


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


---


---

# `ZFS_IOC_` not defined #

---


---


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


---


---

# `IO_APPEND` vs `FAPPEND` #

---


---


Mac OS X uses IO\_APPEND in the kernel to denote appending, instead of FAPPEND. So various `#ifdef` are set up to call with the same parameters but a switch of flag name.


---


---

# VFS Flags #

---


---


Instead of using bitwise flags (like `z_vfs->vfs_flag & VFS_RDONLY`) OSX uses functions in `mount.h` to achieve the same thing.

  * `z_vfs->vfs_flag & VFS_RDONLY` is replaced with `vfs_isrdonly(z_vfs)`
  * `z_vfs->vfs_flag &= ~VFS_RDONLY` is replaced with `vfs_clearflags(z_vfs, MNT_RDONLY` (t steflags, where appropriate)


---


---

# IOCTL Introduction #

---


---


This is a discussion of how the user-land commands interact with the kernel-land commands.

Most of the ZFS user level commands (zfs, zpool) are merely wrappers around instruction that get handed over to the kernel. These are executed with an `ioctl` call, which passes a number/argument to the appropriate routine in the kernel itself.

For example the [zfs\_iter\_filesystems](https://github.com/alblue/mac-zfs/blob/master/usr/src/lib/libzfs/common/libzfs_dataset.c#L2555) call invokes an `ioctl` with an argument `ZFS_IOC_DATASET_LIST_NEXT`. This corresponds to the macro [ZFS\_IOC\_CMD(18)](https://github.com/alblue/mac-zfs/blob/master/usr/src/uts/common/sys/fs/zfs.h#L459), which ultimately ends up as `ioctl('Z',18,struct zfs_cmd)`.

In fact, `ioctl` is `#defined` to `app_ioctl` (defined in  [libzfs\_util.c](https://github.com/alblue/mac-zfs/blob/master/usr/src/lib/libzfs/common/libzfs_util.c#L1065) and mapped in [libzfs\_ioctl.h](https://github.com/alblue/mac-zfs/blob/master/usr/src/lib/libzfs/common/libzfs_ioctl.h)) so that the error number is appropriately copied across.


---


---

# IOCTL Kernelspace #

---


---


The kernel receives the `ioctl` in the [zfsdev\_ioctl()](https://github.com/alblue/mac-zfs/blob/master/usr/src/uts/common/fs/zfs/zfs_ioctl.c#L2331) call, which in turn looks up (based on index) the value in the [zfs\_ioc\_vec](https://github.com/alblue/mac-zfs/blob/master/usr/src/uts/common/fs/zfs/zfs_ioctl.c#L2277) array, which essentially is a list of function pointers, like [zfs\_ioc\_dataset\_list\_next()](https://github.com/alblue/mac-zfs/blob/master/usr/src/uts/common/fs/zfs/zfs_ioctl.c#L1154).

Ultimately, this function from the table gets invoked by invoking the [zvec\_func](https://github.com/alblue/mac-zfs/blob/master/usr/src/uts/common/fs/zfs/zfs_ioctl.c#L2393) call, which has been bound to the function pointer from the lookup table.


---


---

# IOCTL Summary #

---


---


  * Client invokes an `ioctl(ZFS_IOC_DATASET_LIST_NEXT)`, which is essentially `ioctl('Z',18,&zc)`
  * Gets mapped via the `app_ioctl()` macro to support re-acquisition of error number
  * Kernel receives `zfsdev_ioctl(, 18, &zc)`
  * Kernel looks up `zfs_ioc_vec[18]` to get function pointer `zfs_ioc_dataset_list_next`
  * Kernel invokes `zvec_func` which is the same as the acquired function pointer `zfs_ioc_dataset_list_next` in this case
  * Kernel steps into the `zfs_ios_dataset_list_next()` function

Ultimately, the client's invocation of an `ioctl` ZFS\_IOC\_FOO\_BAR` will translate to a call `zfs\_ioc\_foo\_bar()` in the `[https://github.com/alblue/mac-
zfs/blob/master/usr/src/uts/common/fs/zfs/zfs\_ioctl.c zfs\_ioctl.c] file


---


---

# Porting to FUSE #

---


---


No work has been done to port MacZFS to FUSE, but here are some observations.

http://fuse4x.github.com/
http://osxfuse.github.com/

**First:**
The first observation is, that ztest has most of ZFS internals readily
running in user space: The SPA, the DMU, and the DSL.  Only the ZPL
(ZFS Posix Layer) is missing.

(DMU = Data Management Unit: The object based transactional database
> in ZFS that backs ZFS datasets.

> DSL = Dataset and Snapshot Layer: The part which organizes the
> (pool wide) objects provided by the DMU into hierarchical layered sets
> of related objects.)

**Second:**
The second observation is, that SPA, DMU and DSL are more like 90%+
than 75% of ZFS.  The ZPL is a rather simple layer sitting on top of
the DSL / DMU.

**Third:**
The third observation is that the ZPL, beside being rather small, is a
major source of headache in any ZFS port, and specifically for the OSX
port due to many specialties in the OSX VFS layer.  (You can find a
lot about these difficulties when you look at documentation for
MacFUSE -- they had the same troubles then everyone has who tries to
write a file system for MacOSX.)

**Fourth:**
The fourth observation was, that FUSE is exactly made to significantly
simplify writing POSIX layers, or more precisely, FUSE /is/ a POSIX
file system layer, equipped with a nice and simple interface to the
storage back-end.

These four observations almost immediately led to the idea "Why not let
MacFUSE have the headache with the POSIX and VFS layers, and instead
enjoy a simple and nice interface to DMU / DSL?"

Of course, it is **not** that simple in reality.  The ZPL is more than
just a simple translator between the VFS of any kernel and the DMU /
DSL.  All these tricky things like file permissions, ACLs or even
basic stuff like directories are handled at the ZPL and ultimately
stored as data objects in the DMU / DSL layer.  We still would need
all the complexity of decoding / encoding permissions, looking up
files and directories in their respective parent directories and a
lot more.  But the hop is, we can throw away most of the mount /
umount stuff and a lot of glue code connecting a more-or-less Solaris
like ZPL to the MacOSX VFS layer.  And of course, we would work in
user space, allowing us to use all the nice development and debugging
tools available for application software development.

That is pretty much how far I got.  I did a few check on where to
start, and more or less decided to **not** start directly with FUSE, but
instead add a "file browser mode" to ztest, much like the browse mode
found in smbclient (or in any terminal based FTP client).
> -- Bjoern