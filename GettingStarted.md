# Getting Started #


---

**Note:** Development of MacZFS ceased in mid 2013. Please switch to [O3X](https://openzfsonosx.org/)

---


## For Developers ##

  * [Developer Overview](http://code.google.com/p/maczfs/wiki/DevelopmentOverview)
  * Developers and serious users should see the [rest of the wiki](http://code.google.com/p/maczfs/w/list).

## Prerequisites ##

  * Decide your storage strategy.  Decide whether you need to back up your data, because this entire procedure is inherently destructive.  ZFS is not HFS+; and, HFS+ cannot be literally, directly converted into ZFS.  However, HFS+ can be destroyed or shrunk, and ZFS can be created in its place.  An existing drive's HFS+ can be nondestructively shrunk, in order to create a new blank partition suitable for ZFS.  Or a blank drive or partition can have ZFS added to it.
  * [Acquire the latest stable copy of MacZFS](http://code.google.com/p/maczfs/downloads/list) and Mac OS 10.5 or higher.  That's all you need in order to start, and you can uninstall MacZFS without a trace at any time.
  * [Read this about 4k drives.](http://code.google.com/p/maczfs/wiki/FAQ#What_should_I_do_with_4k_(Advanced_Format)_hard_drives?)  Developers may go on to the [Development Overview](http://code.google.com/p/maczfs/wiki/DevelopmentOverview).
  * [Be aware of issues inherent in USB](http://code.google.com/p/maczfs/wiki/USB) and avoid it wherever possible, or be careful.

## ZFS Orientation ##

If you want to know what you're doing, and develop a storage strategy before starting, here are the best starting points.  Please feel free to dive in anyway, and you can always just experiment with creating zpools on sparse files created with 'mkfile -n' instead of with whole hard drives.  Try to read some of these pages before involving support channels.

  * [MacZFS Frequently Asked Questions file](http://code.google.com/p/maczfs/wiki/FAQ), which includes what MacZFS can and can't do.
  * [Known issues](http://code.google.com/p/maczfs/wiki/KnownIssues) with MacZFS.
  * [Explanation of ZFS's RAID levels](http://www.zfsbuild.com/2010/05/26/zfs-raid-levels/).  The only difference is that MacZFS doesn't have RAIDZ3 yet.
  * [ZFS Basic Administration Guide](http://unixfoo.blogspot.com/2009/02/zfs-basic-administration-guide.html) with a video of a Sun engineer trying to physically destroy ZFS with a sledgehammer.
  * [ZFS Solaris Administration Guide](http://docs.huihoo.com/opensolaris/solaris-zfs-administration-guide/html/index.html), where most things apply to MacZFS.
  * [ZFS Best Practices Guide](http://www.solarisinternals.com/wiki/index.php/ZFS_Best_Practices_Guide), for greater and more technical orientation needs of all ZFS users.

The underlying storage used by ZFS filesystems involves pools. A pool may consist of one or more whole disks or disk partitions. Basically, these whole disks and/or disk partitions can be combined in several different ways: dynamic striping, mirroring, or RAIDZ.

In all cases, MacZFS functions optimally (automatically and most safely mounting and unmounting) with a GUID Partition Table (GPT).  ZFS typically works best when it owns the entire disk due in part to how conservative it is with the write cache.

## Create a Simple 1 Disk Pool ##

In the most simple example, let's start by using a single drive for our "puddle" storage pool. In the following example the commands are issued as root.

First, find out which device node to use with a "diskutil list" command. In the example below, I'm going to work with /dev/disk2 which currently has an APM (Apple Partition Map) label and an exsiting HFS filesystem. I'm going to replace the APM label with a GPT one and blow away the HFS "FW" filesystem. You should unmount any mounted filesystems on the target drive at this point.

```
# diskutil list 
. 
. 
. 
/dev/disk2 
   #:                   type name                size     identifier 
   0: Apple_partition_scheme                    *9.4 GB   disk2 
   1:    Apple_partition_map                     31.5 KB  disk2s1 
   2:              Apple_HFS FW                  9.2 GB   disk2s3 
```

Now I'm going to place a GPT label on that disk: **Note this step is very important! You must format the partition before you create a ZFS pool on it**

```
# diskutil partitiondisk /dev/disk2 GPTFormat ZFS %noformat% 100% 
Started partitioning on disk disk2 
Creating partition map 
[ + 0%..10%..20%..30%..40%..50%..60%..70%..80%..90%..100% ]  
Finished partitioning on disk disk2 
/dev/disk2 
   #:                   type name                size     identifier 
   0:  GUID_partition_scheme                    *9.4 GB   disk2 
   1:                    EFI                     200.0 MB disk2s1 
   2:                    ZFS                     9.0 GB   disk2s2 
```

And create our simple ZFS pool (named "puddle"):

```
# zpool create puddle /dev/disk2s2 
```

And then check my work, noting that my new ZFS filesystem is available at /Volumes/puddle:

```
# zpool status puddle 
  pool: puddle 
 state: ONLINE 
 scrub: none requested 
config: 
 
        NAME        STATE     READ WRITE CKSUM 
        puddle      ONLINE       0     0     0 
          disk2s2   ONLINE       0     0     0 
 
errors: No known data errors 
 
# df -hl /Volumes/puddle 
Filesystem   Size   Used Available Capacity  Mounted on 
puddle     8.9Gi  19Ki 8.9Gi     1%    /Volumes/puddle 
```

## Creating a Mirror or RAIDZ ##

To create a mirror or a RAIDZ, take a look at the following example where "tank" (a mirrored pair) and "dozer" (a RAIDZ set) are the names of our pools.

```
# zpool create tank mirror disk2s2 disk3s2 
# zpool status tank 
  pool: tank 
 state: ONLINE 
 scrub: none requested 
config: 
 
        NAME                STATE     READ WRITE CKSUM 
        tank                ONLINE       0     0     0 
          mirror            ONLINE       0     0     0 
            disk2s2         ONLINE       0     0     0 
            disk3s2         ONLINE       0     0     0 
 
errors: No known data errors 
 
 
# zpool create dozer raidz disk4s2 disk5s2 disk6s2 
# zpool status dozer 
  pool: dozer 
 state: ONLINE 
 scrub: none requested 
config: 
 
        NAME                STATE     READ WRITE CKSUM 
        dozer               ONLINE       0     0     0 
          raidz1            ONLINE       0     0     0 
            disk4s2         ONLINE       0     0     0 
            disk5s2         ONLINE       0     0     0 
            disk6s2         ONLINE       0     0     0 
 
errors: No known data errors 
```

## Add Storage to a Pool ##

To add more storage to an existing pool, like "tank" from the example above, take a look at the following example.

```
# zpool add tank mirror disk7s2 disk8s2 
# zpool status tank 
  pool: tank 
 state: ONLINE 
 scrub: none requested 
config: 
 
        NAME                STATE     READ WRITE CKSUM 
        tank                ONLINE       0     0     0 
          mirror            ONLINE       0     0     0 
            disk2s2         ONLINE       0     0     0 
            disk3s2         ONLINE       0     0     0 
          mirror            ONLINE       0     0     0 
            disk7s2         ONLINE       0     0     0 
            disk8s2         ONLINE       0     0     0 
 
errors: No known data errors 
```

## Using an Existing Partition ##

If you have existing partitions you want to use, so long as the partition map on that drive is GPT and you've unmounted them and understand that pre-existing data on those partitions will be lost, you can use the "diskutil" command to change the label type in place. In the example below, I want to use the pre-existing HFS "blank" and Untitled 2" partitions for my "oddcouple" ZFS mirrored pool. Again, please note that with this example, any previous data on the HFS "blank" and "Untitled 2" partitions will (obviously) be overwritten! Note the Apple\_HFS partition type for the "blank" and "Untitled 2" partitions:

```
# diskutil list 
/dev/disk0 
   #:                   type name                size     identifier 
   0:  GUID_partition_scheme                    *149.1 GB disk0 
   1:                    EFI                     200.0 MB disk0s1 
   2:              Apple_HFS Leopard             29.7 GB  disk0s2 
   3:              Apple_HFS Leopard9A376        29.7 GB  disk0s3 
   4:                    ZFS zfstest             29.7 GB  disk0s4 
   5:              Apple_HFS blank               29.7 GB  disk0s5 
   6:              Apple_HFS HFSJ_Boot           29.5 GB  disk0s6 
/dev/disk1 
   #:                   type name                size     identifier 
   0:  GUID_partition_scheme                    *153.4 GB disk1 
   1:                    EFI                     200.0 MB disk1s1 
   2:              Apple_HFS Untitled 1          30.7 GB  disk1s2 
   3:              Apple_HFS Untitled 2          30.7 GB  disk1s3 
   4:              Apple_HFS Leopard9A376        30.7 GB  disk1s4 
   5:              Apple_HFS LaCieLeopard        30.7 GB  disk1s5 
   6:              Apple_HFS Leopard9A377a       29.9 GB  disk1s6 
```

Change the partition type to ZFS and check your work:

```
# diskutil eraseVolume ZFS %noformat% /dev/disk0s5 
[ + 0%..10%..20%..30%..40%..50%..60%..70%..80%..90%..100% ]  
Finished erase on disk disk0s5 
 
# diskutil eraseVolume ZFS %noformat% /dev/disk1s3 
[ + 0%..10%..20%..30%..40%..50%..60%..70%..80%..90%..100% ]  
Finished erase on disk disk1s3 
 
# diskutil list 
/dev/disk0 
   #:                   type name                size     identifier 
   0:  GUID_partition_scheme                    *149.1 GB disk0 
   1:                    EFI                     200.0 MB disk0s1 
   2:              Apple_HFS Leopard             29.7 GB  disk0s2 
   3:              Apple_HFS Leopard9A376        29.7 GB  disk0s3 
   4:                    ZFS zfstest             29.7 GB  disk0s4 
   5:                    ZFS                     29.7 GB  disk0s5 
   6:              Apple_HFS HFSJ_Boot           29.5 GB  disk0s6 
/dev/disk1 
   #:                   type name                size     identifier 
   0:  GUID_partition_scheme                    *153.4 GB disk1 
   1:                    EFI                     200.0 MB disk1s1 
   2:              Apple_HFS Untitled 1          30.7 GB  disk1s2 
   3:                    ZFS                     30.7 GB  disk1s3 
   4:              Apple_HFS Leopard9A376        30.7 GB  disk1s4 
   5:              Apple_HFS LaCieLeopard        30.7 GB  disk1s5 
   6:              Apple_HFS Leopard9A377a       29.9 GB  disk1s6 
```

Now create the "oddcouple" pool and check your work:

```
# zpool create oddcouple mirror disk0s5 disk1s3 
 
# zpool status oddcouple 
  pool: oddcouple 
 state: ONLINE 
 scrub: none requested 
config: 
 
        NAME         STATE     READ WRITE CKSUM 
        oddcouple    ONLINE       0     0     0 
          mirror     ONLINE       0     0     0 
            disk0s5  ONLINE       0     0     0 
            disk1s3  ONLINE       0     0     0 
 
errors: No known data errors 
```

# Other Notes #

## Manual startup and shutdown ##

If you created a zpool using any method not explicitly listed above, such as ...
  * a zpool, of a compatible version, which had been created using an OS other than Mac OS
  * loopback files, as with `mkfile 1g file0 ; zpool create filepool /Users/user/file0`
  * an MBR or APM or any other partition type
  * not using Mac OS's ZFS partition type
... then this is not a supported configuration, although it **should** work.  You are encouraged to report your findings to the mailing list.  Furthermore, you'll probably want to automate your startup and shutdown procedure as much as possible, as [described here](http://code.google.com/p/maczfs/wiki/FAQ#Will_my_ZFS_volumes_automatically_appear_upon_boot_and_then_prop).

## Spotlight ##

See the FAQ: [Does MacZFS work with Spotlight?](http://code.google.com/p/maczfs/wiki/FAQ#Does_MacZFS_work_with_Spotlight?)

Unless you know exactly what you're doing, you should permanently disable Spotlight on all ZFS filesystems which are listed with `mdutil -vas`.  For example: `mdutil -i off /Volumes/mypool`.

## Problems ##

If you have any other problems, be sure that you used a partition like `/dev/disk0s2` and not the whole drive like `/dev/disk0`, or else you'd need to install the manual startup scripts.  Always `zfs umount` and `zpool export` a volume before attempting to unplug it, and never hotswap with [USB](USB.md) anyway lest you risk a kernel panic.  If you can't freely access your files, ensure that you own them with `chown` and `chmod` or with `Get Info` in Finder, because by default, ZFS's files are owned by the user who ran the ZFS setup commands.  And [read the FAQ](FAQ.md)!