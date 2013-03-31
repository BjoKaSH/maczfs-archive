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
file_<id>_fs   : ZFS file system where the file is stored, empty if not
                 on a ZFS file system managed by the test system
file_<id>_name : original file name, serves as a handle, can be
                 structured as a file path, but does not necessary
                 denote a real file path.
file_<id>_relpath : path to file, relative to the ZFS file system fs or
                 relative to "/" if not on a test system managed ZFS
                 file system
file_<id>_path : full path to file, starting at "/"
file_<id>_compfact : standart gzip compression factor
file_<id>_idx  : numeric index into files array for this file.
file_<id>_ghost : file deleted from visible file system, but present in
                  some snapshots.


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


Two functions simplify access to these meta data varables: get_val() 
and print_object():

 - get_val prefix id postfix [ intro ... ]
   Print content of the variable "${prefix}_${id}_${postfix}" to stdout.
   If "intro" is not the empty string, then it is prefixed to the 
   content of the printed variable.

 - print_object object-type id attribute [ ... ]
   Print all listed attributes of the given object.  This prints the 
   variables "${object-type}_${id}_${attribute}", "${object-type}_${id}_${...}" ...

 
Command execution
=================

A major purpose of the system is, to run commands under controlled 
conditions and to capture and compare their output against expected 
values.  Running command, capturing output (stderr and stdout) and 
searching the captured output for defined patterns is implemented in a 
number of run_... functions.  These are build on top of each other with 
run_cmd being the workhorse and many convenient variants build around 
it.  The following functions are defined:

 - run_cmd  [ --outname tmpfile | --outarray varname ] [ --errname tmpfile | --errarray varname ] command [ args ... ]
   Run a command and optionally capture stdout and/or stderr into files 
   or arrays

 - print_count_ok_fail
   Internal support function, used to implement some of the run_... 
   functions.

 - print_run_cmd_logs
   Internal support function, used to implement some of the run_... 
   functions.

 - run_cmd_log  [ -t subtest ] command [ args .. ]
   (uses run_cmd)
   Run then given command and log the command and any output generated 
   on stderr and stdout to ${tests_logdir}/test_${curtest}.X where X is 
   "cmd", "out" or "err", respectively.  If "-t subtest" is given, then 
   logs are written to ${tests_logdir}/test_${curtest}.${subtest}.X instead.
   If "-t subtest" is not given, or if "subtest" is 1, then the value of 
   ${curtest} is increment before constructing the log file names.  The
   subtest number is one-based, i.e. the value 0 is not allowed.

 - run_ret  expected_retval [ -t subtest ] message command [ args ]
   (uses run_cmd or run_cmd_log (depending on message and subtest being 
   empty or not))
   Run given command, compare return value and print a success or failure
   message, depending on (mis)match of expected and actual return value.
   The success or failure message is only printed, if the message parameter
   is not the empty string.  The given command, its arguments, as well 
   as the generated output to stdout and stderr are logged to 
   ${tests_logdir}/test_${curtest}.X where X is "cmd", "out" or "err". 
   Logging is not performed if message and subtest are both the empty 
   string.
   This function returns zero, if the command's return value matches
   expected_retval, else it returns 1.  If -t subtest is given, then the
   log names are changed to ${tests_logdir}/test_${curtest}.${subtest}.X 
   with X as given above.
 
 - run_abort  expected_retval command [ args ... ]
   (uses run_cmd)
   Does the same as run_ret, except that the test suite is aborted if 
   the commands return value does not match the expected value.  Always
   returns zero. 

 - run_check_regex  expected_retval message [ '-n' ] regex command [ args ... ]
   (uses run_cmd_log)
   Does the same as run_ret, but compares the command's stdout to the 
   given regular expression "regex".  Returns zero if (a) the expression 
   matches the generated output (using substring search) and the optional
   parameter "-n" is not given, or if (b) it does not match and "-n" is 
   present.  In all other cases return 1, including in all cases where 
   the original command's return code does not match the expected return
   code expected_retval.

 - run_ret_start  expected_retval [ -t subtest ] message command [ args ]

 - run_ret_next  expected_retval [ -t subtest ] message command [ args ]

 - run_ret_end  expected_retval [ -t subtest ] message command [ args ]

All functions that log the command execution use an auto-generated log 
file name of "test_${curtest}.X" where the X is one out of "cmd", "out" 
and "err".  The variable "curtest" is a counter starting at 1 and 
incremented every time a command is run.  All commands that (auto)detect 
success or failure (currently run_ret and run_check_regex) also increment
either the value of "okcnt" or "failcnt", depending on success or failure
of the command executed.

Several of these function take a parameter "-t subtest".  This parameter
changes the default log file names by adding an additional counter 
"subtest", resulting in "test_${curtest}.${subtest}.X" as log file name.
Additional, if the "subtest" parameter is non-zero, then curtest is not
incremented, while the okcnt and failcnt variables are always updated 
(independent of the value of subtest).

The function run_ret_start, ..._next and ..._end support aggregation of
several commands into one single test case with exactly one update of 
okcnt and failcnt, triggered by running run_ret_end.  Apart from not 
updating okcnt and failcnt for intermediated commands, these function 
behave like run_ret and take the same arguments.  All three functions do
not require the subtest parameter and default to "1" for run_ret_start
and the last used subtest value + 1 for run_ret_next and run_ret_end. 
For this, an internal counter variable "subtest" is used.


Other support functions
=======================

Several functions are provided to simplify common tasks like creating 
temporary files and directories or to perform common zfs tasks like 
creating pools, setting or getting properties.

 - new_temp_file [ -p base ]
   create a new, empty file in the default temporary files directory.  
   The file name (including full path) is echoed to stdout. 
   If "-p base" is given, then the new file is created in the directory 
   "base", which must be an existing, absolute path.  In this case, only
   the basename (filename without path) is echoed to stdout.
   

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
