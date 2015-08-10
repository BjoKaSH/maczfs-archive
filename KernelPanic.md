# Panic decoding #

To support easy debugging of panics (on Intel systems, currently) there is a tool in `support/decode-panic` which can generate a list of files, based on the below.

You can acquire a copy of this by doing:

```
curl https://github.com/alblue/mac-zfs/raw/untested/support/panic-decode > panic-decode
chmod a+x panic-decode
panic-decode
```

It will attempt to find the latest ZFS panic and generate the symbols from it. This should be attatched to an issue report for ease of debugging in the future.

Currently, it only works on Intel systems, and it does not check that the version of the kernel is the same as reported in the code. Caveat emptor.

# Introduction #

  * You need to download a [Kernel Debug Kit](http://developer.apple.com/hardwaredrivers/download/kerneldebugkits.html) which corresponds to your kernel (need to have a valid ADC account). It will be called something like `kernel_debug_kit_10.6.5_10h574.dmg`
  * Mount it with `hdiutil attach kernel_debug_kit_10.6.5_10h574.dmg` or by double-clicking on the image
  * Generate the symbol files for the installed kernel extension. You will need the first number as displayed in the kernel panic e.g. `com.bandlem.mac.zfs.fs(76.0.7)@0x34f56000->0x34fcffff` will give you `0x34f56000`
```
/Volumes/KernelDebugKit/createsymbolfiles -s /tmp /System/Library/Extensions/zfs.kext/
```
  * Debug into the kernel, specifying -arch i386 or -arch x86\_64 depending on kernel flavour:
```
gdb -arch i386 /Volumes/KernelDebugKit/mach_kernel
```
  * Load the kernel symbolic files:
```
set kext-symbol-file-path /tmp
add-kext /System/Library/Extensions/zfs.kext/
```
  * Look at the individual stack exceptions, as described with `x/i`
```
x/i 0x34f9eb45
0x34f9eb45 <zfs_log_write+654>:	add    %al,(%eax)
```

That will give you a clue as to where the problem is.

# Reporting #

[Here's how](http://code.google.com/p/maczfs/wiki/ProblemReports) to generally report problems to the mailing list.