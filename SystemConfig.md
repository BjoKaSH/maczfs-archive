# Introduction #

Since ZFS is a software-only solution, you have the freedom to use it with any hardware that your operating system supports.  But not all hardware is created equally, in quality and in features.  The primary focus is on controllers which present individual drives, which is a mode commonly called JBOD (just a bunch of drives).  This contrasts with hardware RAID mode; you might find a great controller at a great price but which only presents an abstracted RAID to the operating system.  JBOD is especially challenging to find with low-end external drive enclosures, because they're targeting users who want cheap, dumb simplicity with the magical idea of per-drive data redundancy.

Of final note is the fact that ZFS, and ZFS users, tend to find problems more aggressively than others.  So you might take our advice even if you're not going to use ZFS, when making your hardware purchases.

# Existing Configurations #

See our [other page](UserProfiles.md) for a list of actual Mac OS based ZFS systems run by actual users.

# Known Good Hardware #

  * "Nitro FireWire hub with drives in individual enclosures for safety" -- Jason Belec

# Unknown Hardware #

Here are some good leads, but which lack empirically verified results with this community.  If you do use these, please notify the mailing list of your experiences.

  * http://forums.macrumors.com/showthread.php?t=1077549
  * http://eshop.macsales.com/item/DAT%20Optic/UF8R5J/
  * http://www.datoptic.com/usb-firewire-jbod-raid-enclosure.html
  * http://www.amazon.com/DataTale-4-Bay-FireWire-eSATA-Enclosure/dp/B002GXEZ7I
  * http://www.ebay.com/itm/4-BAY-SATA-HARD-DRIVE-USB-2-0-1-PORT-ENCLOSURE-CASE-/310140025800?pt=PCC_Drives_Storage_Internal&hash=item4835c93bc8

# Known Bad Hardware #

Yeah, ShadowX (from IRC) was intrepid enough to try to salvage a first generation Drobo which only supports RAID mode.  No JBOD.  In addition to Drobo's internal RAID mode, he used its operating system block device abstraction as ZFS devices.  It functioned, but not very well!

Note that many enclosures which end up bad, may be bad due only to the power supply.

3TB USB drives can be completely nonfunctional in ZFS, even if they work with HFS+.

Also, [USB](USB.md)!