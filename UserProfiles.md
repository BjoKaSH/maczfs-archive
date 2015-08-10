# MacZFS User & System Profiles #

This is a collection of profiles of individual MacZFS users, and their systems.  This will increasingly include Z-410 users, as all users of ZFS on Mac OS are relevant and welcome!

Welcome to the fray!  Give us your tired drives, your poor sysadmins, your huddled backups.

Our community is comprised mostly of personal systems which are frugal but savvy, inventive but stable.  We are stylin' it up with our Mac OS systems, and we often need to cram and fit a lot into that style.  How do you heap endless terabytes onto a Mac Mini or a Macbook?  How do you attach more than four hard drives onto a Mac Pro?  How do you do it without spending a fortune on a handful of options at the Apple Store?  Show it off, and bring the photos!

### name: Daniel Bethe; IRC nick: dtm ###

  * Home-built Mac clone with 8x2TB drives as a single RAIDZ2 on MacZFS 74.1.0 and Mac OS 10.8.  Those drives are one batch of three Hitachi 7200RPM Deskstars, one batch of four Samsung F4 Spinpoint 5400RPM, one batch of the same model of one Samsung F4 Spinpoint 5400RPM.  I also have another one from that first batch serving as a cold standby, temporarily in an eSATA drive as an occasional backup device until it may ever be needed as a replacement.  This gives me a good compromise of speed and online redundancy of RAIDZ2, plus extra nearline redundancy.
  * 12GB RAM, Gigabyte GA-UD3R-X58A v1 motherboard, Intel i7 920 d0 CPU at 2.66GHz, nVidia 9800GT 1GB dual-DVI, Coolermaster Cosmos case, OWC Vortex 2 90GB SSD
  * Absolutely stable since February 2010 with no real crashes.

### IRC nick: haides ###
  * Mac Mini with 22TB, the biggest Mini recorded by this community (megamonominimania?!).  12x 2TB in three 4-bay sata/fw800 enclosures similar to [this](http://www.ebay.com/itm/4-BAY-SATA-HARD-DRIVE-USB-2-0-1-PORT-ENCLOSURE-CASE-/310140025800?pt=PCC_Drives_Storage_Internal&hash=item4835c93bc8)
```
#zpool list
NAME                    SIZE    USED   AVAIL    CAP  HEALTH     ALTROOT
soundwave              21.8T   4.43T   17.4T    20%  DEGRADED
```
  * "degraded because i'm doing the final disk replacement.  next step is getting 2x 2-bay sata/fw800 enclosures for hot spares.  i've had the zfs pool for over 3 years now, i think.  i just finished upgrading the 12x500GB to 12x2TB."

### name: Jason Belec ###

  * 6TB FireWire MacZFS on a mac mini

### IRC nick: ylluminate ###

  * 4x2TB Hitachi HDS723020BLA642 with 64MB cache (capable of 6GB/s access) in one RAIDZ1, Z-410 beta, Mac OS 10.7 with 64-bit kernel, Mac Pro 2009 Nehelem, 2.93GHz, to be 20GB of RAM, to be Corsair F240 SSD root filesystem.  ATI Radeon HD 5870, 30" cinema, 27" DELL U2711 and a 24" Dell 2408WFP.
  * "the ssd will be in the upper bay just under the super drive as it has a spare sata connector there"

### IRC nick: samsambo ###

  * Mac Mini with a dremel-modified case in order to facilitate an eSATA card in the Airport slot, connected to an eSATA JBOD.  http://avoidant.org/MiniNAS/