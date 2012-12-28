ReadMe "Testsystem"

This file describes the design and operation of the semi-automatic test
system for MacZFS.

Design
======

The system is build from a list of test cases, implemented in "run-tests.sh"
and a number of support function used to implement the test cases.  The
support functions are implemented in "tests-functions.sh".

The main purpose of the support functions is, to run low-level command
and automatically record and check there outcome, as well as to 
standardize common tasks like pool creation and automatically record 
extra meta data that can be used to later compare the state of a ZFS
pool to its expected state as recorded in the meta data.

The whole system works on an object level, where pools, disks, 
file systems and files are considered as abstract, named objects.

Objects can be created, manipulated, queried and destroyed using shell 
functions.

The whole system state is kept in shell variables (scalar variables and 
arrays) and can as such be inspected using the shell build-ins "echo" 
and "set".

For each object type exists an array enumerating all object of that type
and for each instance of an object exists a set of scalar variables 
holding the relevant meta data.

Objects are implemented using sets of scalar variables, because the 
shell neither has alphanumeric array indices nor multi-dimensional arrays.

The following arrays are defined:

files : list of all files created by the test system.
pools : list of all pools created by the test system.
fss   : list of all file systems created by the test system.
disks : list of all disk images created by the test system.

All four arrays hold as value the name (alphanumeric id) of an object 
of the respective type.

For each object exists a set of variables describing the particular 
instance of the object type.  The following variables are defined:

For files, the following variables are defined, and the <id> (the name 
of the object instance) is the file path and name relative to the ZFS 
file system where the file is placed, but with "/" and spaces replaced 
by "_".

file_<id>_size : size of file in bytes
file_<id>_pool : ZFS file system where the file is stored, empty if not
                 on a ZFS file system managed by the test system
file_<id>_name : original file name, including path relative the ZFS 
                 file system or relative to "/" if not on a test system 
                 managed ZFS file system
file_<id>_path : full path to file, starting at "/"
file_<id>_idx  : numeric index into files array for this file.


For disks, the id is the unchanged name given to make_disk.  The 
variables are:

disk_<id>_attached : 1 if attached, else 0
disk_<id>_disk     : device name of disk if attached, else '' 
disk_<id>_size     : size in GB
disk_<id>_path     : path to sparse bundle directory
disk_<id>_idx      : numeric index into disks array for this disk image.


For pools, the id is the unchanged pool name given to make_pool().  
Note that the pools actual name is different,since it is prefixed with 
a common string fixed for all pools maintained by the test system.  The
prefix is a unique prefix generated at test system initialization and 
serves to create a separate namespace between test pools and other 
pools in the system.  The variables are:

pool_<id>_opt      : options used
pool_<id>_fullname : pool name with pool prefix
pool_<id>_path     : full path to pool file system
pool_<id>_vdevs    : vdev specification used
pool_<id>_idx      : numeric index into pools array for this pool.


For file systems, the id is the zfs file system name (i.e. the nesting 
of file systems) with "/" and spaces replaced by "_".  The defined 
variables are:

fs_<id>_opt      : options used
fs_<id>_path     : full path to zfs file system, this reflects the 
                   mount point setting independent from the ZFS file
                   system nesting.
fs_<id>_name     : original file system name ${fsname}
fs_<id>_fullname : zfs file system name with full pool prefix, this 
                   reflects the nesting of ZFS file systems.  See 
                   description of pool_<id>_fullname and discussion of 
                   pool objects for details.
fs_<id>_pool     : pool name of corresponding pool, without prefix.  See
                   description of pool_<id>_fullname and discussion of 
                   pool objects for details.
fs_<id>_idx      : numeric index into files array for this file



Operation
=========

The system can be used automatically, by simply executing the "run-tests.sh"
script, or interactively by 'source'ing the "tests-functions.sh" file 
and then directly executing functions dealing with the various objects.

When started, then the test system first reads a configuration file 
"maczfs-tests.conf" from the current directory and initializes the test
system.  This includes:

 - setting "diskstore" to an empty directory
 - setting "TMPDIR" to a new empty directory
 - initializing its own fast random number generator





# End
