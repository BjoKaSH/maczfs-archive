#! / bin/bash

### list of functions ###
#
# make_disk size_in_gb name [ band size ]
# globals: ${name}_attached, ${name}_disk, ${name}_size, ${name}_path
#
# new_temp_file [ -p ]
# stdout: filename, with path if "-p" given.
#
# make_pool poolname [ -o option=value [ -o ... ] ] vdevs ...
# retval: return code of zpool create
# globals: pool_${poolname}_opt, pool_${poolname}_path, pool_${poolname}_vdevs, pool_${poolname}_fullname
#
# make_fs fsname [ -o option=value [ -o ... ] ]
# globals: pool_${fsname_tr}_opt=, pool_${fsname_tr}_path, pool_${fsname_tr}_name, pool_${fsname_tr}_fullname
#
# make_file [ -c comp_factor ] size pool file
# globals: file_${file}_size, file_${file}_pool, file_${file}_path, file_${file}_name
#
# run_cmd [ --outname tmpfile | --outarray varname ] [ --errname tmpfile | --errarray varname ] command [ args ... ]
# retval: return code of executed command
#
# attach_disk diskname
# globals: ${diskname}_attached, ${diskname}_disk
#
# detach_disk diskname
# globals: ${diskname}_attached, ${diskname}_disk
#
# partion_disk diskname
# globals: ${diskname}_attached, ${diskname}_disk
#
# run_ret expected_retval comment cammand [ args ... ]
# return: 0 or 1
# globals: last_cmd_retval


# create a new disk image
# args:
# size_in_gb disk_name [ band size ]
# globals:
# ${name}_attached # 1 if attached, else 0
# ${name}_disk     # device name of disk if attached, else '' 
# ${name}_size     # size in GB
# ${name}_path     # path to sparse bundle directory
function make_disk() {
    local size=$1
    local name=$2

    if [ -e ${diskstore}/${name}.sparsebundle ] ; then
        echo "error, image path exists."
        return 1
    fi

    if [ $# -eq 3 ] ; then
        # command with band size
        echo "Warning: specifying band size unsupported and ignored"
        hdiutil create -size ${size}g -layout GPTSPUD -partitionType ZFS -type SPARSEBUNDLE ${diskstore}/${name}.sparsebundle
    else
        # command w/o band size
        hdiutil create -size ${size}g -layout GPTSPUD -partitionType ZFS -type SPARSEBUNDLE ${diskstore}/${name}.sparsebundle
    fi

    eval ${name}_attached=0
    eval ${name}_disk=\'\'
    eval ${name}_size=${size}
    eval ${name}_path=\"${diskstore}/${name}.sparsebundle\"
}


# create temporary file
#
# creates a new temporary file in the default location and returns
# the file with full path.  If called with "-p base", then create
# file in base and return only the relative path name.
# args:
# [ -p base ]
# -p : create file in path base
function new_temp_file() {
    local tmp=""
    local base=""
    local res=0

    if [ -z "${1:-}" ] ; then
        tmp=$(mktemp -t mzt.XXXXXX)
    else
        shift
        base="$2"
        shift
        tmp=$(mktemp ${base}/mzt.XXXXXX)
    fi
    res=$?

    if [ -z "${base}" ] ; then
        echo ${tmp}
    else
        basename ${tmp}
    fi

    return ${res}
}


# create named zfs pool
# args:
# poolname [ -o option=value [ -o ... ] ] vdevs ...
# globals:
# pool_${poolname}_opt=...   : options used
# pool_${poolname}_fullname= : pool name with pool prefix
# pool_${poolname}_path=     : full path to pool filesystem
# pool_${poolname}_vdevs=... : vdev specification used
# poolbase : prefix for all pools.
function make_pool() {
    local opt=""
    local poolpath=""
    local poolname="${1}"
    local poolfullname="${poolbase}_${poolname}"

    shift
    while [ "$1" == "-o" ] ; do
        shift
        opt="${opt} $1"
        shift
    done
    eval pool_${poolname}_opt="\"\${opt}\""
    eval pool_${poolname}_fullname="\"\${poolfullname}\""
    eval pool_${poolname}_path="\"/Volumes/\${poolfullname}\""
    eval pool_${poolname}_vdevs="\"\$*\""

    zpool create ${opt} ${poolname} $*
}


# create named zfs filesystem
# args:
# fsname [ -o option=value [ -o ... ] ]
# globals:
# (fsname_tr is fsname, but with "/" mapped to "_")
# pool_${fsname_tr}_opt=...  : options used
# pool_${fsname_tr}_path=    : full path to zfs filesystem
# pool_${fsname_tr}_name=... : original file system name ${fsname}
# pool_${fsname_tr}_fullname= : zfs filesystem name with full pool prefix
function make_fs() {
    local opt=""
    local fspath=""
    local fsname="${1}"
    local fsname_tr="${fsname//\//_}"
    local fsfullname=""

    # if fsname and fsname_tr are identical, then we have only the pool fs itself, which is forbidden.
    if [ "${fsname}" == "${fsname_tr}" ] ; then
        echo "Error: make_fs() requires at least one "/" in the fs name"
        return 1
    fi
    fsfullname=${poolbase}_${fsname}

    shift
    while [ "$1" == "-o" ] ; do
        shift
        opt="${opt} $1"
        shift
    done
    eval pool_${fsname_tr}_opt="\"\${opt}\""
    eval pool_${fsname_tr}_name="\"\${fsname}\""
    eval pool_${fsname_tr}_fullname="\"\${fsfullname}\""
    eval pool_${fsname_tr}_path="\"/Volumes/\${poolfullname}\""

    zfs create ${opt} ${fsname}
}


# create a (temporary) file of given size
# args:
# [ -c comp_factor ] size pool file
# -c comp_factor : try to make the file contents compressible by factor comp_factor
# size  : size of file in bytes, optionaly with multiplier "m" or "k", example: 8m
# pool  : zfs filesystem to place file in.  if special name _temp_ is used, then place file in ${TMPDIR}
# file  : filename (optionally with path prefix) relative to zfs filesystem
# globals:
# file_${file}_size = size of file
# file_${file}_pool = zfs filessystem
# file_${file}_name = original file name
# file_${file}_path = full path to file, starting at "/"
# pool_${pool}_path : path to zfs filesystem
function make_file() {
    local filename=""
    local filename_tr=""
    local size=""
    local pool=""
    local filepath=""
    local compfact=0
    local count=0
    local sizeflag=""
    local poolpath_v=""

    if [ "${1}" == "-c" ] ; then
        shift
        compfact=${1}
        shift
    fi

    size=${1}
    pool=${2}
    filename=${3}
    filename_tr=${filename//\//_}
    
    if [ "${size: -1:1}" == "m" ] ; then
        # 1m bytes makes 1024*256 longs
        count=$((${size%m}*1024*256))
        size=$((${count*4}))
        sizeflag=-m
    elif [ "${size: -1:1}" == "k" ] ; then
        # 1k bytes makes 256 longs
        count=$((${size%k}*256))
        size=$((${count*4}))
        sizeflag=-m
    else
        # size is given in bytes
        count=${size}
        sizeflag=""
    fi

    if [ "${pool}" == "_temp_" ] ; then
        filepath=$(new_temp_file)
    else
        poolpath_v=pool_${pool//\//_}_path
        filepath=${!poolpath_v}/${filename}
    fi
    filedir=$(dirname ${filepath})
    if [ ! -e ${filedir} ] ; then
        mkdir -pv ${filedir}
    elif [ ! -d ${filedir} ] ; then
        echo "Error: file path is not a directory."
        return 1
    fi

    if [ ${compfact} -eq 0 ] ; then
        ${genrand_bin} -S ${genrand_state} -c ${count} ${sizeflag} -o >${filepath}
        res=$?
    else
        ${genrand_bin} -S ${genrand_state} -c ${count} ${sizeflag} -o -t >${filepath}
        res=$?
    fi
    
    if [ $res -eq 0 ] ; then
        eval file_${filename_tr}_size=${size}
        eval file_${filename_tr}_pool=${pool}
        eval file_${filename_tr}_name=${filename}
        eval file_${filename_tr}_path=${filepath}
    else
        echo "Error: generating file ${filepath} (${filename}) failed"
    fi
    
    return $res
}


# determine file statistics and store result in the array destvar as
# well as in individual variables ${destvar}_*
# args:
# destvar file
# destvar : name of an array, which will be set to the file statistics
#    the array will be index starting with 0 in the same order as the
#    variables listed under 'globals'.
# file : file name to use.  the actual path is read from
#    file_${file}_path, see make_file().
# globals:
# ${destvar}_name
# ${destvar}_path
# ${destvar}_mode
# ${destvar}_nlink
# ${destvar}_uid
# ${destvar}_gid
# ${destvar}_size
# ${destvar}_atime
# ${destvar}_mtime
# ${destvar}_ctime
# ${destvar}_blksize
# ${destvar}_blocks
function get_file_stats() {
    local destvar=$1
    local filename=$2
    local filepath_v=file_${filename//\//_}_path
    local filepath=${!filepath_v}

    if [ ! -e "${filepath}" ] ; then
        echo "Error: file '${filepath}' does not exists."
        return 1
    fi

    local st_dev
    local st_ino
    local st_mode
    local st_nlink
    local st_uid
    local st_gid
    local st_rdev
    local st_size
    local st_atime
    local st_mtime
    local st_ctime
    local st_birthtime
    local st_blksize
    local st_blocks
    local st_flags
    
    local i
    for i in $(stat -s ${filepath}) ; do
        eval $i
    done

    eval ${destvar}_name=${filename}
    eval ${destvar}_path=${filepath}

    local i2=0
    for i in mode nlink uid gid size atime mtime ctime blksize blocks ; do
        eval ${destvar}_${i}=\$\{st_${i}\}
        eval ${destvar}\[${i2}\]=\$\{st_${i}\}
        ((i2++))
    done
}


# determine zfs fs statistics
# args:
# destvar fs
# destvar : name of an array, which will be set to the file statistics
#    the array will be index starting with 0 in the same order as the
#    variables listed under 'globals'.
# fs : file name to use.  the actual path is read from
#    file_${file}_path, see make_file().
# globals:
# ${destvar}_pool   = derived from pool_${fs}_name
# ${destvar}_name   = copied from pool_${fs}_name
# ${destvar}_fullname = copied from pool_${fs}_fullname
# ${destvar}_path   = copied from pool_${fs}_path
# ${destvar}_size   = pool size, from zpool list
# ${destvar}_alloc  = allocated space in pool, from zpool list
# ${destvar}_free   = free space in pool, from zpool list
# ${destvar}_used   = allocate space in fs, from zfs list
# ${destvar}_avail  = free space in fs, from zfs list
# ${destvar}_ref    = refered  space in fs, from zfs list
# ${destvar}_comp   = compression ratio, zero if disabled
# ${destvar}_dfblocks = total blocks, from df -k
# ${destvar}_dffree = free space, from df -k
# ${destvar}_dfused = allocated space, from df -k
function get_fs_stats() {
    local destvar=$1
    local fs=$2
    local fs_tr=${fs//\//_}
    local pool=${fs%%/*}
    local tmp_v=pool_${fs_tr}_fullname
    local fullname=${!tmp_v}
    local poolfullname=${fullname%%/*}
    tmp_v=pool_${fs_tr}_path
    local path=${!tmp_v}
    local idx=0
    local tmp_res
    local idx2=0
    local i

    eval ${destvar}_pool=${pool}
    eval ${destvar}_name=${fs}
    eval ${destvar}_fullname=${fullname}
    eval ${destvar}_path=${path}

    for i in pool name fullname path ; do
        tmp_v=${destvar}_${i}
        eval ${destvar}\[${idx}\]=${!tmp_v}
        ((idx++))
    done

    tmp_res=($(LC_ALL=C zpool list ${poolfullname} | LC_ALL=C gawk "/${poolfullname}/"' {print $2 "\n" $3 "\n" $4 "\n";}') )

    for ((idx2=0; idx2 < 3; idx2++)) ;
        tmp_val=${tmp_res[$idx]}
        unit=${tmp_val: -1:1}
        if [ "${unit}" == "T" ] ; then
            tmp_val=$( echo "${tmp_val%T}*1024*1024" | bc)
        elif [ "${unit}" == "G" ] ; then
            tmp_val=$( echo "${tmp_val%G}*1024" | bc)
        elif [ "${unit}" == "K" ] ; then
            tmp_val=$( echo "${tmp_val%K}/1024" | bc)
        else
            tmp_val=${tmp_val%M}
        fi
        tmp_res[$idx]=${tmp_val}
    done

    idx2=0
    for i in size alloc free ; do
        eval ${destvar}_${i}=${tmp_res[${idx2}]}
        eval ${destvar}\[${idx}\]=${tmp_res[${idx2}]}
        ((idx++))
        ((idx2++))
    done

    tmp_res=($(zfs list ${fullname} | gawk "/${fullname}/"' {print $2 "\n" $3 "\n" $4 "\n";}') )
    if [ "$(zfs get compression ${fullname} | gawk "/${fullname}/"' {print $3;}')" == "on" ] ; then
        tmp_res[3]=$(zfs get compressratio ${fullname} | gawk "/${fullname}/"' {print $3;}')
    else
        tmp_res[3]=0
    fi

    for ((idx2=0; idx2 < 3; idx2++)) ;
        tmp_val=${tmp_res[$idx]}
        unit=${tmp_val: -1:1}
        if [ "${unit}" == "T" ] ; then
            tmp_val=$( echo "${tmp_val%T}*1024*1024" | bc)
        elif [ "${unit}" == "G" ] ; then
            tmp_val=$( echo "${tmp_val%G}*1024" | bc)
        elif [ "${unit}" == "K" ] ; then
            tmp_val=$( echo "${tmp_val%K}/1024" | bc)
        else
            tmp_val=${tmp_val%M}
        fi
        tmp_res[$idx]=${tmp_val}
    done

    idx2=0
    for i in used avail ref comp ; do
        eval ${destvar}_${i}=${tmp_res[${idx2}]}
        eval ${destvar}\[${idx}\]=${tmp_res[${idx2}]}
        ((idx++))
        ((idx2++))
    done

    tmp_res=($(df -k -P ${path} | gawk "/${fullname//\//\\/}/"' {print $2 "\n" $3 "\n" $4 "\n"}') )

    idx2=0
    for i in dfblocks dfused dffree; do
        eval ${destvar}_${i}=${tmp_res[${idx2}]}
        eval ${destvar}\[${idx}\]=${tmp_res[${idx2}]}
        ((idx++))
        ((idx2++))
    done
}


# compare two fs stats and save difference in new array
# args:
# diff_array  stats_1_array  stats_2_array
# globals:
# ${diff_array}_pool   = copied from stats_1_array
# ${diff_array}_name   = copied from stats_1_array
# ${diff_array}_fullname = copied from stats_1_array
# ${diff_array}_path   = copied from stats_1_array
# ${diff_array}_size   = stats_2_array - stats_1_array
# ${diff_array}_alloc  = stats_2_array - stats_1_array
# ${diff_array}_free   = stats_2_array - stats_1_array
# ${diff_array}_used   = stats_2_array - stats_1_array
# ${diff_array}_avail  = stats_2_array - stats_1_array
# ${diff_array}_ref    = stats_2_array - stats_1_array
# ${diff_array}_comp   = stats_2_array - stats_1_array
# ${diff_array}_dfblocks = stats_2_array - stats_1_array
# ${diff_array}_dfused = stats_2_array - stats_1_array
# ${diff_array}_dffree = stats_2_array - stats_1_array
#
function diff_fs_stats() {
    local destvar=$1
    local prevar=$2
    local postvar=$3
    local idx=0
    local i=0
    local i2=0
    local temp_v=""
    local preval
    local postval
    local diffval
    
    for i in pool name fullname path ; do
        temp_v=${prevar}_${i}
        preval=${!temp_v}
        temp_v=${postvar}_${i}
        postval=${!temp_v}
        eval ${destvar}_${i}=${preval}
        eval ${destvar}\[${idx}\]=${preval}
        ((idx++))
    done

    for i in size alloc free used avail ref comp ; do
        temp_v=${prevar}_${i}
        preval=${!temp_v}
        temp_v=${postvar}_${i}
        postval=${!temp_v}
        diffval=$(echo "${postval} - ${preval}" | bc)
        eval ${destvar}_${i}=${diffval}
        eval ${destvar}\[${idx}\]=${diffval}
        ((idx++))
    done

    for i in dfblocks dfused dffree ; do
        temp_v=${prevar}_${i}
        preval=${!temp_v}
        temp_v=${postvar}_${i}
        postval=${!temp_v}
        diffval=$((${postval} - ${preval}))
        eval ${destvar}_${i}=${diffval}
        eval ${destvar}\[${idx}\]=${diffval}
        ((idx++))
    done
}


# check if fs size change matches file creation / deletion.
# args:
# [ -c compfact ] diff_stat_array  size
# -c compfact : expected compression factor of file
# diff_stat_array : result from diff_fs_stats()
# size  : uncompressed file size added to or removed from file system 
# globals:
# ${diff_array}_pool   = copied from stats_1_array
# ${diff_array}_name   = copied from stats_1_array
# ${diff_array}_fullname = copied from stats_1_array
# ${diff_array}_path   = copied from stats_1_array
# ${diff_array}_size   = stats_2_array - stats_1_array
# ${diff_array}_alloc  = stats_2_array - stats_1_array
# ${diff_array}_free   = stats_2_array - stats_1_array
# ${diff_array}_used   = stats_2_array - stats_1_array
# ${diff_array}_avail  = stats_2_array - stats_1_array
# ${diff_array}_ref    = stats_2_array - stats_1_array
# ${diff_array}_comp   = stats_2_array - stats_1_array
# ${diff_array}_dfblocks = stats_2_array - stats_1_array
# ${diff_array}_dfused = stats_2_array - stats_1_array
# ${diff_array}_dffree = stats_2_array - stats_1_array
function check_sizes_fs() {
    local compfact=0
    local size=0

    if [ "${1}" == "-c" ] ; then
        shift
        compfact=${1}
        shift
        size=$(parse_size $1)
        sizecomp=$( echo ${size} / ${compfact} | bc)
    else
        compfact=1
        size=$(parse_size $1)
        sizecomp=${size}
    fi

    blockcount=$( echo "(${sizecomp} / ${blocksize}) + 1" | bc)

}

# run a command and optionally capture stdout and/or stderr into files or arrays
# args:
# [ --outname tmpfile | --outarray varname ] [ --errname tmpfile | --errarray varname ] command [ args ... ]
function run_cmd() {
    local outmode=0
    local errmode=0
    local outname=''
    local errname=''
    local cmd=''
    local usage_err=0

    while [ $# -gt 0 -a ${usage_err} -eq 0 -a "${1:0:2}" == "--" ] ; do

    if [ "${1}" == "--outname" ] ; then
        if [ "${outmode}" != "0" ] ; then
            usage_err=1
            break;
        fi
        outmode=1
        shift
        outname="$1"
        shift
        continue
    fi

    if [ "${1}" == "--outarray" ] ; then
        if [ "${outmode}" != "0" ] ; then
            usage_err=1
            break;
        fi
        outmode=2
        shift
        outname="$1"
        shift
        continue
    fi

    if [ "${1}" == "--errname" ] ; then
        if [ "${errmode}" != "0" ] ; then
            usage_err=1
            break;
        fi
        errmode=1
        shift
        errname="$1"
        shift
        continue
    fi

    if [ "${1}" == "--errarray" ] ; then
        if [ "${errmode}" != "0" ] ; then
            usage_err=1
            break;
        fi
        errmode=2
        shift
        errname="$1"
        shift
        continue
    fi

    if [ "${1:0:2}" == "--" ] ; then
        usage_err=1
        break;
    else
        break;
    fi
    done

    if [ ${usage_err} -ne 0 ] ; then
        echo "$0 : error: bad arguments" 1>&2
        return 1
    fi

    if [ ${outmode} -eq 1 ] ; then
        # capture to file
        outfile="${outname}"
    elif [ ${outmode} -eq 2 ] ; then
        # capture to array -> need new temporary file
        outfile=$(new_temp_file)
    fi

    if [ ${errmode} -eq 1 ] ; then
        # capture to file
        errfile="${errname}"
    elif [ ${errmode} -eq 2 ] ; then
        # capture to array -> need new temporary file
        errfile=$(new_temp_file)
    fi

    if [ "${outmode}" == "0" ] ; then
        if [ "${errmode}" == "0" ] ; then
            "$@"
            retval=$?
        else
            "$@" 2>"${errfile}"
            retval=$?
        fi
    else
        if [ "${errmode}" == "0" ] ; then
            "$@" >"${outfile}"
            retval=$?
        else
            "$@" >"${outfile}" 2>"${errfile}"
            retval=$?
        fi
    fi

    if [ ${outmode} -eq 2 ] ; then
        # array
        idx=0
        while read n <${outfile} ; do
            eval ${outname}[$idx]=\"\$n\"
            ((idx++))
        done
        rm ${outfile}
    fi

    if [ ${errmode} -eq 2 ] ; then
        # array
        idx=0
        while read n <${errfile} ; do
            eval ${errname}[$idx]=\"\$n\"
            ((idx++))
        done
        rm ${errfile}
    fi

    return ${retval}
}


# attach a disk image
# args:
# diskname
# globals:
# ${name}_attached # 1 if attached, else 0
# ${name}_disk     # device name of disk if attached, else '' 
function attach_disk() {
    local name=${1}
    local diskpath_v=${name}_path
    local diskpath=${!diskpath_v}
    local attached_v=${name}_attached
    local attached=${!attached_v}
    local outfile=""

    if [ ${attached} -eq 1 ] ; then
        echo "$0 : warning: disk '${name}' already attached."
        return 1
    fi

    outfile=$(new_temp_file) 
    run_cmd --outname ${outfile} hdiutil attach -nomount ${diskpath}

    if [ $? -ne 0 ] ; then
        echo "Disk attach failed. "
        return 1
    fi

    # find out device node(s)
    tmpdiskval=$(grep -e '^/dev/disk[0-9]\+[[:space:]]' <${outfile})
    if [ -z "${tmpdiskval}" ] ; then
        echo "Could not find device info"
        return 1
    fi

    eval ${name}_disk=\"\$\{tmpdiskval%% \*\}\"
    eval ${attached_v}=1

    rm ${outfile}
    return 0
}


# detach a disk image
# args:
# diskname
# globals:
# ${name}_attached # 1 if attached, else 0
# ${name}_disk     # device name of disk if attached, else '' 
function detach_disk() {
    local name=${1}
    local disk_v=${name}_disk
    local disk=${!disk_v}
    local attached_v=${name}_attached
    local attached=${!attached_v}
    local outfile=""

    if [ ${attached} -eq 0 ] ; then
        echo "$0 : warning: disk '${name}' not attached."
        return 1
    fi

    if [ -z "${disk}" ] ;  then
        echo "Warning: disk node for '${name}' not known."
        return 1
    fi

    outfile=$(new_temp_file) 
    run_cmd --outname ${outfile} hdiutil detach ${disk}

    if [ $? -ne 0 ] ; then
        echo "Disk detach failed. "
        return 1
    fi

    eval ${name}_disk=\'\'
    eval ${attached_v}=0

    rm ${outfile}
    return 0
}


# create ZFS partion on disk, destroying old content, if any
# args:
# disk_name
# globals:
# ${name}_attached # 1 if attached, else 0
# ${name}_disk     # device name of disk if attached, else '' 
function partion_disk() {
    local name=$1
    local was_attached=0
    local diskpath_v=${name}_path
    local diskpath=${!diskpath_v}
    local bandN=0
    local disk_v=${name}_disk
    local disk=${!disk_v}

    if [ -z "${diskpath}" ] ; then
        echo "$0 disk image not found" 1>&2
        return 1
    fi

    if hdiutil info | grep -e "${diskpath}" ; then
        # should be attached
        was_attached=1
    else
        # not attached.  Try and get the first and last band, and destroy
        # them, so the following attach will not trigger a mount or an import
        bandN=$(find_bands ${name} last)
        if [ -f "${diskpath}/bands/0" ] ; then
            rm "${diskpath}/bands/0"
        fi
        if [ ! -z "${bandN}" ] ; then
            rm "${diskpath}/bands/${bandN}"
        fi
        attach_disk ${name}
    fi

    gpt create /dev/${disk} 
    gpt add -s 409600 -t efi  /dev/${disk}
    gpt label -i 1 -l "EFI System Partition"  /dev/${disk}
    gpt add -t zfs /dev/${disk}
    gpt label -i 2 -l "ZFS"  /dev/${disk}

    if [ ${was_attached} -eq 0 ] ; then
        detach_disk ${name}
    fi
}


# run command, logging command, stderr and stdout
#
# Logs the execute command, stdout and stderr to
# ${tests_logdir}/test_${curtest}.X where X is "cmd", "out" or
# "err", respectively.
# args:
# [ -t subtest ] command [ args .. ]
# -t subtest  : sub test number, if present and > 0 suppresses increment of curtest
# globals:
# curtest : incremented by 1, if subnum not given or 0
function run_cmd_log() {
    local subnum=0
    local logname=""

    if [ "$1" == "-t" ] ; then
        shift
        subnum=$1
        shift
        if [ ${subnum} -eq 0 ] ; then
            ((curtest++))
        fi
        logname=${curtest}.${subnum}
    else
        ((curtest++))
        logname=${curtest}
    fi

    echo "$*"  >${tests_logdir}/test_${logname}.cmd

    run_cmd  --outname ${tests_logdir}/test_${logname}.out  --errname ${tests_logdir}/test_${logname}.err  "$@"
}


# print a log previously captured by run_cmd_log.
#
# args:
# [ -t subtest ]
# -t subtest  : sub test number to use
function print_run_cmd_logs() {
    local subtest=0
    local logname=""

    if [ $# -gt 1 -a "$1" == "-t" ] ; then
        shift
        subtest=$1
        shift
        logname=${curtest}.${subtest}
    else
        logname=${curtest}
    fi

    if [ -s ${tests_logdir}/test_${logname}.out ] ; then
        echo "out:"
        gawk '{print " | " $0;}' <${tests_logdir}/test_${logname}.out
    fi

    if [ -s ${tests_logdir}/test_${logname}.err ] ; then
        echo "err:"
        gawk '{print " | " $0;}' <${tests_logdir}/test_${logname}.err
    fi
}


# print ok/fail message and increment respective counter
#
# if argument is 0, print and count success, else print and count
# failure.
# args:
# { 0 | n }
# okcnt   : incremented by 1, if argument is 0
# failcnt : incremented by 1, if argument is not 0
function print_count_ok_fail() {
    if [ $1 -eq 0 ] ; then
        echo "ok (${curtest}/${tottests})"
        ((okcnt++))
    else
        echo "fail (${curtest}/${tottests})"
        ((failcnt++))
    fi
}


# run command, compare retval and output success or failure message
#
# Success or failure message is only printed, if the message parameter
# is not the empty string.  Logs given command (and arguments), as well
# as stdout and stderr to ${tests_logdir}/test_${curtest}.X where X is
# "cmd", "out" or "err", respectively, if the message parameter is not
# the empty string.  Returns zero if command's return value matches
# expected_retval, else returns 1.
# if -t subtest is given, then the lognames are changed to
# ${tests_logdir}/test_${curtest}.${subtest}.X with X as given above.
# args:
# expected_retval [ -t subtest ] message command [ args ]
# globals:
# last_cmd_retval : set to return value from command
# curtest : incremented by 1, if message given and subtest > 0 or not present
# okcnt   : incremented by 1, if message given and return value matches
# failcnt : incremented by 1, if message given and return value dose not match
function run_ret() {
    local exp_ret=$1
    local message="$2"
    local subtest=0
    local subtestarg=""
    local retval=0
    shift
    shift

    if [ "${message}" == "-t" ] ; then
        subtest=$1
        subtestarg="-t ${subtest}"
        shift
        message="$1"
        shift
    fi

    if [ -z "${message}" ] ; then
        if [ -z "${subtestarg}" ] ; then
            run_cmd "$@"
            retval=$?
        else
            run_cmd_log ${subtestarg} "$@"
            retval=$?
        fi
    else
        echo -n "${message}"
        echo -n -e "\t "

        run_cmd_log ${subtestarg} "$@"
        retval=$?

        if [ ${retval} -eq ${exp_ret} ] ; then
            print_count_ok_fail 0
        else
            print_count_ok_fail 1
        fi

        print_run_cmd_logs
    fi

    last_cmd_retval=${retval}
    test ${retval} -eq ${exp_ret} 
    retval=$?

    if [ ${stop_on_fail} -eq 1 -a ${retval} -ne 0 ] ; then
        exit 1
    fi

    return ${retval}
}


# run command, abort script if return code doesn't match expectation
# args:
# expected_retval command [ args ... ]
function run_abort() {
    local exp_ret=$1
    local retval=0
    shift

    run_cmd "$@"
    retval=$?

    if [ $retval -ne ${exp_ret} ] ; then
        echo "command '$*' returned ${retval}, expected ${exp_ret}.  Abort."
        exit 1
    fi

    return 0
}


# run command, compare retval and check output for regex.
#
# args:
# expected_retval message [ '-n' ] regex command [ args ... ]
function run_check_regex() {
    local exp_ret=$1
    local message="$2"
    local negate=0
    local regex=""
    local retval=0
    local isfail=1

    shift
    shift
    if [ "$1" == "-n" ] ; then 
        negate=1
        isfail=0
        shift
    fi

    regex="$1"
    shift

    if [ ! -z "${message}" ] ; then
        echo -n "${message}"
        echo -n -e "\t "
    fi

    run_cmd_log "$@"
    retval=$?
    last_cmd_retval=${retval}

    if [ ${exp_ret} -ne ${retval} ] ; then
        isfail=1
    else
        if grep -e "${regex}" <${tests_logdir}/test_${curtest}.out >/dev/null ; then
            isfail=${negate}
        fi
    fi
    
    if [ ! -z "${message}" ] ; then
        print_count_ok_fail ${isfail}
        print_run_cmd_logs
    fi

    if [ ${stop_on_fail} -eq 1 -a ${isfail} -ne 0 ] ; then
        exit 1
    fi

    return ${isfail}
}


# End
