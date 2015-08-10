# Known Issues #


  * **USB**
    * http://code.google.com/p/maczfs/wiki/USB
  * **Mac OS 10.8**
    * Reports are still inconclusive!  You must [install it manually.](http://code.google.com/p/maczfs/wiki/FAQ#How_do_I_install_MacZFS_manually?)
  * **Mac OS 10.7**
    * The mailing list has heard of no reports of data loss of course, but there have been various cosmetic anomalies with MacZFS on Mac OS 10.7.  We know there are lots of deployments.  Please contribute!
    * Any new filesystems that you create, in addition to every zpool's default root filesystem, will still show up in Finder as being additional instances of the zpool's own name.  This is a purely cosmetic bug and can be ignored.  You can create as many ZFSes as you want on each zpool, and name them whatever you want, and use them however you want.  They'll just appear as a bunch of redundantly-named icons on the Finder sidebar.
    * ZFS filesystems are mounted in weird places.  On some systems, you may need to issue a 'zfs set mountpoint' explicitly.

  * **zpool cannot complete a 'replace' operation.**
A raidz will sometimes not replace a vdev that was previously pulled during replacement, instead leaving 2 devices in 'replacing' status, and the pool in a degraded state.
Example:
```
$ zpool status big 
  pool: big 
 state: DEGRADED 
 scrub: resilver completed with 0 errors on Sun Mar 13 01:46:16 2011 
config: 
        NAME                        STATE     READ WRITE CKSUM 
        big                         DEGRADED     0     0     0 
          raidz2                    DEGRADED     0     0     0 
            replacing               DEGRADED     0     0 6.30K 
              disk1                 ONLINE       0     0     0 
              11821611813174021595  FAULTED      0     0     0  was /dev/disk3 
            disk8                   ONLINE       0     0     0 
            disk4                   ONLINE       0     0     0

...
```
**Workaround:** `zpool detach <pool> <missing device id>`

This is an upstream ZFS bug which will disappear upon the eventual porting of newer code. http://bugs.opensolaris.org/bugdatabase/view_bug.do?bug_id=6782540

  * **Spotlight doesn't really work with ZFS.**
[Not really.](http://groups.google.com/group/zfs-macos/browse_thread/thread/dfcda6a9b71b0dac)

  * **Integrating ZFS more into the Finder.**
[Read this.](http://groups.google.com/group/zfs-macos/browse_thread/thread/d6add98139df1df5)

  * **Does this affect MacOS? [The ARC allocates memory inside the kernel cage, preventing DR](http://bugs.opensolaris.org/bugdatabase/view_bug.do?bug_id=6522017)**

  * **Snapshots can't be viewed with '.zfs/snapshot'**
[Ticket #5](http://code.google.com/p/maczfs/issues/detail?id=5)

**Workaround:** Clone your snapshots, and view them all that way.

  * Finder is slow
    * Finder does a lot of lookups on the filesystem to get metadata like icons, size etc. There's a fast call 'searchfs' which Finder will normally use; however, this isn't implemented in MacZFS, so it falls back to acquiring the contents of each of the files to give the information (especially the preview icon). There may be some problems with it caching this data because the longer a system has been running, the longer Finder takes.