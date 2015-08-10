# Introduction #

ZFS is developed as part of OpenSolaris, so rather than being a separate downloadable project, it's mixed in with the combination of the OpenSolaris codebase.

## Getting the source ##

OpenSolaris is hosted via Mercurial, at http://hub.opensolaris.org/bin/view/Project+onnv/WebHome Cloning this will generate a lot of data; there's also a tool which can be used to convert this into a git repository (http://github.com/roddi/TelescopeSolarisZFS).

The mercurial repository has tags, onnv\_72 appears to the one that Apple forked the code from.

## Mappings between Apple layout and ONNV layout ##

```
mac-zfs/zfs_lib/lib*/*                  <-> onnv/usr/src/lib*/common/*
mac-zfs/zfs_commands/zfs/*       <-> onnv/usr/src/cmd/zfs/*
mac-zfs/zfs_commands/zpool/*   <-> onnv/usr/src/cmd/zpool/*
mac-zfs/zfs_commands/ztest/*    <-> onnv/usr/src/cmd/ztest/*
mac-zfs/zfs_commands/zpoink/* <-> none, Apple developed code
mac-zfs/zfs_common/*                <-> onnv/usr/src/common/*
mac-zfs/zfs_documentation/man8/ <-> ? not in onnv as far as I can tell
mac-zfs/zfs_bundle/*                  <-> none, Apple developed code
mac-zfs/zfs_kext/zfs/*               <-> onnv/usr/src/uts/common/fs/*
```