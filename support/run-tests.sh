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
conf=maczfs-tests.conf
if [ "${1:-}" == "-C" ] ; then
    conf="${2:-}"
    if [ ! -f "${conf}" ] ; then
        echo "Config file '${conf}' not readable."
        exit 1
    fi
elif [ "${1:-}" == "--help" ] ; then
    echo "$0 [ -C conf-file ] "
    exit 1
fi

if [ -f ${conf} ] ; then
    source ${conf}
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

tests_func_init_done=1

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

run_ret 0 "Create zpool ${pool1} with vdev vd1 at ${vd1_disk}s2" make_pool p1 vd1:2
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

echo "Waiting 5 secs for Spotlight & Co to move on"
sleep 5
run_ret 0 "Unmounting using zfs utility" zfs umount ${pool1}
run_check_regex 0 "Verifying unmount" '-n' "${pool1}" mount

run_ret 0 "Exporting pool '${pool1}'" zpool export ${pool1}
run_check_regex 0 "Verifying export" '-n' "${pool1}" zpool list

run_ret 0 "Importing pool '${pool1}'" zpool import ${pool1}
run_check_regex 0 "Verifying import" "${pool1}" mount

run_ret 0 "Exporting pool '${pool1}' withou prior unmount" zpool export ${pool1}
run_check_regex 0 "Verifying export" '-n' "${pool1}" zpool list

run_ret 0 "Reimporting pool '${pool1}'" zpool import ${pool1}
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
run_ret 0 -t 2 "Copying file to pool fs" copy_file tf0 p1 tf1

run_cmd_log -t 0 get_file_stats stat_tf1_b tf1
run_cmd_log -t 1 get_fs_stats stat_p1_b p1
diff_fs_stats stat_p1_diff1  stat_p1_a  stat_p1_b
run_ret_start 0 -t 2 "verify space accounting" check_sizes_fs  stat_p1_diff1  8m  
run_ret_end 0 "checking file sizes" check_sizes_file  stat_tf1_b  8m

# - enable compression
run_ret 0 "Enabling compression" zfs set compression=on ${pool1}

# - write same file under new name "tf2" again
#   - verify it got compressed
#   - verify du, df, ls and stat return sensible values
#   - verify content of uncompressed file

run_cmd_log -t 0 get_fs_stats stat_p1_tf2_a  p1
run_ret_start 0 -t 1 "Writing same 8m file, then checking compression" copy_file tf1 p1 tf2
calc_comp_fact tf0
run_cmd_log -t 2 get_file_stats stat_tf2 tf2
print_file_stats  stat_tf2
run_ret_next 0 -t 3 "verifying file size" check_sizes_file -c ${file_tf0_compfact}  stat_tf2  8m
run_cmd_log -t 4 get_fs_stats stat_p1_tf2_b  p1
diff_fs_stats  stat_p1_tf2_diff1  stat_p1_tf2_a  stat_p1_tf2_b
run_ret_next 0 -t 5 "verifying fs size" check_sizes_fs -c ${file_tf0_compfact}  stat_p1_tf2_diff1 8m 
run_ret_next 0 "comparing content of uncompressed file"  cmp ${file_tf0_path} ${file_tf1_path}
run_ret_end 0 "comparing content of compressed file" cmp ${file_tf0_path} ${file_tf2_path}

# - create snapshot "sn1"
# - set copies = 2
# - write same file again as "tf3"
#   - verify space accounting
#   - verify du, df, ls and stat return sensible values

run_ret 0 "Creating snapshot sn1"  zfs snapshot -r  ${pool1}@sn1
run_check_regex 0 "Verifying snapshot is present"  "${pool1}@sn1" zfs list -t snapshot

run_ret 0 "Seting copies property to 2" zfs set copies=2 ${pool1}
run_check_regex 0 "Verifying copies property"  "2" zfs get copies ${pool1}

run_cmd_log -t 0 get_fs_stats stat_p1_tf3_a  p1
run_ret_start 0 "Writing same 8m file again, as tf3" copy_file tf0 p1 tf3
run_cmd_log -t 2 get_fs_stats stat_p1_tf3_b  p1
diff_fs_stats  stat_p1_tf3_diff1  stat_p1_tf3_a  stat_p1_tf3_b
print_fs_stats stat_p1_tf3_diff1
run_ret_next 0 -t 3 "verifying fs size" check_sizes_fs -c ${file_tf0_compfact}  stat_p1_tf3_diff1 8m 
run_cmd_log -t 4 get_file_stats stat_tf3 tf3
print_file_stats  stat_tf3
run_ret_end 0 -t 5 "verifying file size" check_sizes_file -c ${file_tf0_compfact}  stat_tf3  8m


# - create snapshot "sn2"
run_ret 0 "Creating snapshot sn2"  zfs snapshot -r  ${pool1}@sn2
run_check_regex 0 "Verifying snapshot is present"  "${pool1}@sn2" zfs list -t snapshot


# - disable compression
#   - verify content of compressed file
run_ret 0 "Disabling compression" zfs set compression=off ${pool1}
run_ret 0 "comparing content of compressed file" cmp ${file_tf0_path} ${file_tf2_path}


# - create dump of "sn1" (zfs send)
stream1fifo=$(new_fifo)
stream1=$(new_temp_file)
cat ${stream1fifo} >${stream1} &
run_ret 0 "creating dump of snapshot sn1 ..."  zfs send ${pool1}@sn1 >${stream1fifo}


# - delete "tf3"
#   - verify space accounting
run_cmd_log -t 0 get_fs_stats stat_p1_tf3_c  p1
run_ret_start 0 "Removing tf3"  remove_file tf3
run_cmd_log -t 2 get_fs_stats stat_p1_tf3_d  p1
diff_fs_stats  stat_p1_tf3_diff2  stat_p1_tf3_c  stat_p1_tf3_d
print_fs_stats stat_p1_tf3_diff2
run_ret_end 0 -t 3 "verifying fs size" check_sizes_fs -c ${file_tf0_compfact}  stat_p1_tf3_diff2 -8m 


# - create snapshot "sn3"
run_ret 0 "Creating snapshot sn3"  zfs snapshot -r  ${pool1}@sn3
run_check_regex 0 "Verifying snapshot is present"  "${pool1}@sn3" zfs list -t snapshot


# - create incremental dump of "sn3" against "sn2"
stream2fifo=$(new_fifo)
stream2=$(new_temp_file)
cat ${stream2fifo} >${stream2} &
run_ret 0 "creating dump of snapshot sn3 against sn2 ..."  zfs send -i ${pool1}@sn2 ${pool1}@sn3 >${stream2fifo}


# - delete "tf1"
#   - verify space accounting
run_cmd_log -t 0 get_fs_stats stat_p1_tf1_c  p1
run_ret_start 0 "Removing tf1"  remove_file tf1
run_cmd_log -t 2 get_fs_stats stat_p1_tf1_d  p1
diff_fs_stats  stat_p1_tf1_diff2  stat_p1_tf1_c  stat_p1_tf1_d
print_fs_stats stat_p1_tf1_diff2
run_ret_end 0 -t 3 "verifying fs size" check_sizes_fs stat_p1_tf1_diff2 -8m 


# - create incremental dump of "sn2" against "sn1"
stream3fifo=$(new_fifo)
stream3=$(new_temp_file)
cat ${stream3fifo} >${stream3} &
run_ret 0 "creating dump of snapshot sn2 against sn1 ..."  zfs send -i ${pool1}@sn1 ${pool1}@sn2 >${stream3fifo}


# - destroy "sn2"
#   - verify space accounting
run_cmd_log -t 0 get_fs_stats stat_p1_sn2_a  p1
run_ret_start 0 "Destroying snapshot sn2" zfs destroy ${pool1}@sn2
run_cmd_log -t 2 get_fs_stats stat_p1_sn2_b  p1
diff_fs_stats  stat_p1_sn2_diff1  stat_p1_sn2_a  stat_p1_sn2_b
print_fs_stats stat_p1_sn2_diff1
run_ret_end 0 -t 3 "verifying fs size" check_sizes_fs stat_p1_tf1_diff2 -8m 

# - unmount
# - rollback to "sn3"
# - mount
#   - verify file content
#   - verify space accounting
run_cmd_log -t 0 get_fs_stats stat_p1_rb_a  p1

run_ret 0 "Unmounting using diskutil"  diskutil umount ${pool1path}
run_check_regex 0 "Verifying unmount" '-n' "${pool1}" mount

run_ret_start 0 "Rolling back to sn3"  zfs rollback ${pool1}@sn3
run_ret_end 0 "Mounting reseted pool"  zfs mount ${pool1}

run_cmd_log -t 0 get_fs_stats stat_p1_rb_b  p1
diff_fs_stats  stat_p1_rb_diff1  stat_p1_rb_a  stat_p1_rb_b
print_fs_stats stat_p1_rb_diff1

run_ret 0 "Verifying tf1 has re-appeared and unchanged contents"  cmp ${file_tf0_path}  ${file_tf1_path}


#
# - add second device in stripe mode (sparsebundle, band-size 2MB) as "vd2"

run_ret 0 "Create disk vd2" make_disk 5 vd2 2
attach_disk vd2
run_ret 0 "Adding new vdev in stripe mode"  zpool add ${pool1} ${disk_vd2_disk}s2


# - write 64 small, random files in a 4x4 directory hierarchy, using
#   file and directory names with 8-127 character long names and file
#   content length between 3 and 11 kB.

dirtestdirs[0]=dirtest1
run_ret_start 0 "Creating 64 random files in 4x4 directories ..." mkdir -v ${pool1path}/${dirtestdirs[0]}
for ((ii1=1; ii1 < 5; ii1++)) ; do
    dirtestdirs[$(($ii1*5*5))]=${dirtestdirs[0]}/$(make_name 8 127)
    run_ret_next 0 "Building directory" mkdir -v ${pool1path}/${dirtestdirs[$(($ii1*5*5))]}
    for ((ii2=1; ii2 < 5; ii2++)) ; do
        dirtestdirs[$(($ii1*5*5 + $ii2*5))]=${dirtestdirs[$(($ii1*5*5))]}/$(make_name 8 127)
        run_ret_next 0 "Building directory" mkdir -v ${pool1path}/${dirtestdirs[$(($ii1*5*5 + $ii2*5))]}
        for ((ii3=1; ii3 < 5; ii3++)) ; do
            dirtestdirs[$(($ii1*5*5 + $ii2*5 + $ii3))]=${dirtestdirs[$(($ii1*5*5 + $ii2*5))]}/$(make_name 8 127)
            run_ret_next 0 "Making file" make_file $(get_rand_number 3 11)k p1 ${dirtestdirs[$(($ii1*5*5 + $ii2*5 + $ii3))]}
        done
    done
done
run_ret_end 0 "Done creating 64 files"  true


# - scrub pool
run_ret 0 "Starting scrub"  zpool scrub ${pool1}

echo "waiting for scrub to complete ..."
while sleep 5 ; do
    if zpool status ${pool1} | grep -e "complet" -e "finish" >/dev/null ; then
        break;
    fi
done

run_ret 0 "Checking pool status" zpool status -v ${pool1}


# - destory 75% of added device "vd2" (write random data)
# - scrub pool, verifying that copies have been placed on different disks.
run_ret 0 "Damaging 75% of data in disk vd2" damage_disk 75 vd2

run_ret 0 "Starting scrub"  zpool scrub ${pool1}

echo "waiting for scrub to complete ..."
while sleep 5 ; do
    if zpool status ${pool1} | grep -e "complet" -e "finish" >/dev/null ; then
        break;
    fi
done

run_ret 0 "Checking pool status" zpool status -v ${pool1}


# - replace 2nd drive with file-based vdev "vd3"
run_ret_start 0 "Replacing vd2: making new file-vdev"  make_file 1m _temp_ vd3file
dd if=/dev/zero of=${file_vd3file_path} bs=$((1024*1024)) count=$((1024*3))
run_ret_end 0 "Initiating disk replacement"  zpool replace ${pool1} ${disk_vd2_disk}s2 ${file_vd3file_path}


# - wait until resilver is complete
echo "waiting for replacement to complete ..."
while sleep 5 ; do
    if zpool status ${pool1} | grep -e "complet" -e "finish" >/dev/null ; then
        break;
    fi
done

run_ret 0 "Checking pool status" zpool status -v ${pool1}


# - make first vdev "vd1" into mirror, adding disk-based vdev "vd4"
run_ret 0 "Creating new disk vd4" make_disk 5 vd4 8
attach_disk vd4
run_ret 0 "Attaching to vd1, making a mirror"  zpool attach ${pool1} ${disk_vd1_disk}s2 ${disk_vd4_disk}s2

# - force-export while resilver is running
sleep 1
run_ret 0 "Force-exporting" zpool export -f ${pool1}
run_check_regex 0 "Verifying export" '-n' "${pool1}" zpool list

# - import
#   - verify resilver continues
#   - wait until resilver completes
run_ret 0 "re-import pool"  zpool import ${pool1}
run_check_regex 0 "Verifying it is resilvering" "resilver" zpool status ${pool1}

# - wait until resilver is complete
echo "waiting for resilver to complete ..."
while sleep 5 ; do
    if zpool status ${pool1} | grep -e "complet" -e "finish" >/dev/null ; then
        break;
    fi
done

run_ret 0 "Checking pool status" zpool status -v ${pool1}


# - destroy 15% of original device "vd1"
run_ret 0 "Destroying 15% of vd1" damage_disk 15 vd1


# - read "tf1" to "tf3" until zpool status shows errors
dd if=${file_tf1_path}  of=/dev/null
dd if=${file_tf3_path}  of=/dev/null
run_ret 0 "Checking pool status after read from damaged device" zpool status -v

 
# - create snapshot "sn4"
run_ret 0 "Creating snapshot sn4" zfs snapshot ${pool1}@sn4
run_check_regex 0 "Verifying snapshot is present"  "${pool1}@sn4" zfs list -t snapshot


# - create set of 16 random files in one directory, file content length
#   between 3 and 11 kB
filetestfiles[0]=filetest1
run_ret_start 0 "Creating 16 random files in 1directory ..." mkdir -v ${pool1path}/${filetestfiles[0]}
for ((ii1=1; ii1 < 17; ii1++)) ; do
    filetestfiles[$ii1]=${filetestfiles[0]}/$(make_name 8 127)
    run_ret_next 0 "Making file" make_file $(get_rand_number 3 11)k p1 ${filetestfiles[$ii1]}
done
run_ret_end 0 "Done creating 16 files"  true


# - make 2nd vdev "vd3" into mirror, adding disk-based vdev "vd5"
#   - verify resilver has started
run_ret 0 "Creating new disk vd5" make_disk 4 vd5 8
attach_disk vd5
run_ret 0 "Attaching to vd3, making a mirror"  zpool attach ${pool1} ${file_vd3file_path} ${disk_vd5_disk}s2
run_check_regex 0 "Verifying it is resilvering" "resilver" zpool status ${pool1}

# - create snapshot "sn5"
run_ret 0 "Creating snapshot sn5" zfs snapshot ${pool1}@sn5
run_check_regex 0 "Verifying snapshot is present"  "${pool1}@sn5" zfs list -t snapshot


# - dump snapshot "sn4" incremental against "sn3"
stream4fifo=$(new_fifo)
stream4=$(new_temp_file)
cat ${stream4fifo} >${stream4} &
run_ret 0 "creating dump of snapshot sn4 against sn3 ..."  zfs send -i ${pool1}@sn3 ${pool1}@sn4 >${stream4fifo}


# - replace 1st vdev "vd1" with new disk-based vdev "vd6"
#   - wait until all resilvering has been completed
#   - pool config now: mirror "vd6" "vd4" mirror "vd3" "vd5"
#

run_ret 0 "Creating new disk vd6" make_disk 5 vd6 8
attach_disk vd6
run_ret 0 "Replacing vd1 with vd6"  zpool replace ${pool1} ${disk_vd1_disk}s2 ${disk_vd6_disk}s2
run_check_regex 0 "Verifying it is resilvering" "resilver" zpool status ${pool1}

echo "waiting for resilver to complete ..."
while sleep 5 ; do
    if zpool status ${pool1} | grep -e "complet" -e "finish" >/dev/null ; then
        break;
    fi
done

run_ret 0 "Checking pool status" zpool status -v ${pool1}



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
