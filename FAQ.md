
---


---

# Frequently Asked Questions about MacZFS #

---


---

# Table of Contents #


---

**Note:** Development of MacZFS ceased in mid 2013. Please switch to [O3X](https://openzfsonosx.org/)

---


  * [Where do I get MacZFS and how do I install it?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Where_do_I_get_MacZFS_and_how_do_I_install_it?)
  * [On what systems does MacZFS run?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#On_what_systems_does_MacZFS_run?)
  * [How do I install MacZFS manually?](http://code.google.com/p/maczfs/wiki/FAQ#How_do_I_install_MacZFS_manually?)
  * [How stable is MacZFS?  Can I totally trust it?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#How_stable_is_MacZFS?__Can_I_totally_trust_it?)
  * [I've never had any corruption, so is ZFS really necessary?](http://code.google.com/p/maczfs/wiki/FAQ#I've_never_had_any_corruption,_so_is_ZFS_really_necessary?)
  * [What is the future of MacZFS?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#What_is_the_future_of_MacZFS?)
  * [Does Apple support or interact with MacZFS?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Does_Apple_support_or_interact_with_MacZFS?)
  * [Is there any negative ramification from the fact that Apple doesn't support ZFS?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Is_there_any_negative_ramification_from_the_fact_that_Apple_does)
  * [Who is MacZFS intended for? Is it easy to set up? Is it Mac-like?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Who_is_MacZFS_intended_for?__Is_it_easy_to_set_up?__Is_it_Mac-li)
  * [What quality assurance methods can I use to ensure MacZFS's stability for my needs?](http://code.google.com/p/maczfs/wiki/FAQ#What_quality_assurance_methods_can_I_use_to_ensure_MacZFS's)
  * [Is there a GUI with which to manage MacZFS?](http://code.google.com/p/maczfs/wiki/FAQ#Is_there_a_GUI_with_which_to_manage_MacZFS?)
  * [Can it fill and empty the Trash in the normal Mac way?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Can_it_fill_and_empty_the_Trash_in_the_normal_Mac_way?)
  * [Does it work ok with USB and other external drives?](http://code.google.com/p/maczfs/wiki/FAQ#Does_it_work_ok_with_USB_and_other_external_drives?)
  * [Should I install one of the development versions, one that's not the stable version? The number is higher!](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Should_I_install_one_of_the_development_versions,_one_that')
  * [Well, I did. And I learned my lesson. How do I go back?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#Well,_I_did.__And_I_learned_my_lesson.__How_do_I_go_back?)
  * [What software versions and features does MacZFS support?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#What_software_versions_and_features_does_MacZFS_support?)
  * [How does it compare to the current, free Illumos-based release?](http://code.google.com/p/maczfs/wiki/FAQ#How_does_it_compare_to_the_current,_free_Illumos-based_release?)
  * [How does MacZFS compare to Apple's 10a286 beta release?](http://code.google.com/p/maczfs/wiki/FAQ#How_does_MacZFS_compare_to_Apple's_10a286_beta_release?)
  * [What should I do with 4k (Advanced Format) hard drives?](http://code.google.com/p/maczfs/wiki/FAQ#What_should_I_do_with_4k_(Advanced_Format)_hard_drives?)
  * [What do I do if I absolutely need ZFS features which are more advanced than MacZFS's current implementation, or which are found only on another OS?](http://code.google.com/p/maczfs/wiki/FAQ?ts=1300860697&updated=FAQ#What_do_I_do_if_I_absolutely_need_ZFS_features_which_are_more_ad)
  * [Can I boot from ZFS? Can I convert totally from HFS+ to ZFS?](http://code.google.com/p/maczfs/wiki/FAQ#Can_I_boot_from_ZFS?__Can_I_convert_totally_from_HFS+_to_ZFS?)
  * [Will my ZFS volumes automatically appear upon boot and then properly shut down?](http://code.google.com/p/maczfs/wiki/FAQ#Will_my_ZFS_volumes_automatically_appear_upon_boot_and_then_prop)
  * [Does MacZFS work with Spotlight?](http://code.google.com/p/maczfs/wiki/FAQ#Does_MacZFS_work_with_Spotlight?)
  * [Can I share zpools between other operating systems such as Linux, FreeBSD, or Solaris?](http://code.google.com/p/maczfs/wiki/FAQ#Can_I_share_zpools_between_other_operating_systems_such_as_Linux)
  * [Can I host my Time Machine archives on a ZFS target?](http://code.google.com/p/maczfs/wiki/FAQ#Can_I_host_my_Time_Machine_archives_on_a_ZFS_target?)
  * [Will Time Machine back up from a ZFS source?](http://code.google.com/p/maczfs/wiki/FAQ#Will_Time_Machine_back_up_from_a_ZFS_source?)
  * [Does anyone have MacZFS in commercial production, with their reputations staked on it?](http://code.google.com/p/maczfs/wiki/FAQ#Does_anyone_have_MacZFS_in_commercial_production,_with_their_rep)
  * [Is there any point of using it on a laptop or a system with only one hard drive?](http://code.google.com/p/maczfs/wiki/FAQ#Is_there_any_point_of_using_it_on_a_laptop_or_a_system_with_only)
  * [Does ZFS run on iOS?](http://code.google.com/p/maczfs/wiki/FAQ#Does_ZFS_run_on_iOS?)
  * [How else can I monitor the health of my system?](http://code.google.com/p/maczfs/wiki/FAQ#How_else_can_I_monitor_the_health_of_my_system?)
  * [How do I move data from one zpool to another?](http://code.google.com/p/maczfs/wiki/FAQ#How_do_I_move_data_from_one_zpool_to_another?)
  * [Miscellaneous utilities and information](https://code.google.com/p/maczfs/wiki/FAQ#Miscellaneous_utilities_and_information)

## _**Where do I get MacZFS and how do I install it?**_ ##
MacZFS 74 is the current stable release.  [Click here](http://code.google.com/p/maczfs/downloads/list) to download it.  Just download on a supported system and double click that file.  There is a [release of PureDarwin](http://www.puredarwin.org/downloads/xmas) which includes an older ZFS, and [other info about it](http://www.puredarwin.org/curious/zfs).  Then you're ready to follow our [Getting Started Guide](http://code.google.com/p/maczfs/wiki/GettingStarted) to partition your drives, make a zpool, and use ZFS.


---

**Note:** Development of MacZFS ceased in mid 2013. Please switch to [O3X](https://openzfsonosx.org/)

---


## _**On what systems does MacZFS run?**_ ##
Supported systems include any combination of MacOS 10.5/10.6/10.7 or [PureDarwin](http://puredarwin.org), PowerPC or Intel, 32-bit or 64-bit.  Many people have run it for years on 32-bit CPUs, or on 64-bit CPUs in 32-bit kernel mode, with 512 MB of RAM.  But ZFS has always been fundamentally performance-optimized for 64-bit operation.  64-bit mode and at least 1 or 2 GB of RAM are recommended on any ZFS platform.  MacZFS is [pure by PureDarwin's standards](http://www.puredarwin.org/developers/macports/purity).

Please install MacZFS on Mac OS 10.8 according to the [manual instructions](http://code.google.com/p/maczfs/wiki/FAQ#How_do_I_install_MacZFS_manually?), run the [burn-in software](http://code.google.com/p/maczfs/issues/detail?id=14&q=ztest), and report your findings to the mailing list.  Thanks!

## _**How do I install MacZFS manually?**_ ##
This is how to manually install MacZFS, such as on a target which isn't known by the [Installer package](http://code.google.com/p/maczfs/downloads/list).  This is mainly intended for PureDarwin.  Get the latest stable .pkg file.  The following works for unpacking the embedded gzip+cpio archive on Mac OS 10.8.0.  Assuming. ~/tmp does not exist, do this:

```
pkgutil --expand MacZFS-74.3.0.pkg ~/tmp
cd /
sudo tar zxvf ~/tmp/zfs106.pkg/Payload
```

To get a list of contents (the "bill of materials"), do this:

```
lsbom ~/tmp/zfs106.pkg/Bom 
```

## _**How stable is MacZFS?  Can I totally trust it?**_ ##
First and foremost, MacZFS is ZFS.  MacZFS 74 is a stable release based on Oracle's stable onnv\_74.  It is from a timeframe where ZFS was already almost ten years mature, in massively widespread and large-scale enterprise usage, and was already several years beyond virtually any other storage platform in the world.  Its zpool version 8 is about a year or two behind the mainstream free release found in [OpenIndiana](http://openindiana.org/), but is nevertheless a highly venerable, stable, widely tested, and mature product.

MacZFS is ZFS.  Kernel panics are truly rare, and are unheard of for most users.  If your system crashes, you can be sure that all of your data will still be there.  There have been no reported cases of data loss using any implementation of ZFS on MacOS in recent history.  That history spans years, if ever.

We believe it to be the best storage solution currently available for most MacOS users, at any price.

Please see our suggested [quality assurance methods](http://code.google.com/p/maczfs/issues/detail?id=14).

Your typical point of comparison on MacOS is the mighty HFS+.  So let's rephrase the question.  Do you consider HFS+ to be perfectly stable?  Do you trust HFS+ with your money and your time?  Is all of your HFS+ data still there?  Are you sure?  We hope that helps to put things into perspective.

## _**I've never had any corruption, so is ZFS really necessary?**_ ##
"You say that file corruption is a fact of life that every Mac user has to deal with. I haven't had one file get corrupted on my Macs. Where is your proof, to back up these claims?"  You've never had any corruption, that you know of, yet.  Where's your proof?  Your skepticism is easily understood and appreciated by the architects of ZFS who you would question.  That's because the question is a mirror. It goes both ways. Your claim that you know that every one of your billions of bits is empirically correct, is a truly extraordinary claim which requires extraordinary proof.

It requires extraordinary proof like that which, for example, would be provided by a guaranteed end-to-end block-level checksumming storage system, with free source code to be audited.

So in other words, if you don't have ZFS, then you must do something like the following.  Checksum each installed file against the Mac OS installation source.  You can't checksum it against a freshly installed copy, because you can't prove that the RAM, CPU, cables, hard drives, and software were absolutely error free during the installation.  It's a chicken-and-egg problem.  You must get a file type checker utility, which knows the file format of every file you have, such as JPEG, MP3, plists, etc, and validate their structure.  You must open every file and inspect its contents -- the audio or image or video -- pixel by pixel or character by character, against a known good source which you can somehow cryptographically authenticate.  If you're able to do that for every file type that you have, then you can be **reasonably** sure that your data is intact, or at least good enough to your eyes and ears.  Now do it again, to prove that the act that you just performed in reading it, didn't inherently cause it to be corrupted.  Now, do it again.  Forever.

By the way, while you're at it, when (not if) you eventually find a corrupt bit, you may as well be ready with a method to instantly fix it.

## _**What is the future of MacZFS?**_ ##
See the [Roadmap](http://code.google.com/p/maczfs/wiki/Roadmap) for the latest developments, based on porting the latest ZFS code from ZFSonLinux, which is developing rapidly.  As for the stable MacZFS 74 version...

At the risk of sounding self-aggrandizing, the primary reason for the slow pace in the past is **the fact that it's so good and stable**.  Secondarily, it's a huge and complex project.  Developers are devoutly participating in the mailing list and making periodic commits, but nobody had been forced by pain and suffering to hack or fix it.

Because as far as we know, it absolutely just works.  However, we are **very** enthusiastically accepting any new developers or sponsors.

In any case, MacOS's architectural development path has been so stable that the old svn 119 ZFS still loads on MacOS 10.6, and MacZFS 74 runs on MacOS 10.8.  So we expect it to continue to work.

## _**Does Apple support or interact with MacZFS?**_ ##
No, we have had no contact from any current Apple employees.  But we would love to hear from past or present Apple employees, on any level!  Good job, guys.  We're kinda fans.

## _**Is there any negative ramification from the fact that Apple doesn't support ZFS?**_ ##
There is no absolute technical detriment.  But it would be really really nice to have completed the low level integration with XNU and with Finder and maybe with a few APIs.  It would be very helpful if Mac OS and various applications were not hardcoded to be based on case-insensitivity and on HFS+.  And it would have been really, really helpful if they would publicly acknowledge the ongoing free software community, so that the general public doesn't believe that we don't exist just because Apple withdrew.  The chilling effect of that one phenomenon alone, cannot be overstated.

Thanks to Sun's initial release years ago, ZFS is forever free software.  Existentially speaking, there is no tangible thing which the community had, or was entitled to receive, which was truly taken away by Apple's withdrawal.  The free software volunteer community loves its corporate benefactors, but corporations neither grant nor deny a community its right to exist, and they don't define who the community are as people.  Not even those who own all of the copyrights can completely grant or define such things, as long as the software is truly free.  This is the case with ZFS.

Apple started things off in a big, big way.  They marshalled a global groundswell of awareness and support for ZFS and for the concept of data integrity, for which the MacZFS project is forever grateful.  The company withdrew amicably from the project, in their impersonal, policy-driven, legalistic fashion.  It may not have been a clear, summary judgment, but rather, a combination of technical and legal conundrums.  That's the cultural norm for Apple and for many other megacorporations, and we respect their privacy.

We picked up the pieces and moved on.  We maintained the viability and market share of ZFS on MacOS beyond **four** major operating system releases, should they ever return.

When Apple left, the world missed out on a lot of anticipated software gifts, to which the world was never entitled to begin with.  Similarly, the canonical free ZFS platform -- the whole free operating system distribution of OpenSolaris -- has been completely discontinued by Oracle, and yet their community has carried on in full force nevertheless.  There is a ZFS working group, so that ZFS can theoretically exist independently of any operating system, any entity, or any private interest.

Apple continues to actively bolster countless free software projects and open standards that we all use daily.  We regret to see them leave the project, and the whole world hopes that they return at any time.

## _**Who is MacZFS intended for?  Is it easy to set up?  Is it Mac-like?**_ ##
MacZFS is for people who have MacOS, who have data, and who really **care** about keeping **all** of their data.  It'll store your petabytes with raging speed, or it'll keep the bit-rotted bleeps and bloops out of your iTunes library.

Assuming that you're not terrified of Terminal.app, it's about as easy as you make it.  The simplest MacZFS setup can begin with one partition on one hard drive, double-clicking the installer, and typing one or two commands.  Boom, guaranteed data integrity on all platforms, forever.  That may include dozens of terabytes and the ability to withstand the loss of several hard drives.

Then, all of your hard drives automatically pop up as one giant hard drive in the Finder from then on, just like any other hard drive.  Your files look and act exactly like any other files, appearing in all your applications, except that they're case-sensitive.  MacOS makes it all magically work just how you expected.

We have one intrepid user who quickly set up a four-drive raidz1 array by himself, with no prior Unix experience, just by following the instructions on this web site.  Then he got minimal post-installation configuration help (how to use 'chmod') from our volunteers on IRC.  No joke.

Some people have a single laptop drive shared with HFS+, some people have eSATA JBODs on a Mac Mini, and some people have 16 terabytes on a Mac clone.  MacZFS can handle the biggest, most expensive setup that you can probably imagine seeing in your home or office.  Given any MacOS system, there is no limit to the size or complexity.

As with other ZFS systems, MacZFS is **generally** for system administrators, for people who follow that mentality, and for people who can follow written instructions.  But you retain the familiarity and niceness of the surrounding MacOS environment.  Its one-time initial setup is command line only, but ideally you just set it up and forget it.  You just need to develop a basic storage strategy, about how to allocate your hard drives and to plan for the future.  You can do web searches, or chat with us on the mailing list or on IRC, to quickly sum up such a strategy.

MacZFS suits the raw technological needs of Mac users who have the drive (ha!) to set it up, ranging from personal to small enterprise level users.  The only features that it lacks are the higher end features which are largely unique to ZFS and which are found near the enterprise level of IT, in major data centers.  And even then, those missing features are usually provided only by ZFS on another platform.

If you're reading this, then it's almost certainly for you.

See [an old movie](http://hub.opensolaris.org/bin/view/Community+Group+zfs/basics) on ZFS basics.

## _**What quality assurance methods can I use to ensure MacZFS's stability for my needs?**_ ##
Please see our suggested [quality assurance methods](http://code.google.com/p/maczfs/issues/detail?id=14).

## _**Is there a GUI with which to manage MacZFS?**_ ##
Not officially, but we need someone to see if [ZFSGuru's web-based GUI](http://zfsguru.com/) works on MacOS!  Here is [one of their old announcements](http://forums.freebsd.org/showthread.php?t=14904).

## _**Can it fill and empty the Trash in the normal Mac way?**_ ##
Yes!

## _**Does it work ok with USB and other external drives?**_ ##
[Be aware of issues inherent in USB](http://code.google.com/p/maczfs/wiki/USB) and avoid it wherever possible, or be careful.  eSATA is just the same as SATA, but removable, and most or all versions of Mac OS don't support hot plugging eSATA anyway.  Information about hot swapping non-USB drives is unknown to the FAQ author at this time.  Please report to the list.

## _**Should I install one of the development versions, one that's not the stable version?  The number is higher!**_ ##
No!

## _**Well, I did.  And I learned my lesson.  How do I go back?**_ ##
You should [completely uninstall it](http://code.google.com/p/maczfs/wiki/Uninstalling), reboot, and then install the latest stable package.  If you had created a zpool with a zpool version higher than that which is supported by the stable release, then you must either destroy and recreate that zpool, or you must use the development MacZFS to create an additional and backward-compatible zpool on another partition using `zpool create -o version=8 penitentpool` and possibly `zfs create -o version=2 penitentpool/filesystem` and then copy your data.

## _**What software versions and features does MacZFS support?**_ ##
MacZFS 74 is the current stable release, based on Oracle's `onnv_74`, providing zpool version 8 and zfs version 2.  This supports hot spares, raidz2/mirror/stripe, gzip compression, block duplication, separate ZIL devices, 4k drives (even mixed with 512 bytes drives), and every bit of bit-for-bit data integrity guarantee that ZFS ever provided.  Zpool version 8 is a highly venerable and mature codebase which provides all functionality and integrity that are absolutely essential.
```
$ zpool upgrade -v
This system is currently running ZFS pool version 8.

The following versions are supported:

VER  DESCRIPTION
---  --------------------------------------------------------
 1   Initial ZFS version
 2   Ditto blocks (replicated metadata)
 3   Hot spares and double parity RAID-Z
 4   zpool history
 5   Compression using the gzip algorithm
 6   pool properties
 7   Separate intent log devices
 8   Delegated administration
For more information on a particular version, including supported releases, see:

http://www.opensolaris.org/os/community/zfs/version/N

Where 'N' is the version number.

$ zfs upgrade -v
The following filesystem versions are supported:

VER  DESCRIPTION
---  --------------------------------------------------------
 1   Initial ZFS filesystem version
 2   Enhanced directory entries

For more information on a particular version, including supported releases, see:

http://www.opensolaris.org/os/community/zfs/version/zpl/N

Where 'N' is the version number.
```
The unstable MacZFS 78, based on Oracle's `onnv_78` is at zpool version 10.  It will panic, and is only to be used by ZFS  developers.

## _**How does it compare to the current, free Illumos-based release?**_ ##
This also applies when comparing MacZFS to FreeBSD, ZFSonLinux, and probably ZFS-FUSE.  It's missing some of the more high-end features, including deduplication, encryption, zvols, raidz3, relocatable ZIL support, ACL support, L2ARC, and it's missing case insensitivity.  It's missing some non-critical bug fixes.  It's missing some higher end internal performance enhancements.  See [Wikipedia's list](http://en.wikipedia.org/wiki/ZFS#Version_numbers) of notable features above zpool version 8.

Here's the list of [all zpool versions on any platform](http://hub.opensolaris.org/bin/view/Community+Group+zfs/).

If you have to ask whether you need any of that, then the answer is probably **no**.  For the rest of you, you almost certainly don't absolutely require it, at least not on your Mac OS system.  You can still make a totally reliable and fast system with dozens of hard drives using the same strategies which most of the world's ZFS users still use anyway.  As with ZFS standard practice, you can scale by striping your raidz1/2 vdevs, or separating your ZIL device.  And you can make sparse bundles containing HFS+, for your case insensitivity.

## _**How does MacZFS compare to Apple's 10a286 beta release?**_ ##
Apple obviously had done some amazing work, and we thank them for the partial source code release (not all of which we have incorporated into MacZFS), but that release is not to be put into use.  Please take a look at [the 10a286 source code](http://maczfs.googlecode.com/files/zfs-10a286-cddl.tar.bz2) which Apple released.

## _**What should I do with 4k (Advanced Format) hard drives?**_ ##
The following is partially an opinion piece, and I invite correction and clarity.

If you create your partitions on Mac OS, using Disk Utility (such as via the [Getting Started Guide](http://code.google.com/p/maczfs/wiki/GettingStarted)), then the system automatically aligns everything to 4k blocks.  Then, you create your zpool.

You must create your zpool with 4k alignment from the beginning; you can't change it later.  You'd have to destroy and recreate it.  You create a pool with 4k alignment by adding the `-o ashift=12` property option to the `zpool create` command line.  See the zpool man page and `zpool --help` output for details.  Note that specifying the `-o ashift=12` really only sets the pool's default.  You can still override it for any individual vdev (physical harddisk, mirror of disks or raidz group) you later add using `zpool add` by specifying a different ashift value as in `zpool add -o ashift=9` if you want to add an old disk with 512 byte sectors.  Of course you can also format an old 512 bytes disk with ashift=12 as 4k, which might even perform better than using the physical 512 bytes block size.

### _What if I have an old pool with old 512 byte disks, but need to add a 4k drive?_ ###
No problem.  Starting with MacZFS\_74.3 you can specify different ashift values for individual top-level vdevs (physical harddisk, mirror of disks or raidz group) as discussed above.  Simple use `zpool add -o ashift=12 _your_pool_name_  _you_new_vdev_spec_`.

At least one person has reported using FreeBSD's 'gnop' feature and 'zpool create', to create a 4k-aligned zpool, which they relocated over to MacZFS.  They report that it's a lot faster with MacZFS and ashift=12, than it was with FreeBSD and ashift=9.

### _Some historical background on the whole problem_ ###

_The procedure here after is no longer needed!_

For a long time, the upstream ZFS community wasn't exactly sure how to handle the 4k debacle, so they also relied on hacking a separate Solaris executable.  So if you wanted to activate 4k support, then you booted Solaris to create your zpool with that particular version of the 'zpool' executable.  FreeBSD sets it with the 'gnop' layer, which allows its ZFS layer to autodetect the desired setting.  ZFSonLinux sets it with their own syntax of 'zpool create -o ashift=12'.

What's the debacle?  The hard drive manufacturer community has been designing most or all of their 4k hard drives to lie to the host, for compatibility with lesser, decrepit, proprietary operating systems.  Furthermore, as I understand it, ZFS's 4k support is not a hack, because ZFS has always had variable support for block sizes.  It's just that the hard drives defeated ZFS's autodetection with their filthy, filthy lies.  So ZFS always autodetected 512 byte block sizes.

So we have to specify it manually.  It has been unfortunately tough for ZFS engineers to implement manual ashift specification correctly, and to modify all the tools needed in order to support the syntax.  But the internal support for ashift specification, has been long implemented.  They have had a hard time agreeing on the command line syntax, as it relates to the rest of the internal code.  Furthermore, 4k support is not a typical enterprise critical path yet because most enterprise drives have been 512 bytes, and it wouldn't have caused the sale of a lot more hard drives.  And I can guess that people wanted more widespread deployment first, like a chicken and the egg.  But I believe they found that it had been fine all along, and that it's just another variable in the code.  Enterprise engineers are cautious.

In any case, that's what we're all doing with our 4k drives -- hacked executable behavior or not.

So, again, to be clear, the issue is not supporting 4k drives.  Every ZFS implementation has supported the existence of different ashift values for a long time.  The only issue is how to **specify** your ashift value.  That is not yet completely resolved officially upstream, but they all have their methods or hacks.  Once that value is specified on a given zpool, however it was done, the issue is resolved for that given zpool.

Why would you want to specify your ashift value?  You should do it if you have all 4k drives, or a mixture of 4k and 512b drives, or if you have an all-512b zpool but you  ever anticipate the possibility of replacing any of them with 4k drives.  4k is the way of the future, and it's already the increasing norm in the sub-enterprise world.  So Mac OS users almost certainly want this.  Some drives have reported even higher speeds with ashift=13.  You need to experiment with this value.

As with any larger block/cluster sizing, the only tradeoff is possibly some extra space consumed.  And 512b is a common denominator of 4k, so you can mix them.  But the performance gains on a 4k drive are dramatic.

[Here is an article](http://oceansidecoding.wordpress.com/2011/09/13/maczfs-performance-analysis/) bearing some tests of the results.

[The ZFSonLinux community provided an analysis](https://github.com/zfsonlinux/zfs/issues/289) of the difficulties inherent in the autodetection of 4k drives.  [Here is the status of Illumos's](https://www.illumos.org/issues/2663) work on the subject.  [Here is FreeBSD's status](http://ivoras.net/blog/tree/2011-01-01.freebsd-on-4k-sector-drives.html) on the subject.

## _**What do I do if I absolutely need ZFS features which are more advanced than MacZFS's current implementation, or which are found only on another OS?**_ ##
If that's the case, then you probably aren't reading this because you already know what to do.  ;-)  If you're a kernel developer, please see our [rapidly emerging prototype](https://github.com/zfs-osx), which will provide current ZFS functionality.

For the stable release, you can get another machine to use as a ZFS server running a different OS and share that via NFS, iSCSI, AFP, or whatever.  Or you can run, say, [OpenIndiana](http://openindiana.org), inside a virtual machine such as VMware or VirtualBox hosted on MacOS, giving the VM access to a host file or to your raw hard drives containing its own zpool, and exporting that zpool back to the MacOS host using iSCSI/NFS/AFP.  **Whew**.  There are a few people who have done this, in order to achieve deduplication of things like source code repositories.  But you'd really better know what you're doing first, and do a simulation analysis to indicate how much damage deduplication will do to your hardware performance.

Upgrading a zpool doesn't change the existing data or meta data.  It simply sets a flag that from now on the new format should be written.

## _**Can I boot from ZFS?  Can I convert totally from HFS+ to ZFS?**_ ##
No, you can't boot from ZFS on MacOS.  MacOS can currently only boot from HFS+ volumes.  [That would require another level of work](http://groups.google.com/group/zfs-macos/browse_thread/thread/69c3e7b098a691e2).

You can carefully move a lot of things to ZFS.  It was said years ago, that some people migrated almost everything to ZFS except for /System and /Library and a few other ancillary and boot-related directories.  The other issue is [a lack of case insensitivity in MacZFS](http://groups.google.com/group/zfs-macos/browse_thread/thread/00651a71ebc64448).

Some apps, such as Adobe Creative Suite, Steam, and some of the art from Final Cut Studio, are case-insensitive.  And MacZFS 74 doesn't support case insensitivity, requiring you to install them to HFS+-formatted DMGs using symlinks or something like that with a tool like 'shove'.

```/System//Library/PrivateFrameworks/PackageKit.framework/Versions/A/Resources/shove```

If you have auto-login enabled for your user's desktop, it is recommended that you keep your ~/Library on HFS+ just in case ZFS hasn't mounted by the time your user has logged in.

However, it's best to create a delay so that your ZFS has time to acclimate.  You can disable autologin, which presents a password prompt upon boot.  You can put the file representing your user's avatar, on your ZFS location; then, when your ZFS is initialized, the avatar will appear.  Or, just wait a little bit.

## _**Will my ZFS volumes automatically appear upon boot and then properly shut down?**_ ##
Yes, if you followed the instructions in the [Getting Started guide](http://code.google.com/p/maczfs/wiki/GettingStarted) upon the initial creation of your zpools.  All it requires is a valid hard drive partition type on a GPT volume.  If not, such as with zpools you moved from another system or zpools you created inside of a loopback file, you can instruct MacOS to manually execute an import/export command upon startup and shutdown.  See the bottom of the [Getting Started guide](http://code.google.com/p/maczfs/wiki/GettingStarted) for more information.

Here are tentative workarounds as [discussed here](http://groups.google.com/group/zfs-macos/browse_thread/thread/c102d4421d9f6796).  Don't forget how paranoid launchd is, and do this: `sudo chown 0:0 /etc/rc.shutdown.local ; sudo chmod u+x /etc/rc.shutdown.local`  Please read about `launchd` and submit something better!  See [Apple's launchd documentation](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html) and [this discussion](http://lists.apple.com/archives/macos-x-server/2007/Oct/msg00016.html).

Here's a simple set of scripts, if it helps anyone to understand things better.

```
$ cat /etc/rc.shutdown.local
#!/bin/bash
# ZFS shutdown script by dtm and KonaB1end

LOG=/var/log/maczfs.log

echo -n "ZFS shutdown " ; date >> $LOG 2>&1

echo "umounting ZFS" >> $LOG
#diskutil communicates properly and more reliably with diskarbitrationd
#zfs umount -a >> $LOG 2>&1
for i in $(zfs list -H -t filesystem -o mountpoint) ; do
	diskutil umount $i >> $LOG 2>&1
done

echo "Exporting all ZFS pools" >> $LOG
for i in $(zpool list -H -o name) ; do
	zpool export $i >> $LOG 2>&1
done

$ cat /Library/LaunchDaemons/org.maczfs.zfs.fs.plist 
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>org.maczfs.zfs.fs</string>
        <key>ProgramArguments</key>
        <array>
            <string>zpool</string>
            <string>import</string>
            <string>-a</string>
            <string>-f</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>StandardOutPath</key>
	<string>/private/var/log/maczfs.log</string>
    </dict>
</plist>
```

## _**Does MacZFS work with Spotlight?**_ ##
[Not really.](http://groups.google.com/group/zfs-macos/browse_thread/thread/dfcda6a9b71b0dac)  It'll waste resources scanning your volumes but then you can't search them.  Some people disable Spotlight from their ZFS volumes using `mdutil -i off /Volumes/myzpool`.

Note how to enable Spotlight and [AppleDouble](http://netatalk.sourceforge.net/3.0/htmldocs/upgrade.html#id4282732) support of Netatalk volumes

## _**Can I share zpools between other operating systems such as Linux, FreeBSD, or Solaris?**_ ##
Yes.  ZFS was always designed to be portable and to respect cross-platform behavior, including endianness.  As with almost any other data format, you have to use the lowest common denominator of versions.  MacZFS 74 supports zpool version 8.  So if you create a zpool on MacZFS, it'll work on any recent version of Linux, FreeBSD, or Solaris.  But if you create a zpool on those other systems, you must create it at version 8 using this:

```
zpool create -o version=8 mypool
zfs create -o version=2 mypool/myfilesystem
```

If you do not, it will be permanently unreadable in any ZFS system of a lower zpool version, such as MacZFS 74.  In this case, you will have to **copy** your data over from the previous system to another zpool on your MacZFS system.  You can use `zfs send` to preserve all basic ZFS metadata, or use the totally generic rsync.

Beware of filenames containing non-ASCII characters. Any such filename needs to be encoded in utf-8 with MacOS's peculiar normalization, or you won't be able to access the file on MacOS, not
even to delete it.

And as with any cross-platform filesystem access, beware of [ACL](http://en.wikipedia.org/wiki/Access_control_list) incompatibilities.

## _**Can I host my Time Machine archives on a ZFS target?**_ ##
Yes, but not directly.  Time Machine, itself, requires either a raw block device formatted with HFS+, or the latest version of AFP.  To host your Time Machine on a local MacZFS volume, you must do one of the following:
  * set up an AFP server such as netatalk on your LAN or on localhost
  * Create a sparsebundle disk image, formatted to HFS+, and run this systemwide command once:
```
defaults write com.apple.systempreferences TMShowUnsupportedNetworkVolumes 1
and/or this:
touch .com.apple.timemachine.supported
```
Alternatively, if your ZFS is hosted on a platform other than MacOS, you can either use netatalk or you can export a zvol as an iSCSI device, to a Mac OS iSCSI connector, and format that as HFS+.

As a more ZFS-native replacement for Time Machine, see [this utility](https://github.com/jollyjinx/ZFS-TimeMachine) and post your findings.  For recovering Time Machine without Mac OS or Darwin, [try this](https://github.com/abique/tmfs).  For recovering sparsebundles, [try this](https://github.com/torarnv/sparsebundlefs).  For automated snapshots, try [Alex's system](http://alblue.bandlem.com/2008/11/crontab-generated-zfs-snapshots.html) and [zfSnap](https://github.com/graudeejs/zfSnap/wiki).

See [how to set up an iSCSI target hosted on Solaris for Time Machine](http://web.archive.org/web/20090223193539/http://blogs.sun.com/constantin/entry/zfs_and_mac_os_x) (not possible on MacZFS 74) or [this](http://www.kamiogi.net/Kamiogi/Frame_Dragging/Entries/2009/5/25_OpenSolaris_ZFS_iSCSI_Time_Machine_in_20_Minutes_or_Less.html).

[Here](http://groups.google.com/group/zfs-macos/msg/e331eae204b183ba?) is an introduction to the reason why Time Machine is hardcoded to HFS+.

## _**Will Time Machine back up from a ZFS source?**_ ##
Not directly.  Time Machine is another one of Mac OS's features which is predominantly based on HFS+.  It may be possible to work around this using netatalk, and by enable nonstandard filesystem sources.  Please feel free to post to the MacZFS mailing list to contribute background information to explain this issue.

## _**Does anyone have MacZFS in commercial production, with their reputations staked on it?**_ ##
Yes, although it's impossible to count the users of free software.  They range from personal installations, to consultants, to several unattended Mac Mini server deployments in dental offices.  All ZFS users tend to have some **serious** hardware and livelihoods devoted to it.  If they have critical problems, it's safe to bet that we hear about them.  Check the mailing list archives and IRC channel for stories!

## _**Is there any point of using it on a laptop or a system with only one hard drive?**_ ##
We have lots of users, including primary MacZFS developers, who have a single-drive laptop partitioned as HFS+ for booting and ZFS for data.  No problem.  The total failure of an entire hard drive is not necessarily one's greatest concern.  Silent data corruption, also known as "bit rot", is everpresent.  ZFS protects against that whether you have a lot of files, or DMGs/sparsebundles/clones.  And ZFS can give you some single-drive redundancy anyway by [making copies](https://blogs.oracle.com/relling/entry/zfs_copies_and_data_protection).

## _**Does ZFS run on iOS?**_ ##
Here is [an older article](http://www.macworld.com/article/156796/2011/01/2011_predictions.html) with speculation and here's [a newer article](http://www.imore.com/2012/02/03/zfs-references-latest-ios-51-beta/) with an unsubstantiated claim that it has arrived in iOS 5.1 beta, although that may actually be an unreleased internal-only experimental build.  [Here is a followup article](http://www.imore.com/apple-zfs-speculation-ios).

iOS is essentially an embedded MacOS, and we would hope that it would not take much more effort to port it.  However, Apple strips out all ARM code from their iOS source code releases, and the iOS kernel is non-modular.  So there is no support for loadable kexts.  It seems that the free software community is out of luck, unless we port iOS back to the iPhone.

There are naysayers who claim that ZFS is functionally irrelevant, or is too heavy, for a phone or other embedded systems.  Those claims are about as valid as any open-ended naysaying about what is or is not possible in this world.  An iPhone 4 has the equivalent processing power and capacity of the minimum requirements for the current ZFS, and about that of a heavy workstation or a serious server, back when ZFS's development began.  There is no sense whatsoever in attempting to dictate what free software can or cannot be used for, or in effectively denying the existence of Moore's law, or in denying the ingenuity of Apple's embedded engineering, or that ZFS's performance variables cannot be configured.

Even if flash storage doesn't hit the same critical mass which hard drives have hit, where it's so cheap and so big that redundancy is a necessity, embedded ZFS is still awesome.  [See our FAQ entry about single-device systems](http://code.google.com/p/maczfs/wiki/FAQ#Is_there_any_point_of_using_it_on_a_laptop_or_a_system_with_only) such as laptops.  As with the promises of ZFS on the desktop, ZFS provides a faster bootup by eliminating the 'fsck' process; and, its snapshotting could provide live, realtime, over-the-air, failsafe operating system updates.

It is interesting trivia that iOS is based on case-sensitive HFS+.

As a side note, NEC has created an embedded ZFS for ARM, mentioned [here](http://mail.opensolaris.org/pipermail/osarm-dev/2009-June/000068.html)

## _**How else can I monitor the health of my system?**_ ##
Try these apps.  Note that some are even free software (GPL, etc)!  These are unrelated to MacZFS, and are not officially endorsed by this project.

  * [SMARTreporter](http://www.corecode.at/smartreporter/) is a GUI for smartmontools (free software originating on Linux and friends), amongst other things, and has a freeware version.  This will run in the background and give you a popup warning when a drive is reporting imminent failure via SMART.
  * [SATSMARTDriver](https://github.com/kasbert/OS-X-SAT-SMART-Driver/blob/master/SATSMARTDriver-0.5.dmg) is a kext which may further enhance SMART reporting.
  * [MenuMeters](http://www.ragingmenace.com/software/menumeters/) is completely awesome, and completely free, for monitoring many aspects of your system's health and performance at a glance.
  * [TemperatureMonitor](http://www.bresink.com/osx/TemperatureMonitor.html) is freeware for monitoring your system temperatures in your menu bar.
  * There are other proprietary data integrity tools which report SMART, and can test other aspects of your system.  They usually focus mostly on fixing HFS+'s problems.  This includes TechTool.
  * [Opensnoop](http://osxdaily.com/2011/04/22/monitor-mac-os-x-filesystem-usage-access-with-opensnoop/) Monitors Mac OS X Filesystem Usage & Access

## _**How do I move data from one zpool to another?**_ ##
MacZFS has some cosmetic limitations with `zfs send`, so please see [this howto by MacZFS engineer, Alex Blewitt](http://alblue.bandlem.com/2010/11/moving-data-from-one-zfs-pool-to.html).

## _**Miscellaneous utilities and information**_ ##

[MacZFS and Backblaze](https://groups.google.com/d/msg/zfs-macos/5XuHDfkn4Vg/8_MkyUHsXskJ)

http://brkirch.wordpress.com/switchdisksizebase/

HFS+ transparent compression:
  * https://github.com/diimdeep/afsctool
  * http://hints.macworld.com/article.php?story=20090902223042255