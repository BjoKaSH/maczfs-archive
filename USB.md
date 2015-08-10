# Issues with USB Drives #

Before using USB drives with ZFS, please note the following potential issues:

## Sync issues ##

USB drives may often lie about committing code with an `fsync` and claim that the data has hit the disk before it actually has. This can cause ZFS' always valid on disk guarantees to become invalidated.

For example, when writing out the root metadata, ZFS writes first to the front of the disk, then the back, then the front (different slot) and back (different slot). ZFS assumes that these writes hit the disk in the order written, such that upon reboot, if the order is inconsistent then it can be deduced which order they are written. (These vdev labels are described in the [ZFS On Disk Format](http://maczfs.googlecode.com/files/ZFSOnDiskFormat.pdf).)

With MacZFS 74, there is only a single pointer to the on-disk tree. Subsequent versions of MacZFS will support multiple pointers to previous versions to reduce the likelihood of failure in the case that part of the tree gets corrupted.

In any case, if the USB lies about writing data, and coalesces the front label update before the back labels are updated, then the on-disk format can be thrown out of sync. This can render a pool unusable in the most extreme case.

## Ejecting whilst mounted ##

ZFS will panic when a device it is speaking to goes bad; or more specifically, when the number of devices drops below the minimum threshold. In a mirrored pair, you can lose one device; in a raidz2 you can lose two devices, and so on. However, if you have a raidz consisting of multiple partitions on a single USB device then it's generally an all-or-nothing affair.

Pulling a USB disk will therefore trigger this scenario. (You get the same sort of issue with HFS+ or NTFS drives; OSX will throw up a warning saying 'unsafe ejection'.) It makes sense to eject rather than yank in these cases.

Subsequent versions of MacZFS (from MacZFS77) will permit a mode whereby this causes the pool to be marked as invalid but without a full panic occurring.

See also: [Issue 3](http://code.google.com/p/maczfs/issues/detail?id=3)

## Flaky hardware and power ##

Lastly, note that not all USB drives are made equal. If there are power fluctuations on USB then this can cause the USB drive to momentarily disconnect and reconnect.

In addition, some USB drives may spin down after a period of time and return an error until they've spun up again, which triggers this failure scenario. This issue can be somewhat mitigated by disabling the "Put the disks to sleep where possible" in the Energy Saver of System Preferences, or by running `sudo pmset -a disksleep 0` from the command line.

## Competition for scarce resources ##

The USB drive needs to be performant and give data upon request. However, if the drive is busy, powered down, or being used by other applications heavily the device returns errors. Any errors from a device under Zpool management automatically get marked as failed; and if this failure brings the data copies to below the required amount will result in a kernel panic.

## Reporting issues ##

Please don't report issues regarding panics for USB based devices.