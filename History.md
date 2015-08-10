# Project History #


---

**Note:** Development of MacZFS ceased in mid 2013. Please switch to [O3X](https://openzfsonosx.org/)

---


Years ago, Apple began the visionary and ambitious undertaking of porting ZFS to Mac OS.  The company distributed ZFS as a read-only kernel extension in Mac OS 10.5 and later as a fully functional suite in the developer beta builds of Mac OS 10.6.  Apple hosted the project at the now defunct _http://zfs.macosforge.org/_; the now defunct original mailing list [is now mirrored at Nabble](http://mac-os-x-zfs-discuss.19757.n3.nabble.com/).  After a lengthy hiatus from the public eye prior to the final release of Mac OS 10.6, the company unceremoniously withdrew their involvement from the ZFS community both internally and publicly, by suddenly deleting all traces of ZFS from their web sites and almost all traces of ZFS from Mac OS.

Possible explanations for this action involve a failure to achieve a private licensing agreement between Apple and Sun over the ZFS source code.  This was severely exacerbated by overarching legal aggression from Net App toward Sun, and hence potentially toward Sun's customers such as Apple.

Forever grateful to Sun, to Apple, and to all of their brilliantly visionary engineers for the generous head start, the community fearlessly resumed the project's development.  The community reacted immediately to the disorienting setback by mirroring all historical resources, by opening this project page, and by starting various personal source code forks.  Development has ensued in the years since.

The summary result of all of these efforts made by Sun, Apple, and the MacZFS community is the drastic advancement of the state of the art of storage technology on Mac OS.

Also see our [Credits](Credits.md) page for more information about individual contributors.

Aside from MacZFS, there is another port of ZFS to Mac OS which was done by [Ten's Complement](TensComplement.md) and [GreenBytes](http://www.getgreenbytes.com/blog/bid/80758/GreenBytes-Welcomes-ZEVO-and-Don-Brady), who has altered their original commitment to free software and now instead offers to customers, a proprietary subset of ZFS functionality.

## The slow stop of MacZFS in 2013 ##

MacZFS was under active development until mid of 2013, when it became clear that its development model of incrementally patching up the source to newer build will potentially never catchup with the constantly evolving ZFS on other platforms.  Limited time resources of both core developers put additional doubts on a sustainable development process for MacZFS.  As a consequence, the project reached out to other ZFS communities and developer to both strengthen its team and revise its development model.  New team members brought in fresh ideas and a much more agile development style, resulting in a new experimental MacZFS-ng, abandoning almost all of the old core ZFS code base and keeping only the Solaris porting layer.

## The new Future of ZFS on OS X ##

Throughout 2013 MacZFS-ng matured and eventually became its own, independent project _OpenZFS on OS X_ or [O3X](https://openzfsonosx.org/).  O3X is part of the larger cross-platform [OpenZFS](http://open-zfs.org/wiki/Main_Page) initiative (a community of open source projects and companies active in ZFS development and applications) aiming at increased cross-platform compatibility, code sharing and development coordination between all stake holders.

The current development takes place in the _OpenZFS on OS X_ (_O3X_) project at https://openzfsonosx.org/.  Everyone formerly using MacZFS is encouraged to move over to O3X and migrate to the latest stable version of [O3X](https://openzfsonosx.org/wiki/Downloads).