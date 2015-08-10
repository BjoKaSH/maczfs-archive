## Quick Links: [What is ZFS?](http://code.google.com/p/maczfs/wiki/WhatIsZFS) | [FAQ](http://code.google.com/p/maczfs/wiki/FAQ) | [Getting Started Guide](http://code.google.com/p/maczfs/wiki/GettingStarted) | [Mailing List](https://groups.google.com/forum/?fromgroups#!forum/zfs-macos) | [IRC](http://code.google.com/p/maczfs/wiki/MacZFSIRCChannel) | [Downloads](http://code.google.com/p/maczfs/wiki/Downloads) ##


---

**Note:** Development of MacZFS ceased in mid 2013.  Please switch to [O3X](https://openzfsonosx.org/)

---



MacZFS is free data storage and protection software for [all Mac OS users](http://code.google.com/p/maczfs/wiki/FAQ#Who_is_MacZFS_intended_for?__Is_it_easy_to_set_up?__Is_it_Mac-li).  It's for people who have Mac OS, who have any data, and who really **like** their data.  Whether on a single-drive laptop or on a massive server, it'll store your petabytes with ragingly redundant RAID reliability, and it'll keep the bit-rotted bleeps and bloops out of your iTunes library.

The completely [free](http://www.gnu.org/licenses/license-list.html) MacZFS 74 provides absolutely all functionality, speed, and data integrity guarantee which are needed for personal and small enterprise use.  We believe it to be one of the most advanced storage solutions for most Mac OS users, at any price.

[Read some commentary](http://alblue.bandlem.com/2011/03/status-of-maczfs-on-osx.html) by one of MacZFS's primary engineers, Alex Blewitt.

Assuming that you're not terrified of Terminal, it's about as easy or complicated [as you make it](http://code.google.com/p/maczfs/wiki/GettingStarted).

# Current Status #

Supported systems: PowerPC and Intel, 32-bit and 64-bit, Mac OS 10.5/10.6/10.7/10.8/10.9, or [PureDarwin](http://puredarwin.org/) ([pure](http://www.puredarwin.org/developers/macports/purity)).  [Get it!](http://code.google.com/p/maczfs/wiki/GettingStarted)

**Stable:** The stable generation of MacZFS consists of a stable release based on `onnv_74` which provides zpool version 8 and zfs version 2, and development releases based on `onnv_75` and `onnv_77`.  This code was synched from an upstream release of 2008, and is a highly venerable, stable, widely tested, and mature product.  It originates from a timeframe where ZFS was already almost ten years mature, and was already several years beyond virtually any other storage platform.

**Development:** The prototype generation of MacZFS is synchronizing from the latest ZFSonLinux code, and is establishing a broader compatibility layer.  See the [Developer Overview](DevelopmentOverview.md) to get involved, including the locations of the various repositories and release protocol.  **Now recruiting** all contributors, big and small: kernel engineers, hobbyist hackers, and testers for the all-new next generation of MacZFS.  Please introduce yourself on the [Mailing List](https://groups.google.com/forum/?fromgroups=#!forum/maczfs-devel) or on [IRC](http://code.google.com/p/maczfs/wiki/MacZFSIRCChannel) (#mac-zfs on irc.freenode.net).

## Future of MacZFS ##

The development of good old MacZFS ceased in mid 2013 for a number of technical and organizational reasons.  Development of ZFS on OS X shifted to a new and more modern code base and continues in the _OpenZFS on OS X_ (or [O3X](https://openzfsonosx.org/) for short) project.  O3X is part of the cross-platform [OpenZFS](http://open-zfs.org/wiki/Main_Page) organization and combines all the features known from ZFS on other platforms with the solid Solaris-to-Darwin porting layer taken from the old MacZFS.

If you need ZFS on OS X and have a modern (10.7 or newer) OS X, then please upgrade to the latest stable release of O3X, see [O3X downloads](https://openzfsonosx.org/wiki/Downloads).

# License #

The original ZFS software is licensed by Oracle under the [free software copyleft license](http://www.gnu.org/licenses/license-list.html) called the [CDDL](http://en.wikipedia.org/wiki/Common_Development_and_Distribution_License).  Solaris is the property of Oracle.  "Macintosh" and "Mac OS X" are registered trademarks of Apple, Inc.  Portions of MacZFS are copyright by various individuals.