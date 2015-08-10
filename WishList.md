# Wish List for MacZFS #



This document is a dumping ground for ideas, both big and small, both fantastical and easy.  Please convert them into issue tickets or chapters in a wiki document, where appropriate.

  * Create a project engineering roadmap and project plan, enumerating the known and unknown issues, challenges, and dilemmas.
  * Are the kernel performance parameters optimally tuned for most usage cases?  Since we can't currently tune those at runtime, maybe we can provide alternative binaries for desktops or for servers.  Modify the Installer script to allow checkboxes for desktop, server, low RAM, big RAM, etc.
  * New release
    * Are we distributing the CDDL and a notice thereof?
    * Are all of our files covered under CDDL?
    * New man pages.
    * zpool\_ashift binary.
    * Boot scripts.  Appropriately attributed/copywrited.
  * Create an automated method of hosting Time Machine backups on ZFS (non-HFS+)
  * Note how to enable Spotlight and [AppleDouble](http://netatalk.sourceforge.net/3.0/htmldocs/upgrade.html#id4282732) support of Netatalk volumes
  * Utilize github as a search engine.  Create a stub project on github.org which redirects people to maczfs.org and Google Code.  Possibly update the github repository in tandem, but don't do direct work there.
  * Web site relaunch as maczfs.org
    * Create a more official and approachable face for new users, casual readers, and the press
    * Package up MacZFS as a real finished product
    * Basic promotion in various existing ZFS communities and projects, and with relevant existing articles, and with journalists.  Proactively solicit and educate journalists.
    * Language translations of wiki and stuff
    * Index of MacZFS-related web sites and articles
    * Statistics on web traffic, Google Analytics, and Git repository
    * Profiles of successful hardware deployment -- where is MacZFS being deployed?
    * Solicit storage products for review with MacZFS and ZEVO
  * Package MacZFS for MacPorts, Homebrew, Gentoo, and Fink
  * Cross-promote and recruit with other storage-related and ZFS-related projects -- ZFSonLinux, zfs-fuse, osxfuse, Netatalk, Samba
  * Port [zfsguru web GUI](http://zfsguru.com/download) to Mac OS
  * Make an installation demo and training video
  * Create a maximal ZFS-based Mac OS system
    * Boot with HFS+ only containing /System and /Library, and the rest on ZFS
    * Upon boot, use 'tmutil' to do Time Machine backup of the OS to an HFS+ sparsebundle on ZFS, and do snapshot
    * Create a package to modify the Mac OS Installer to contain ZFS.  Have a menu item to be able to restore a sparsebundle Time Machine image from ZFS.  Menu item to convert the new installation to ZFS.  It can create a zpool or start a Terminal so that you can create your own, then copy everything except the minimal HFS+ boot stub.  See myHack as an example.
  * Join ZFS working group
  * Make a new icon
  * scan Alex Blewitt's weblog for material to convert to the wiki
  * Make a suggested usage profile.  Suggested filesystems to be created, with different compression or other attributes.  For example, one for the iTunes Library (heavy compression, infrequent snapshots), one for iPhoto/Aperture library, one for iPhone backups (more frequent snapshots), one for source code repositories (compression for faster build speed).
  * Scripts for automatic scrub, Time Machine, and rotating snapshots: [Alex's](http://alblue.bandlem.com/2008/11/crontab-generated-zfs-snapshots.html) and [zfSnap](https://github.com/graudeejs/zfSnap/wiki) and [TimeMachine](https://github.com/jollyjinx/ZFS-TimeMachine)
  * Boot scripts
    * Auto-mount all ZFS-hosted DMGs; inside of each zfs, could be a /DMG directory and it could run `hdiutil attach $ZFS/DMG/*`.
    * Have an option to automatically run Time Machine upon each boot.
    * Have a variable to configure whether to disable Spotlight, set to 'true' by default.
    * Use launchd's dependency support to start ZFS ASAP in the boot process, pausing other things (at least user log login) until it completes.
  * Case insensitivity?  http://www.brain-dump.org/projects/ciopfs/
  * Find a way to recruit new developers, promoting a roadmap, and possibly via cheap outsourcing of sponsored features http://fossfactory.org/
  * Get corporate sponsors, even if just for small token gifts like tshirts or USB flash drives
  * Hold a contest to deploy a loosely relevant app in the App Stores, even if it's a game of "swat the bad blocks", in order to drive traffic to MacZFS.org.  ADC account will be sponsored by dtm.
  * Bug-filing and petition-signing campaign toward Apple (ADC accounts, [public bug reports](https://bugreport.apple.com/), and public feature requests), to remove all needless prejudice toward HFS+, and to remove roadblocks against non-HFS+.
    * Support in the bootloader (contact Chameleon)
    * Case sensitivity in apps and data (FCP X app, Motion clip art)
  * target iOS