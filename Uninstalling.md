# Get rid of any pools/data #

You'll obviously need to move your data to a different file system. That is left as an exercise for the reader.

Once you've not got any more data left on your file system, then you'll need to do:

```
zpool list
# for each pool
zpool export -f pool
```

Once you have done this, a zpool list should show no more pools. You should then remove the partitions/disks using Disk Utility to ensure that there's no partition with a ZFS label.

# Reboot and remove #

At this point, rebooting might be a good idea. If you have no ZFS pools upon reboot then the extensions shouldn't be loaded. It might not be necessary to do this at this point, but it might not hurt.

## Removing files ##

ZFS is installed in the following files/locations:

  * /System/Library/Filesystems/zfs.fs
  * /System/Library/Extensions/zfs.kext
  * /System/Library/Extensions/zfs.readonly.kext (this is present on 10.5 systems only and is for read-only support)
  * /usr/sbin/zfs
  * /usr/sbin/zpool
  * /usr/sbin/zoink
  * /usr/sbin/zfs.util
  * /usr/lib/libzfs.dylib
  * /usr/share/man8/zfs.8
  * /usr/share/man8/zfs.util.8
  * /usr/share/man8/zpool.8

Once you've removed all these files, you can reboot and you should have no traces of ZFS on your system.