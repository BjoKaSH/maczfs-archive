#! /bin/bash

set -x -v
export LC_ALL=C 

# load configuration, if present
#
# set defaults
poolbase=pool_$(date +%s)_$$
has_fstest=0
genrand_bin=./support/genrand
#
# check for local config file
if [ -f maczfs-tests.conf] ; then
    source maczfs-test.conf
    # make sure diskstore is set, otherwise bad things will happen
    if [ ! -d "${diskstore}" ] ; then
	echo "diskstore not set. Abort."
	exit 1
    fi
else
    diskstore=$(mktemp -d -t diskstore_)
fi

stop_on_fail=1

if [ ! -z "${tests_tmpdir}" ] ; then
    export TMPDIR=${tests_tmpdir}
else
    tests_tmpdir=$(mktemp -d -t tests_maczfs_)
    export TMPDIR=${tests_tmpdir}
fi

if [ -z "${tests_logdir}" ] ; then
    tests_logdir=$(mktemp -d -t test_logs_maczfs_)
fi

if [ ! -x "${genrand_bin}" ] ; then
    echo "Error: random number generator '' not found."
    echo "Did you compiled it? ('gcc -o genrand -O3 genrand.c' in the support folder.)"
fi

# initialize random datas generator
genrand_state=${tests_logdir}/randstate.txt
${genrand_bin} -s 13446 -S ${genrand_state}


# load various helper functions
source ./support/tests-functions.sh

# Test sequence:
# - create single-disk pool in default config, using disk-based vdev "vd1"
#   - verify it auto mounts
#   - verify it can be ejected with diskutil
#   - verify it can be re-mounted
#   - verify it can be exported
#   - verify it can be reimported and auto-mounts

cleanup=0
failcnt=0
okcnt=0
tottests=0
curtest=0

if [ ${has_fstest} -eq 1 ] ; then
    tottests=$(($tottest+1))
fi

run_abort 0 mkdir ${diskstore}/dev

run_ret 0 "Create disk vd1" make_disk 5 vd1 8
attach_disk vd1
#run_ret 0 "Partition disk vd1" partion_disk vd1

run_ret 0 "Create zpool ${pool1} with vdev vd1 at ${vd1_disk}s2" make_pool p1 ${vd1_disk}s2
pool1=${pool_p1_fullname}
pool1path=${pool_p1_path}

run_check_regex 0 "Checking it auto-mounted" "${pool1}" mount

run_ret 0 "Unmount using diskutil" diskutil umount ${pool1path}
run_check_regex 0 "Verifying unmount" '-n' "${pool1}" mount

run_ret 0 "Remounting using zfs utility" zfs mount ${pool1}
run_check_regex 0 "Verifying mount" "${pool1}" mount

sleep 2
echo "Turning of indexing on test pool(s)"
mdutil -i off /Volumes/${pool1}

sleep 5
run_ret 0 "Unmounting using zfs utility" zfs umount ${pool1}
run_check_regex 0 "Verifying unmount" '-n' "${pool1}" mount

run_ret 0 "Exporting pool '${pool1}'" zpool export ${pool1}
run_check_regex 0 "Verifying export" '-n' "${pool1}" zpool list

run_ret 0 "Importing pool '${pool1}'" zpool import ${pool1}
run_check_regex 0 "Verifying import" "${pool1}" mount


# - run fstest in subdir of pool

if [ ${has_fstest} -eq 1 ] ; then
    echo "Running fstest suite ..."
    ((curtest++))
    mkdir ${pool1path}/fstest
    pushd ${pool1path}/fstest
    run_ret 0 "" run-fstest.sh
    res=$?
    popd
    echo -n "Completed fstest suite"
    print_count_ok_fail ${res}
fi


# - create large (>8 MB), compressible (factor > 2) file as "tf1"
#   - verify space accounting

run_cmd_log -t 0 get_fs_stats stat_p1_a p1
run_ret 0 -t 1 "Creating 8m file (random, compressible)" make_file -c 2 8m _temp_ tf0
run_ret 0 -t 2 "" copy_file tf0 p1 tf1

run_cmd_log -t 0 get_file_stats stat_tf1_b tf1
run_cmd_log -t 1 get_fs_stats stat_p1_b p1
diff_fs_stats stat_p1_diff1  stat_p1_a  stat_p1_b
run_ret_start 0 -t 2 "verify space accounting" check_sizes_fs  stat_p1_diff1  8m  
run_ret_end 0 check_sizes_file  stat_tf1_b  8m

# - enable compression
run_ret 0 "Enabling compression" zfs set compression=on ${pool1}

# - write same file under new name "tf2" again
#   - verify it got compressed
#   - verify du, df, ls and stat return sensible values
#   - verify content of uncompressed file

run_cmd_log -t 0 get_fs_stats stat_p1_tf2_a  p1
run_ret_start 0 -t 1 "Writing same 8m file, then checking compression" copy_file tf1 tf2
calc_comp_fact tf0
run_cmd_log -t 2 get_file_stats stat_tf2 tf2
run_ret_next 0 -t 3 "verifying file size" check_sizes_file -c ${file_tf2_compfact}  stat_tf1_b  8m
run_cmd_log -t 4 get_fs_stats stat_p1_tf2_b  p1
diff_fs_stats  stat_p1_tf2_diff1  stat_p1_tf2_a  stat_p1_tf2_b
run_ret_next 0 -t 5 "verifying fs size" check_sizes_fs -c ${file_tf2_compfact}  stat_p1_tf2_diff 8m 
run_ret_next 0 "comparing content of uncompressed file"  cmp ${file_tf0_path} ${file_tf1_path}
run_ret_end 0 "comparing content of compressed file" cmp ${file_tf0_path} ${file_tf2_path}

# - create snapshot "sn1"
# - set copies = 2
# - write same file again as "tf3"
#   - verify space accounting
#   - verify du, df, ls and stat return sensible values
# - create snapshot "sn2"
# - disable compression
#   - verify content of compressed file
# - create dump of "sn1" (zfs send)
# - delete "tf3"
#   - verify space accounting
# - create snapshot "sn3"
# - create incremental dump of "sn3" against "sn2"
# - delete "tf1"
#   - verify space accounting
# - create incremental dump of "sn2" against "sn1"
# - destroy "sn2"
#   - verify space accounting
# - unmount
# - rollback to "sn3"
# - mount
#   - verify file content
#   - verify space accounting
#
# - add second device in stripe mode (sparsebundle, band-size 2MB) as "vd2"
# - write 64 small, random files in a 4x4 directory hierarchy, using
#   file and directory names with 8-127 character long names and file
#   content length between 3 and 11 kB.
# - scrub pool
# - destory 75% of added device "vd2" (write random data)
# - scrub pool, verifying that copies have been placed on different disks.
# - replace 2nd drive with file-based vdev "vd3"
# - wait until resilver is complete
# - make first vdev "vd1" into mirror, adding disk-based vdev "vd4"
# - force-export while resilver is running
# - import
#   - verify resilver continues
#   - wait until resilver completes
# - destroy 15% of original device "vd1"
# - read "tf1" to "tf3" until zpool status shows errors
# - create snapshot "sn4"
# - create set of 16 random files in one directory, file content length
#   between 3 and 11 kB
# - make 2nd vdev "vd3" into mirror, adding disk-based vdev "vd5"
#   - verify resilver has started
# - create snapshot "sn5"
# - dump snapshot "sn4" incremental against "sn3"
# - replace 1st vdev "vd1" with new disk-based vdev "vd6"
#   - wait until all resilvering has been completed
#   - pool config now: mirror "vd6" "vd4" mirror "vd3" "vd5"
#
# - create sub-fs "fs11" with copies = 1
# - create set of 16 random files in "fs11", file content length
#   between 3 and 11 kB
#   - verify space accounting
# - create snapshot "sn6"
# - delete 8 of the files in "fs11"
# - create snapshot "sn7"
# - clone snapshot "sn6" as "cl1"
# - verify file content in "cl1"
# - create set of 4 additional files in "cl1" ind directory "cl1/d1"
# - verify space accounting
# - delete 2 files in "cl1/d1" and 2 in "cl1"
# - verify space accounting
# - create snapshot "sn8"
# - dump snapshot "sn5" incremental against "sn4"
# - dump snapshot "sn6" incremental against "sn5"
# - dump snapshot "sn7" incremental against "sn6"
# - dump snapshot "sn8" incremental against "sn7"
# - destroy clone "cl1"
# - unmount
# - destroy "sn8"
# - destroy "sn7"
# - rollback to "sn6"
# - mount
# - create snapshot "sn9"
#
# - run "manyfs" test (adapted from Alex' version)
# - create snapshot "sn10"
# - dump snapshot "sn8" incremental against "sn6"
#
# - create new pool "p2" on "vd1"
# - receive snapshots "sn1" to "sn4", one by one
#   - after each receive, verify files
#   - after each receive, verify space accounting
# - add vdev "vd2" to pool "p2" in stripe mode
# - receive snapshots "sn1" to "sn4", one by one
#   - after each receive, verify files
#   - after each receive, verify space accounting
#
# - destroy pool "p2"
# - destroy pool "p1"
# - try to unload kext.
#
# Done

# End
