# What is ZFS? #

_Note the below description is taken directly from the ZFS Open Solaris site  What is ZFS page_

ZFS is a new kind of filesystem that provides simple administration, transactional semantics, end-to-end data integrity, and immense scalability. ZFS is not an incremental improvement to existing technology; it is a fundamentally new approach to data management. We've blown away 20 years of obsolete assumptions, eliminated complexity at the source, and created a storage system that's actually a pleasure to use.
ZFS presents a pooled storage model that completely eliminates the concept of volumes and the associated problems of partitions, provisioning, wasted bandwidth and stranded storage. Thousands of filesystems can draw from a common storage pool, each one consuming only as much space as it actually needs. The combined I/O bandwidth of all devices in the pool is available to all filesystems at all times.
All operations are copy-on-write transactions, so the on-disk state is always valid. There is no need to fsck(1M) a ZFS filesystem, ever. Every block is checksummed to prevent silent data corruption, and the data is self-healing in replicated (mirrored or RAID) configurations. If one copy is damaged, ZFS will detect it and use another copy to repair it.

ZFS introduces a new data replication model called RAID-Z. It is similar to RAID-5 but uses variable stripe width to eliminate the RAID-5 write hole (stripe corruption due to loss of power between data and parity updates). All RAID-Z writes are full-stripe writes. There's no read-modify-write tax, no write hole, and — the best part — no need for NVRAM in hardware. ZFS loves cheap disks.

But cheap disks can fail, so ZFS provides disk scrubbing. Like ECC memory scrubbing, the idea is to read all data to detect latent errors while they're still correctable. A scrub traverses the entire storage pool to read every copy of every block, validate it against its 256-bit checksum, and repair it if necessary. All this happens while the storage pool is live and in use.

ZFS has a pipelined I/O engine, similar in concept to CPU pipelines. The pipeline operates on I/O dependency graphs and provides scoreboarding, priority, deadline scheduling, out-of-order issue and I/O aggregation. I/O loads that bring other filesystems to their knees are handled with ease by the ZFS I/O pipeline.

ZFS provides unlimited constant-time snapshots and clones. A snapshot is a read-only point-in-time copy of a filesystem, while a clone is a writable copy of a snapshot. Clones provide an extremely space-efficient way to store many copies of mostly-shared data such as workspaces, software installations, and diskless clients.
ZFS backup and restore are powered by snapshots. Any snapshot can generate a full backup, and any pair of snapshots can generate an incremental backup. Incremental backups are so efficient that they can be used for remote replication — e.g. to transmit an incremental update every 10 seconds.

There are no arbitrary limits in ZFS. You can have as many files as you want; full 64-bit file offsets; unlimited links, directory entries, snapshots, and so on.

ZFS provides built-in compression. In addition to reducing space usage by 2-3x, compression also reduces the amount of I/O by 2-3x. For this reason, enabling compression actually makes some workloads go faster.
In addition to filesystems, ZFS storage pools can provide volumes for applications that need raw-device semantics. ZFS volumes can be used as swap devices, for example. And if you enable compression on a swap volume, you now have compressed virtual memory.

ZFS administration is both simple and powerful. Please see the zpool(1M) and zfs(1M) man pages for more information — and be sure to check out the Getting Started section for a whirlwind tour.

ZFS is already quite snappy on most workloads — and we're just getting started.