#! /bin/bash

### list of functions ###
#
# make_disk size_in_gb name [ band size ]
# globals: disk_${name}_attached, disk_${name}_disk, disk_${name}_size, disk_${name}_path
#
# new_temp_file [ -p ]
# stdout: filename, with path if "-p" given.
#
# make_pool poolname [ -o option=value [ -o ... ] ] vdevs ...
# retval: return code of zpool create
# globals: pool_${poolname}_opt, pool_${poolname}_path, pool_${poolname}_vdevs, pool_${poolname}_fullname
#
# make_fs fsname [ -o option=value [ -o ... ] ]
# globals: fs_${fsname_tr}_opt=, fs_${fsname_tr}_path, fs_${fsname_tr}_name, fs_${fsname_tr}_fullname
#
# make_file [ -c comp_factor ] size pool file
# globals: file_${file}_size, file_${file}_pool, file_${file}_path, file_${file}_name
#
# run_cmd [ --outname tmpfile | --outarray varname ] [ --errname tmpfile | --errarray varname ] command [ args ... ]
# retval: return code of executed command
#
# attach_disk diskname
# globals: disk_${diskname}_attached, disk_${diskname}_disk
#
# detach_disk diskname
# globals: disk_${diskname}_attached, disk_${diskname}_disk
#
# partion_disk diskname
# globals: disk_${diskname}_attached, disk_${diskname}_disk
#
# run_ret expected_retval comment cammand [ args ... ]
# return: 0 or 1
# globals: last_cmd_retval

if [ -z "${tests_func_init_arr}" ] ; then
poolsmax=0
pools[0]=''
fssmax=0
fss[0]=''
filesmax=0
files[0]=''
disksmax=0
disks=''

tests_func_init_arr=1
fi

# create a new disk image
# args:
# size_in_gb disk_name [ band size ]
# globals:
# disk_${name}_attached # 1 if attached, else 0
# disk_${name}_disk     # device name of disk if attached, else '' 
# disk_${name}_size     # size in GB
# disk_${name}_path     # path to sparse bundle directory
function make_disk() {
    local size=$1
    local name=$2
    local res=0
    
    if [ "$1" == "-h" ] ; then
        echo "size_in_gb disk_name [ band size ]"
        return 0
    fi

    if [ -e ${diskstore}/${name}.sparsebundle ] ; then
        echo "error, image path exists."
        return 1
    fi

    if [ $# -eq 3 ] ; then
        # command with band size
        echo "Warning: specifying band size unsupported and ignored"
        hdiutil create -size ${size}g -layout GPTSPUD -partitionType ZFS -type SPARSEBUNDLE ${diskstore}/${name}.sparsebundle
        res=$?
    else
        # command w/o band size
        hdiutil create -size ${size}g -layout GPTSPUD -partitionType ZFS -type SPARSEBUNDLE ${diskstore}/${name}.sparsebundle
        res=$?
    fi

    eval disk_${name}_attached=0
    eval disk_${name}_disk=\'\'
    eval disk_${name}_size=${size}
    eval disk_${name}_path=\"${diskstore}/${name}.sparsebundle\"
    eval disk_${name}_idx=0

    if [ ${res} -eq 0 ] ; then
        disks[${disksmax}]=${name}
        eval disk_${name}_idx=${disksmax}
        ((disksmax++))
    fi

    return ${res}
}


# destroy a disk image
# args:
# disk_name
# globals:
# disk_${name}_attached # 1 if attached, else 0
# disk_${name}_disk     # device name of disk if attached, else '' 
# disk_${name}_size     # size in GB
# disk_${name}_path     # path to sparse bundle directory
function destroy_disk() {
    local name=$1
    local diskidx=0
    local tmp_v
    local i

    if [ "$1" == "-h" ] ; then
        echo "disk_name"
        return 0
    fi

    tmp_v=disk_${name}_idx
    
    if [ -z "${!tmp_v}" ] ; then
        echo "Nothing known about disk '${name}'"
        return 0
    fi
    diskidx=${!tmp_v}

    tmp_v=disk_${name}_attached
    if [ "1" == "${!tmp_v}" ] ; then
        detach_disk ${name}
    fi

    if [ ! -d ${diskstore}/${name}.sparsebundle ] ; then
        echo "error, image path not found."
        return 1
    fi

    rm -rf ${diskstore}/${name}.sparsebundle

    for i in attached disk size path idx ; do
        eval unset disk_${name}_${i}
    done

    disks[${diskidx}]=""
    return 0
}


# show all defined disk images
function list_disks() {
    local i
    local name

    if [ "$1" == "-h" ] ; then
        echo "(none)"
        return 0
    fi

    for ((i=0; i < disksmax; i++)) ; do
        if [ "${disks[i]}" == "" ] ; then
            continue
        fi
        name="${disks[i]}"
        echo "Disk '${name}'"
        print_object disk "${name}" path size attached disk
        echo
    done
}


# damage a disk to test ZFS error tolerance.
# args:
# percent disk_name
# globals:
# disk_${name}_attached # 1 if attached, else 0
# disk_${name}_disk     # device name of disk if attached, else '' 
function damage_disk() {
    local percent=$1
    local name=$2
    local diskpath_v=disk_${name}_path
    local diskpath=${!diskpath_v}
    local bandN=0
    local disk_v=disk_${name}_disk
    local disk=${!disk_v}
    local disksize
    local damagesize
    local tmp_v
    local miniterations_1
    local miniterations
    local maxiterations
    local minsize
    local maxsize
    local was_attached
    

    if [ "$1" == "-h" ] ; then
        echo "percent diskname"
        return 0
    fi

    if [ -z "${diskpath}" ] ; then
        echo "$0 disk image not found" 1>&2
        return 1
    fi
    
    echo "Damage_disk not implemented!"

    return 0


# we need to figure out how many iterations we need to do.  The criteria 
# are:
# Damage at most 4096 bytes (1 AF hardware sector) per iteration.
# Damage at least 32 bytes per iteration (we do not do single-byte or 
# bit damages).
# Do at least 50 iterations or 5 per percent, whichever is more.  Relaxe 
# minimum damage size of 32 bytes to 16 bytes if necessary, but not 
# further.
#
# We first calc a lower limit on the number of iterations, based on disk 
# size, percentage of damage and max damage per iteration

    # size of disk
    tmp_v=disk_${name}_size
    disksize=${!tmp_v}
    damagesize=$(echo "${disksize}*${percent}/100" | bc)
    if [ 50 -lt $((${percent}*5)) ] ; then
        miniterations_1=$((${percent}*5))
    else
        miniterations_1=50
    fi
    miniterations=$(echo "${damagesize}/4096" | bc)
    maxiterations=$(echo "${damagesize}/32" | bc)
    
    if [ ${miniterations} -lt ${miniterations_1} ] ; then
        maxsize=$(echo "${damagesize}/miniterations_1" | bc)
        if [ ${maxsize} -lt 16 ] ; then
            maxsize=16
            miniterations_1=$(echo "${damagesize}/16" | bc)
        fi
        miniterations=${miniterations_1}
    else
        maxsize=4096
    fi

    # here, maxsize and miniterations are fixed

    if [ ${maxiterations}  -lt ${miniteration} ] ; then
        maxiterations=${miniterations}
        minsize=$(echo "${damagesize}/maxiterations" | bc)
    else
        minsize=32
    fi

    # here minsize, maxsize, miniterations and maxiterations are fixed.

    # now we do a loop, randomly varying damage size per iteration 
    # between minsize and maxsize and randomly selecting damage start 
    # positions.  We repeate the loop until we have written damagesize
    # bytes of random data to the disk device (or its file backend).
    
    
    
    
# first determine number of blocks in disk
# split into 4096 extends
# repeat for percent times:
#   randomly select a segment
#   overwrite segment
# end repeat


    if hdiutil info | grep -e "${diskpath}" ; then
        # should be attached
        was_attached=1
    else
        # not attached.  Try and get the first and last band, and destroy
        # them, so the following attach will not trigger a mount or an import
        was_attached=0
    fi
    
    echo "Damage_disk not implemented!"

    return 0
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

    if [ "$1" == "-h" ] ; then
        echo "[ -p base ]"
        return 0
    fi

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


function new_fifo() {
    local filename=$(make_name 8)
    local filepath=${TMPDIR}/mzt.${filename}
    local res=0

    if [ "$1" == "-h" ] ; then
        echo "(none)"
        return 0
    fi

    while [ -e "${filepath}" ] ; do
        filename=$(make_name 8)
        filepath=${TMPDIR}/mzt.${filename}
    done
    mkfifo ${filepath}
    res=$?

    if [ $res -eq 0 ] ; then
        echo "${filepath}"
    else
        echo "Error: generating fifo ${filepath} (${filename}) failed" >&2
    fi
    return $res
}


# generate single random number in given interval
# args:
# min max
# min : lower bound for number (inclusive)
# max : upper bound for number (inclusive)
function get_rand_number() {
    local upperlimit="-b"

    if [ "$1" == "-h" ] ; then
        echo "min max"
        return 0
    fi

    if [ ${2} -gt 255 ] ; then
        upperlimit="-w"
    fi

    ${genrand_bin}  -S ${genrand_state} -d ${upperlimit} -c 1 -m $1 -M $2
    return 0
}


# generate name of given length
# args:
# min_length  [ max_length ]
# min_length : minimal name length, if no max_length given, then a name
#    of exactly min_length bytes is generated
# max_length : optional max name length, if given, then a random length
# between min_length and max_length (both inclusive) will be generated.
# The generated name is echoed to stdout.
function make_name() {
    local len=0
    local min=${1}
    local max=0
    local upperlimit="-b"

    if [ "$1" == "-h" ] ; then
        echo "min_length [ max_length ]"
        return 0
    fi

    if [ $# -eq 2 ] ; then
        max=$2
        len=0
        upperlimit="-b"
        if [ ${max} -gt 255 ] ; then
            upperlimit="-w"
        fi
#        while [ ${len} -lt ${min} -o ${len} -gt ${max} ] ; do
#            len=$(${genrand_bin} -S ${genrand_state} -c 1 ${upperlimit} -d)
#        done
        len=$(${genrand_bin} -S ${genrand_state} -c 1 ${upperlimit} -m ${min} -M ${max} -d)
    else
        len=${min}
    fi

    ${genrand_bin} -S ${genrand_state} -c ${len} -b -o -m 65 -M 90

    return 0
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
# pools[] : list of all test pools
# poolsmax : highest used index in pools[]
function make_pool() {
    local opt=""
    local opt_arg=""
    local poolpath=""
    local poolname="${1}"
    local poolfullname="${poolbase}_${poolname}"
    local res=0
    local i=''
    local realvdevs=''
    local disk_v
    local tmp

    if [ "$1" == "-h" ] ; then
        echo "poolname [ -o option=value [ -o ... ] ] vdevs ..."
        return 0
    fi

    shift
    while [ "$1" == "-o" ] ; do
        shift
        opt="${opt} $1"
        opt_arg="${opt_arg} -o $1"
        shift
    done
    eval pool_${poolname}_opt="\"\${opt}\""
    eval pool_${poolname}_fullname="\"\${poolfullname}\""
    eval pool_${poolname}_path="\"/Volumes/\${poolfullname}\""
    eval pool_${poolname}_vdevs="\"\$*\""
    
    for i in $* ; do
        tmp=${i%%:*}
        disk_v=disk_${tmp//\//_}_idx
        if [ -z "${!disk_v}" ] ; then
            realvdevs="${realvdevs} $i"
        else
            disk_v=disk_${tmp//\//_}_disk
            tmp=${!disk_v}
            if [ "${i}" != "${i##*:}" ] ; then
                tmp="${tmp}s${i##*:}"
            fi
            realvdevs="${realvdevs} $tmp"
        fi
    done
    eval pool_${poolname}_realvdevs="\"\${realvdevs}\""

    zpool create ${opt_arg} ${poolfullname} ${realvdevs}
    res=$?
    if [ ${res} -eq 0 ] ; then
        pools[${poolsmax}]=$poolname
        eval pool_${poolname}_idx=${poolsmax}
        ((poolsmax++))

        eval fs_${poolname}_opt=""
        eval fs_${poolname}_name="\"\${poolname}\""
        eval fs_${poolname}_fullname="\"\${poolfullname}\""
        eval fs_${poolname}_path="\"/Volumes/\${poolfullname}\""
        eval fs_${poolname}_pool="\"\${poolname}\""
    fi

    return ${res}
}


# destroy named zfs pool
# args:
# poolname 
# globals:
# pool_${poolname}_opt=...   : options used
# pool_${poolname}_fullname= : pool name with pool prefix
# pool_${poolname}_path=     : full path to pool filesystem
# pool_${poolname}_vdevs=... : vdev specification used
# poolbase : prefix for all pools.
# pools[] : list of all test pools
# poolsmax : highest used index in pools[]
function destroy_pool() {
    local tmp_v=""
    local poolidx=0
    local poolname="${1}"
    local poolfullname=""
    local name
    local res=0
    local i=''

    if [ "$1" == "-h" ] ; then
        echo "poolname"
        return 0
    fi

    tmp_v=pool_${poolname}_idx
    if [ -z "${!tmp_v}" ] ; then
        echo "Pool '${poolname}' not found"
        return 0
    fi
    poolidx=${!tmp_v}

    tmp_v=pool_${poolname}_fullname
    poolfullname="${!tmp_v}"

    run_cmd_log zpool destroy -f ${poolfullname}
    res=$?

    for ((i=0; i < fssmax; i++)) ; do
        if [ "${fss[i]}" == "" ] ; then
            continue
        fi
        name="${fss[i]}"
        tmp_v=fs_${name}_pool
        if [ "${!tmp_v}" != "${poolname}" ] ; then
            continue
        fi
        forget_fs ${name}
    done

    for i in opt fullname path vdevs idx ; do
        eval unset pool_${poolname}_${i}
    done

    pools[${poolidx}]=""
    
    return $res
}


# show all defined pools
function list_pools() {
    local i
    local name

    if [ "$1" == "-h" ] ; then
        echo "(none)"
        return 0
    fi

    for ((i=0; i < poolsmax; i++)) ; do
        if [ "${pools[i]}" == "" ] ; then
            continue
        fi
        name="${pools[i]}"
        echo "Pool '${name}'"
        print_object pool "${name}" fullname path opt vdevs
        echo
    done
}


# create named zfs filesystem
# args:
# fsname [ -o option=value [ -o ... ] ]
# globals:
# (fsname_tr is fsname, but with "/" mapped to "_")
# fs_${fsname_tr}_opt=...  : options used
# fs_${fsname_tr}_path=    : full path to zfs filesystem
# fs_${fsname_tr}_name=... : original file system name ${fsname}
# fs_${fsname_tr}_fullname= : zfs filesystem name with full pool prefix
# fs_${fsname_tr}_pool=    : name of pool
function make_fs() {
    local opt=""
    local fspath=""
    local fsname="${1}"
    local fsname_tr="${fsname//\//_}"
    local fsfullname=""

    if [ "$1" == "-h" ] ; then
        echo "fsname [ -o option=value [ -o ... ] ]"
        return 0
    fi

    # if fsname and fsname_tr are identical, then we have only the pool fs itself, which is forbidden.
    if [ "${fsname}" == "${fsname_tr}" ] ; then
        echo "Error: make_fs() requires at least one '/' in the fs name"
        return 1
    fi
    fsfullname=${poolbase}_${fsname}

    shift
    while [ "$1" == "-o" ] ; do
        shift
        opt="${opt} -o $1"
        shift
    done
    eval fs_${fsname_tr}_opt="\"\${opt}\""
    eval fs_${fsname_tr}_name="\"\${fsname}\""
    eval fs_${fsname_tr}_fullname="\"\${fsfullname}\""
    eval fs_${fsname_tr}_path="\"/Volumes/\${fsfullname}\""
    eval fs_${fsname_tr}_pool="\"\${fsname%%/\*}\""

    zfs create ${opt} ${fsfullname}

    res=$?
    
    if [ ${res} -eq 0 ] ; then
        fss[${fssmax}]=${fsname_tr}
        eval fs_${fsname_tr}_idx=${fssmax}
        ((fssmax++))
    fi

    return ${res}
}

# clone snapshot into new zfs filesystem
# args:
# snapshot fsname [ -o option=value [ -o ... ] ]
# globals:
# (fsname_tr is fsname, but with "/" mapped to "_")
# fs_${fsname_tr}_opt=...  : options used
# fs_${fsname_tr}_path=    : full path to zfs filesystem
# fs_${fsname_tr}_name=... : original file system name ${fsname}
# fs_${fsname_tr}_fullname= : zfs filesystem name with full pool prefix
# fs_${fsname_tr}_pool=    : name of pool
function make_clone_fs() {
    local opt=""
    local fspath=""
    local snname="${1}"
    local fsname="${2}"
    local fsname_tr="${fsname//\//_}"
    local fsfullname=""

    if [ "$1" == "-h" ] ; then
        echo "snapshot fsname [ -o option=value [ -o ... ] ]"
        return 0
    fi

    # if fsname and fsname_tr are identical, then we have only the pool fs itself, which is forbidden.
    if [ "${fsname}" == "${fsname_tr}" ] ; then
        echo "Error: make_fs() requires at least one '/' in the fs name"
        return 1
    fi
    fsfullname=${poolbase}_${fsname}

    shift
    shift
    while [ "$1" == "-o" ] ; do
        shift
        opt="${opt} $1"
        shift
    done
    eval fs_${fsname_tr}_opt="\"\${opt}\""
    eval fs_${fsname_tr}_name="\"\${fsname}\""
    eval fs_${fsname_tr}_fullname="\"\${fsfullname}\""
    eval fs_${fsname_tr}_path="\"/Volumes/\${fsfullname}\""
    eval fs_${fsname_tr}_pool="\"\${fsname%%/\*}\""

    zfs clone ${opt}  ${poolbase}_${snname} ${fsfullname}

    res=$?
    
    if [ ${res} -eq 0 ] ; then
        fss[${fssmax}]=${fsname_tr}
        eval fs_${fsname_tr}_idx=${fssmax}
        ((fssmax++))
        clone_files -c ${snname} ${fsname}
    fi

    return ${res}
}


# remove file system from list of known fs
# args:
# fsname
# fsname : name of filesystem
function forget_fs() {
    local i
    local name="${1}"
    local name_tr="${1//[\/@]/_}"
    local fsidx
    local tmp_v

    if [ "$1" == "-h" ] ; then
        echo "fsname"
        return 0
    fi

    tmp_v=fs_${name_tr}_idx
    fsidx=${!tmp_v}

    if [ -z "${fsidx}" ] ; then
        echo "Nothing known about fs ${name}"
        return 1
    fi

    forget_fs_files ${name}

    for i in name fullname path pool opt idx ; do
        eval unset fs_${name_tr}_${i}
    done

    fss[${fsidx}]=""
    
    return 0
}


# show all defined file systems
# args:
# [ poolname ]
# poolname : only show file systems belonging to pool poolname
function list_fss() {
    local i
    local name
    local poolname=""
    local tmp_v
    
    if [ "$1" == "-h" ] ; then
        echo "[ poolname ]"
        return 0
    fi

    if [ $# -eq 1 ] ; then
        poolname="${1}"
    fi

    for ((i=0; i < fssmax; i++)) ; do
        if [ "${fss[i]}" == "" ] ; then
            continue
        fi
        name="${fss[i]}"
        if [ -n "${poolname}" ] ; then
            tmp_v=fs_${name}_pool
            if [ "${!tmp_v}" != "${poolname}" ] ; then
                continue
            fi
        fi
        echo "FS '${name}'"
        print_object fs "${name}" name fullname path pool opt
        echo
    done
}

# create a stream from a snapshot
# args:
# destfile zfs-send-args ...
#
function zfs_send() {
    local destpath=$1
    local args=""

    if [ "$1" == "-h" ] ; then
        echo "destfile zfs-send-args ... "
        return 0
    fi

    shift

    while [ $# -ge 1 ] ; do
        if [ "${1:0:1}" == "-" ] ; then
            args="${args} ${1}"
            shift
        else
            # everything else should be a snapshot name -> remap
            args="${args} ${poolbase}_${1}"
            shift
        fi
    done

    zfs send ${args} >${destpath}
}

# create a (temporary) file of given size
# args:
# [ -c comp_factor ] [ -T max_secs ] size fs file [ rel_file_path]
# -c comp_factor : try to make the file contents compressible by factor comp_factor
# size  : size of file in bytes, optionaly with multiplier "m" or "k", example: 8m
# -T max_secs    : spend at most max_secs second, trying to generate $size bytes 
# fs    : zfs filesystem to place file in.  if special name _temp_ is used, then place file in ${TMPDIR}
# file  : filename (optionally with path prefix) relative to zfs filesystem.
#         this is just a handle to the file, not necessaryly its path, see next argument
# rel_file_path  : filename and path relative to the file system $fs.  Defaults to $file.
# globals:
# (note: ${file} is a sanitized variant of $file from above)
# file_${file}_size = size of file
# file_${file}_fs = zfs filessystem
# file_${file}_name = original file name, this is the handle $file from above
# file_${file}_relpath = filename and path relative to the file system $fs
# file_${file}_path = full path to file, starting at "/"
# fs_${fs}_path : path to zfs filesystem
# files[] : list of all created files
# filesmax : index into files[]
function make_file() {
    local filename=""
    local filename_tr=""
    local size=""
    local fs=""
    local filepath=""
    local filerelpath=""
    local compfact=0
    local count=0
    local sizeflag=""
    local fspath_v=""
    local maxsecs=0
    local filedir
    local res=0

    if [ "$1" == "-h" ] ; then
        echo "[ -c comp_factor ] [ -T max_secs ] size fs file [ rel_path ]"
        return 0
    fi

    if [ "${1}" == "-c" ] ; then
        shift
        compfact=${1}
        shift
    fi

    if [ "${1}" == "-T" ] ; then
        shift
        maxsecs=${1}
        shift
    fi

    size=${1}
    fs=${2}
    filename=${3}
    filename_tr=${filename//\//_}

    if [ $# -gt 3 ] ; then
        filerelpath="${4}"
    else
        filerelpath=${3}
    fi
    
    if [ "${size: -1:1}" == "m" ] ; then
        # 1m bytes makes 1024*256 longs
        count=$((${size%m}*1024*256))
        size=$((${count}*4))
        sizeflag=-l
    elif [ "${size: -1:1}" == "k" ] ; then
        # 1k bytes makes 256 longs
        count=$((${size%k}*256))
        size=$((${count}*4))
        sizeflag=-l
    else
        # size is given in bytes
        count=${size}
        sizeflag=""
    fi

    if [ "${fs}" == "_temp_" ] ; then
        filepath=$(new_temp_file)
        filerelpath=${filepath}
    else
        fspath_v=fs_${fs//\//_}_path
        filepath=${!fspath_v}/${filerelpath}
    fi
    filedir=$(dirname ${filepath})
    if [ ! -e ${filedir} ] ; then
        mkdir -pv ${filedir}
    elif [ ! -d ${filedir} ] ; then
        echo "Error: file path is not a directory."
        return 1
    fi

    if [ ${compfact} -eq 0 ] ; then
        ${genrand_bin} -v -S ${genrand_state} -T ${maxsecs} -c ${count} ${sizeflag} -o >${filepath}
        res=$?
    else
        ${genrand_bin} -v -S ${genrand_state} -T ${maxsecs} -c ${size} -b -o -t >${filepath}
        res=$?
    fi
    
    if [ $res -eq 0 ] ; then
        eval file_${filename_tr}_size=${size}
        eval file_${filename_tr}_fs=${fs}
        eval file_${filename_tr}_name=${filename}
        eval file_${filename_tr}_relpath=${filerelpath}
        eval file_${filename_tr}_path=${filepath}
        eval file_${filename_tr}_ghost=0

        files[${filesmax}]=${filename_tr}
        eval file_${filename_tr}_idx=${filesmax}
        ((filesmax++))
    else
        echo "Error: generating file ${filepath} (${filename}) failed"
    fi

    return $res
}


# show all defined files
# args:
# [ fsname ] [ -g ]
# fsname : only show files on the file system fsname
# -g : include files in ghost state (implied, if fsname is a snapshot)
function list_files() {
    local i
    local name
    local fsname=""
    local showghost=0
    local tmp_v

    if [ "$1" == "-h" ] ; then
        echo "[ fsname ] [ -g ]"
        return 0
    fi

    while [ $# -gt 0 ] ; do
        if [ "${1}" == "-g" ] ; then
            showghost=1
            shift
        elif [ "${1:0:1}" != "-" ] ; then
            fsname="${1}"
            shift
        else
            echo "list_files(): Unknown flag '$1'"
            return 1
        fi
    done

    if [ "${fsname#*@}" != "${fsname}" ] ; then
        # name contains "@"
        showghost=1
    fi

    for ((i=0; i < filesmax; i++)) ; do
        if [ "${files[i]}" == "" ] ; then
            continue
        fi
        name="${files[i]}"
        if [ -n "${fsname}" ] ; then
            tmp_v=file_${name}_fs
            if [ "${!tmp_v}" != "${fsname}" ] ; then
                continue
            fi
        fi
        tmp_v=file_${name}_ghost
        if [ ${!tmp_v} -eq 1 -a ${showghost} -eq 0 ] ; then
            continue
        fi
        echo "File '${name}'"
        print_object file "${name}" name path fs size ghost
        echo
    done
}


# add existing file
# args:
# filename
# filename  : filename with absolute path
# globals:
# file_${file}_size = size of file
# file_${file}_pool = zfs filessystem
# file_${file}_name = original file name
# file_${file}_path = full path to file, starting at "/"
# pool_${pool}_path : path to zfs filesystem
function add_file() {
    if [ "$1" == "-h" ] ; then
        echo "filename"
        echo "(unimplemented)"
        return 0
    fi

    echo "add_file():  unimplemented."
    exit 1
}


# copy existing file
# args:
# src-file target-fs dest-file [ dest-rel-path ]
# src-file : filename as given to make_file
# target-fs : zfs filesystem to place file in, as from make_fs
# dest-file : filename (handle) for the new file. does not need to be a path
# dest-rel-path : name of new file, including path relative to target
#                 filesystem.  Defaults to dest-file.
function copy_file() {
    local srcname=""
    local srcname_tr=""
    local srcpath=""
    local destname=""
    local destname_tr=""
    local fs="${2}"
    local fs_tr=""
    local destpath=""
    local destrelpath=""
    local srcidx=0
    local destidx=0
    local name_v=''
    local res=0

    if [ "$1" == "-h" ] ; then
        echo "src-file target-fs dest-file [ dest-rel-path ]"
        return 0
    fi

    srcname=${1}
    srcname_tr=${srcname//\//_}

    destname=${3}
    destname_tr=${destname//\//_}
    
    if [ $# -gt 3 ] ; then
        destrelpath="${4}"
    else
        destrelpath="${3}"
    fi
    
    if [ "${srcname_tr}" == "${destname_tr}" ] ; then
        echo "Error: test system limitation: can't have to files with same name in different file systems."
        return 1
    fi

    for ((srcidx=0; srcidx < filesmax; srcidx++)) ; do
        if [ "${files[${srcidx}]}" == "${srcname_tr}" ] ; then
            break
        fi
    done
    
    if [ ${srcidx} -eq ${filesmax} ] ; then
        echo "copy_file(): Nothing known about '${srcname}'."
        return 1
    fi

    name_v=file_${srcname_tr}_ghost
    if [ ${!name_v} -eq 1 ] ; then
        echo "copy_file(): File is not accessible: State is ghost == 1."
        return 1
    fi

    name_v=file_${srcname_tr}_path
    srcpath=${!name_v}

    for ((destidx=0; destidx < filesmax; destidx++)) ; do
        if [ "${files[${destidx}]}" == "${destname_tr}" ] ; then
            break
        fi
    done
    
    fs_tr=${fs//\//_}
    name_v=fs_${fs_tr}_path
    destpath="${!name_v}/${destrelpath}"

    cp "${srcpath}" "${destpath}"
    res=$?

    if [ $res -eq 0 ] ; then
        name_v=file_${srcname_tr}_size
        eval file_${destname_tr}_size=${!name_v}
        eval file_${destname_tr}_fs=${fs}
        eval file_${destname_tr}_name=${destname}
        eval file_${destname_tr}_path=${destpath}
        eval file_${destname_tr}_relpath=${destrelpath}
        eval file_${destname_tr}_ghost=0

        files[${destidx}]=${destname_tr}
        eval file_${destname_tr}_idx=${destidx}
    else
        echo "Error: generating file ${filepath} (${filename}) failed"
    fi

    if [ ${destidx} -eq ${filesmax} ] ; then
        ((filesmax++))
    fi

    return $res
}


# remove (delete) file created by make_file()
# args:
# [ -k ] filename
# -k : delete file from file system, but keep meta data (use for files
#    that may return from snapshots)
# filename : file name as given to make_file().  The actual path is
#    read from file_${file}_path, see make_file().
function remove_file() {
    local filename=""
    local filename_tr=""
    local filepath=""
    local filepath_v=''
    local fileidx=0
    local keepmeta=0
    local tmp_v
    local res=0

    if [ "$1" == "-h" ] ; then
        echo "[ -k ] filename"
        return 0
    fi

    if [ "$1" == "-k" ] ; then
        keepmeta=1
        shift
    fi

    filename=${1}
    filename_tr=${filename//\//_}

    for ((fileidx=0; fileidx < filesmax; fileidx++)) ; do
        if [ "${files[${fileidx}]}" == "${filename_tr}" ] ; then
            break
        fi
    done
    
    if [ ${fileidx} -eq ${filesmax} ] ; then
        echo "remove_file(): Nothing known about '${filename}'."
        return 1
    fi

    tmp_v=file_${filename_tr}_path
    filepath="${!tmp_v}"

    tmp_v=file_${filename_tr}_ghost
    if [ ${!tmp_v} -eq 1 -a ! -e "${filepath}" ] ; then
        echo "File already removed (file is a ghost entry)."
        return 0
    fi
    
    rm "${filepath}"
    res=$?
    if [ ${res} -eq 0 -a ! -e "${filepath}" ] ; then
        if [ ${keepmeta} -eq 0 ] ; then
            forget_file ${filename}
        else
            eval file_${filename_tr}_ghost=1
        fi
    else
        echo "remove_file(): unlink failed"
    fi

    return ${res}
}


# dublicate file meta data when creating a snapshot or when cloning a
# snapshot into a new fs.
# args:
# { -c | -s } old-name new-name
# -c  : a snapshot is cloned
# -s  : a file system is snapshotted
# old-name : old filesystem or snapshot name
# new-name : new snapshot or filesystem name
# snapshot names include the pool and filesystem part, e.g. p1/fs2@sn4
function clone_files() {
    local oldname=$2
    local newname=$3
    local clonepath
    local idx=0
    local attr=""
    local oldidxmax=${filesmax}
    local newfn
    local newfn_tr
    local oldfn
    local oldfn_tr
    local tmp_v

    if [ "$1" == "-h" ] ; then
        echo "{ -c | -s } old_name new_name"
        return 0
    fi

    if [ "$1" == "-c" ] ; then
        tmp_v=fs_${newname//[\/@]/_}_path
        clonepath=${!tmp_v}
    fi

    for ((idx=0; idx < oldidxmax; idx++)) ; do
        oldfn_tr=${files[${idx}]}
        tmp_v=file_${oldfn_tr}_fs
        if [ "${!tmp_v}" == "${oldname}" ] ; then
            # candidate
            if [ "$1" == "-s" ] ; then
                tmp_v=file_${oldfn_tr}_ghost
                if [ ${!tmp_v} -eq 1 ] ; then
                    # ghost files are not visible and as such not part of the new snapshot
                    continue;
                fi
                tmp_v=file_${oldfn_tr}_name
                newfn=${!tmp_v}@${newname#*@}
            else
                tmp_v=file_${oldfn_tr}_name
                oldfn=${!tmp_v}
                newfn=${newname}/${oldfn%@*}
            fi
            newfn_tr=${newfn//[\/@]/_}
            for attr in size relpath path compfact; do
                tmp_v=file_${oldfn_tr}_${attr}
                eval file_${newfn_tr}_${attr}=${!tmp_v}
            done
            eval file_${newfn_tr}_fs=${newname}
            eval file_${newfn_tr}_name=${newfn}
            if [ "$1" == "-s" ] ; then
                eval file_${newfn_tr}_ghost=1
            else
                eval file_${newfn_tr}_ghost=0
                tmp_v=file_${oldfn_tr}_relpath
                eval file_${newfn_tr}_path=${clonepath}/${!tmp_v}
            fi
            eval file_${newfn_tr}_idx=${filesmax}
            files[${filesmax}]=${newfn_tr}
            ((filesmax++))
        fi
    done
}


# forget all files on a filesystem, snapshot or clone.
# args:
# fs-name
# fs-name : old filesystem, clone or snapshot name
# snapshot names include the pool and filesystem part, e.g. p1/fs2@sn4
function forget_fs_files() {
    local oldname=$1
    local idx
    local tmp_v
    local oldidxmax=${filesmax}
    local oldfn_tr

    if [ "$1" == "-h" ] ; then
        echo "fs_name"
        return 0
    fi

    for ((idx=0; idx < oldidxmax; idx++)) ; do
        oldfn_tr=${files[${idx}]}
        tmp_v=file_${oldfn_tr}_fs
        if [ "${!tmp_v}" == "${oldname}" ] ; then
            # candidate
            forget_file_impl ${idx}  ${oldfn_tr}
        fi
    done
}


# declare re-appearance of a file deleted by remove_file -k ....
# args:
# filename  [ new_fs ]
# filename : file name as given to make_file().  The actual path is
#    read from file_${file}_path, see make_file().
# new_fs   : optional new file system which hold the file.  Use when
#    cloning a snapshot.
function resurrect_file() {
    local filename=""
    local filename_tr=""
    local filepath=""
    local tmp_v=''
    local fileidx=0
    local keepmeta=0

    if [ "$1" == "-h" ] ; then
        echo "filename [ new_fs ]"
        return 0
    fi

    filename=${1}
    filename_tr=${filename//[\/@]/_}

    for ((fileidx=0; fileidx < filesmax; fileidx++)) ; do
        if [ "${files[${fileidx}]}" == "${filename_tr}" ] ; then
            break
        fi
    done
    
    if [ ${fileidx} -eq ${filesmax} ] ; then
        echo "resurrect_file(): Nothing known about '${filename}'."
        return 1
    fi

    tmp_v=file_${filename_tr}_ghost
    if [ ${!tmp_v} -eq 0 ] ; then
        echo "File not in ghost state."
        return 1
    fi

    if [ $# -eq 2 ] ; then
        # new fs path
        tmp_v=fs_${2//\//_}_path
        eval filepath=${!tmp_v}/${filename}
        # ${poolbase}_${2}/\${filepath\#${poolbase}_${!tmp_v}/}
        eval file_${filename_tr}_fs="${2}"
        eval file_${filename_tr}_path="${filepath}"
    fi

    eval file_${filename_tr}_ghost=0

    return 0
}


# forget file creaed by make_file()
# args:
# filename
# filename : file name as given to make_file().  The actual path is
#    read from file_${file}_path, see make_file().
function forget_file() {
    local filename=""
    local filename_tr=""
    local fileidx=0

    if [ "$1" == "-h" ] ; then
        echo "filename"
        return 0
    fi

    filename=${1}
    filename_tr=${filename//[\/@]/_}

    for ((fileidx=0; fileidx < filesmax; fileidx++)) ; do
        if [ "${files[${fileidx}]}" == "${filename_tr}" ] ; then
            break
        fi
    done
    
    if [ ${fileidx} -eq ${filesmax} ] ; then
        echo "forget_file(): Nothing known about '${filename}'."
        return 1
    fi

    forget_file_impl ${fileidx}  ${filename_tr}
}

# internal backend form forget_file
# args:
# idx fn_tr
# idx  : index into files array
# fn_tr: translate file name
function forget_file_impl() {
    local filename_tr="$2"
    local fileidx=$1
    local i

    if [ "$1" == "-h" ] ; then
        echo "idx  fname_tr"
        return 0
    fi

    for i in size fs name path compfact idx ghost; do
        eval unset file_${filename_tr}_${i}
    done
    
    files[${fileidx}]=''
}


# determine file compression
# args:
# file
# file : file name to use.  the actual path is read from
#    file_${file}_path, see make_file().
# globals:
# file_${file}_path
# file_${file}_size
# file_${file}_compfact
function calc_comp_fact() {
    local fileid="$1"
    local tmp_v
    local filepath
    local compsize=0
    local nomsize=0

    if [ "$1" == "-h" ] ; then
        echo "file"
        return 0
    fi

    tmp_v=file_${fileid}_path
    filepath=${!tmp_v}

    tmp_v=file_${fileid}_size
    nomsize=${!tmp_v}

    compsize=$(gzip <${filepath} | wc -c)
    eval file_${fileid}_compfact=$(echo "${nomsize} / ${compsize}" | bc)
    return 0
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

    if [ "$1" == "-h" ] ; then
        echo "destvar file"
        return 0
    fi

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


# print file status meta data
# args:
# stats_array_name  : name of variable holding the state data, see 
#    get_file_stats()
function print_file_stats() {
    local tmp_v=""

    if [ "$1" == "-h" ] ; then
        echo "stats_array_name"
        return 0
    fi

    for i in name path mode nlink uid gid size atime mtime ctime blksize blocks ; do
        tmp_v=${1}_${i}
        echo "$i : ${!tmp_v}"
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
# ${destvar}_pool   = copied from fs_${fs}_pool
# ${destvar}_name   = copied from fs_${fs}_name
# ${destvar}_fullname = copied from fs_${fs}_fullname
# ${destvar}_path   = copied from fs_${fs}_path
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
    local tmp_v=fs_${fs_tr}_pool
    local pool=${!tmp_v}
    tmp_v=fs_${fs_tr}_fullname
    local fullname=${!tmp_v}
    tmp_v=pool_${pool}_fullname
    local poolfullname=${!tmp_v}
    tmp_v=fs_${fs_tr}_path
    local path=${!tmp_v}
    local idx=0
    local tmp_res
    local idx2=0
    local i
    local tmp_val
    local unit

    if [ "$1" == "-h" ] ; then
        echo "destvar fs"
        return 0
    fi

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

    for ((idx2=0; idx2 < 3; idx2++)) ; do
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

    for ((idx2=0; idx2 < 3; idx2++)) ; do
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


# print file system status meta data
# args:
# stats_array_name  : name of variable holding the state data, see 
#    get_fs_stats()
function print_fs_stats() {
    local tmp_v=""

    if [ "$1" == "-h" ] ; then
        echo "stats_array_name"
        return 0
    fi

    for i in pool name fullname path size alloc free used avail ref comp dfblocks dfused dffree; do
        tmp_v=${1}_${i}
        echo "$i : ${!tmp_v}"
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

    if [ "$1" == "-h" ] ; then
        echo "diff-array  stats-1  stats-2"
        return 0
    fi

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
    local sizecomp

    if [ "$1" == "-h" ] ; then
        echo "[ -c comp_factor ] fs-diff-array  size"
        return 0
    fi

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

    echo "Warning: check_sizes_fs() not implemented"
    return 0
    
#    blockcount=$( echo "(${sizecomp} / ${blocksize}) + 1" | bc)

}


# check if file size reported by ls makes sense
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
function check_sizes_file() {
    local compfact=0
    local size=0

    if [ "$1" == "-h" ] ; then
        echo "[ -c comp_factor ] fs-diff-array  size"
        return 0
    fi

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

    echo "Warning: check_sizes_file() not implemented"
    return 0
    
#    blockcount=$( echo "(${sizecomp} / ${blocksize}) + 1" | bc)

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
    local outfile
    local errfile
    local retval
    local idx

    if [ "$1" == "-h" ] ; then
        echo "[ --outname tmpfile | --outarray varname ] [ --errname tmpfile | --errarray varname ] command [ args ... ]"
        return 0
    fi

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
# disk_${name}_attached # 1 if attached, else 0
# disk_${name}_disk     # device name of disk if attached, else '' 
function attach_disk() {
    local name=${1}
    local diskpath_v=disk_${name}_path
    local diskpath=${!diskpath_v}
    local attached_v=disk_${name}_attached
    local attached=${!attached_v}
    local outfile=""
    local tmpdiskval

    if [ "$1" == "-h" ] ; then
        echo "diskname"
        return 0
    fi

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

    eval disk_${name}_disk=\"\$\{tmpdiskval%% \*\}\"
    eval ${attached_v}=1

    rm ${outfile}
    return 0
}


# detach a disk image
# args:
# diskname
# globals:
# disk_${name}_attached # 1 if attached, else 0
# disk_${name}_disk     # device name of disk if attached, else '' 
function detach_disk() {
    local name=${1}
    local disk_v=disk_${name}_disk
    local disk=${!disk_v}
    local attached_v=disk_${name}_attached
    local attached=${!attached_v}
    local outfile=""

    if [ "$1" == "-h" ] ; then
        echo "diskname"
        return 0
    fi

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

    eval disk_${name}_disk=\'\'
    eval ${attached_v}=0

    rm ${outfile}
    return 0
}


# create ZFS partion on disk, destroying old content, if any
# args:
# disk_name
# globals:
# disk_${name}_attached # 1 if attached, else 0
# disk_${name}_disk     # device name of disk if attached, else '' 
function partion_disk() {
    local name=$1
    local was_attached=0
    local diskpath_v=disk_${name}_path
    local diskpath=${!diskpath_v}
    local bandN=0
    local disk_v=disk_${name}_disk
    local disk=${!disk_v}

    if [ "$1" == "-h" ] ; then
        echo "diskname"
        return 0
    fi

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
# -t subtest  : sub test number, if present and > 1 suppresses increment of curtest
# globals:
# curtest : incremented by 1, if subnum not given or less than 2
function run_cmd_log() {
    local subnum=0
    local logname=""

    if [ "$1" == "-h" ] ; then
        echo "[ -t subtest ] command [ args .. ]"
        return 0
    fi

    if [ "$1" == "-t" ] ; then
        shift
        subnum=$1
        shift
        if [ ${subnum} -lt 2 ] ; then
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
# globals:
# curtest
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
# { 0 | n } [ s ]
# globals:
# okcnt   : incremented by 1, if argument is 0
# failcnt : incremented by 1, if argument is not 0
# tottests: updated if less than curtest
# curtest
# cursubtest
# subokcnt
# subfailcnt
function print_count_ok_fail() {
    if [ ${curtest} -gt ${tottests} ] ; then
        tottests=${curtest}
    fi
    if [ $# -eq 2 ] ; then
        if [ $1 -eq 0 ] ; then
            echo "ok (${curtest}.${cursubtest}/${tottests})"
            ((subokcnt++))
        else
            echo "fail (${curtest}.${cursubtest}/${tottests})"
            ((subfailcnt++))
        fi
    else
        if [ $1 -eq 0 ] ; then
            echo "ok (${curtest}/${tottests})"
            ((okcnt++))
        else
            echo "fail (${curtest}/${tottests})"
            ((failcnt++))
        fi
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
# cursubtest
# subokcnt
# subfailcnt
function run_ret() {
    local exp_ret=$1
    local message="$2"
    local subtest=0
    local subtestarg=""
    local retval=0
    local rrmode=0
    local counter=""

    if [ "${exp_ret}" == "-h" ] ; then
        echo "expected_retval [ -t subtest ] message command [ args ]"
        return 0
    fi

    if [ "${exp_ret}" == "-is" ] ; then
        # called as run_ret_start
        rrmode=1
        cursubtest=1
        subtest=1
        subokcnt=0
        subfailcnt=0
        subtestarg="-t 1"
        shift
        exp_ret=$1
        message="$2"
    elif [ "${exp_ret}" == "-in" ] ; then
        # called as run_ret_next
        rrmode=2
        ((cursubtest++))
        subtest=${cursubtest}
        subtestarg="-t ${subtest}"
        shift
        exp_ret=$1
        message="$2"
    elif [ "${exp_ret}" == "-ie" ] ; then
        # called as run_ret_end
        rrmode=3
        ((cursubtest++))
        subtest=${cursubtest}
        subtestarg="-t ${subtest}"
        shift
        exp_ret=$1
        message="$2"
    fi

    shift
    shift

    if [ "${message}" == "-t" ] ; then
        subtest=$1
        subtestarg="-t ${subtest}"
        shift
        message="$1"
        shift
        if [ ${rrmode} -eq 0 ] ; then
            rrmode=2
        fi
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

        if [ ${rrmode} -eq 0 ] ; then
            counter=""
        else
            counter="s"
        fi

        if [ ${retval} -eq ${exp_ret} ] ; then
            print_count_ok_fail 0 ${counter}
        else
            print_count_ok_fail 1 ${counter}
        fi

        if [ ${rrmode} -eq 3 ] ; then
            if [ ${subfailcnt} -eq 0 ] ; then
                print_count_ok_fail 0
            else
                print_count_ok_fail 1
            fi
        fi

        print_run_cmd_logs ${subtestarg}
    fi

    if [ ${rrmode} -ne 0 ] ; then
        cursubtest=${subtest}
    fi

    last_cmd_retval=${retval}

    if [ ${rrmode} -ne 3 ] ; then
        test ${retval} -eq ${exp_ret}
        retval=$?
    else
        test ${subfailcnt} -eq 0
        retval=$?
    fi

    if [ ${stop_on_fail} -eq 1 -a ${retval} -ne 0 ] ; then
        exit 1
    fi

    return ${retval}
}


function run_ret_start() {
    run_ret -is "$@"
}


function run_ret_next() {
    run_ret -in "$@"
}


function run_ret_end() {
    run_ret -ie "$@"
}


# run command, abort script if return code doesn't match expectation
# args:
# expected_retval command [ args ... ]
function run_abort() {
    local exp_ret=$1
    local retval=0
    shift

    if [ "$1" == "-h" ] ; then
        echo "expected_retval command [ args ]"
        return 0
    fi

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
# globals:
# last_cmd_retval
# curtest : incremented by 1, if message given and subtest > 0 or not present
# okcnt   : incremented by 1, if message given and return value matches
# failcnt : incremented by 1, if message given and return value dose not match
function run_check_regex() {
    local exp_ret=$1
    local message="$2"
    local negate=0
    local regex=""
    local retval=0
    local isfail=1

    if [ "$1" == "-h" ] ; then
        echo "expected_retval message [ -n ] regex command [ args ]"
        return 0
    fi

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


# print value from set variable to stdout
# args:
# prefix id postfix [ intro ... ]
# prefix  : variable prefix, see example
# id      : object id, see example
# postfix : variable postfix, see example
# intro   : optional text to print befor value
#
# example: "pool p1 vdevs" will print the content of the variable "pool_p1_vdevs".
function get_val() {
    local name=''
    local intro=''

    if [ "$1" == "-h" ] ; then
        echo "prefix id postfix"
        return 0
    fi

    if [ "$1" == fs -o "$1" == file ] ; then
        name="$1_${2//[\/@]/_}_$3"
    else
        name="$1_$2_$3"
    fi

    if [ $# -gt 3 ] ; then
        shift
        shift
        shift
        echo "$*" "${!name}"
    else
        echo "${!name}"
    fi
}


# print set of variables for object instance
# args:
# object-type id attribute ...
# object-type : disk, pool, fs or file
# id          : object id
# attribute   : list of arrtibutes to print.
function print_object() {
    local i
    local id="$2"
    local prefix="$1"
    local attr=''

    if [ "$1" == "-h" ] ; then
        echo "object-type id attribute ..."
        return 0
    fi

    shift
    shift

    if [ $# -gt 0 ] ; then
        attr="$*"
    else
        if [ "${prefix}" == "file" ] ; then
            attr="name ghost fs relpath path"
        elif [ "${prefix}" == "fs" ] ; then
            attr="name fullname pool path"
        elif [ "${prefix}" == "pool" ] ; then
            attr="fullname vdevs path"
        elif [ "${prefix}" == "disk" ] ; then
            attr="disk attached path"
        fi
    fi

    for i in ${attr} ; do
        get_val ${prefix} "${id}" ${i} "${i} : "
    done
}

if [ -z "${genrand_bin}" ] ; then
    genrand_bin=$(dirname $0)/genrand
fi

function tests_func_init() {

    if [ ! -z "${tests_tmpdir}" ] ; then
        export TMPDIR=${tests_tmpdir}
    else
        tests_tmpdir=$(mktemp -d -t tests_maczfs_)
        export TMPDIR=${tests_tmpdir}
    fi

    if [ -z "${tests_logdir}" ] ; then
        tests_logdir=$(mktemp -d -t test_logs_maczfs_)
    fi

    if [ -z "${genrand_bin}" ] ; then
        genrand_bin=$(dirname $0)/genrand
    fi

    if [ ! -x "${genrand_bin}" ] ; then
        echo "Error: random number generator '${genrand_bin}' not found."
        echo "Did you compiled it? ('gcc -o genrand -O3 genrand.c' in the support folder.)"
    fi

    # initialize random data generator
    genrand_state=${tests_logdir}/randstate.txt
    ${genrand_bin} -s 13446 -S ${genrand_state}

    if [ ! -d "${diskstore}" ] ; then
        diskstore=$(mktemp -d -t diskstore_)
    fi

    if [ -z "${poolbase}" ] ; then
        poolbase=pool_$(date +%s)_$$
    fi

    cleanup=0
    failcnt=0
    okcnt=0
    subfailcnt=0
    subokcnt=0
    cursubtest=0
    tottests=0
    curtest=0

    stop_on_fail=0

    tests_func_init_done=1
}


function tests_func_cleanup() {
    local i
    local name
    local tmp_v
    local fsname

    stop_on_fail=0
    
    for ((i=0; i < poolsmax; i++)) ; do
        if [ "${pools[i]}" == "" ] ; then
            continue
        fi
        name="${pools[i]}"
        echo "Destroying pool '${name}'"
        destroy_pool ${name}
    done

    poolsmax=0

    fssmax=0
    fss[0]=''

    for ((i=0; i < filesmax; i++)) ; do
        if [ "${files[i]}" == "" ] ; then
            continue
        fi
        name="${files[i]}"
        tmp_v=file_${name}_fs
        fsname="${!tmp_v}"
        if [ "" != "${fsname}"  -a  "_temp_" != "${fsname}" ] ; then
            forget_file ${name}
        elif [ "_temp_" == "${fsname}" ] ; then
            remove_file ${name}
        fi
        echo "File '${name}'"
        print_object file "${name}" name path fs size
        echo
    done

    filesmax=0
    files[0]=''

    for ((i=0; i < disksmax; i++)) ; do
        if [ "${disks[i]}" == "" ] ; then
            continue
        fi
        name="${disks[i]}"
        
        tmp_v=disk_${name}_attached
        if [ "1" == "${!tmp_v}" ] ; then
            detach_disk ${name}
        fi
        echo "Deleting disk '${name}'"
        destroy_disk ${name}
    done

    disksmax=0
    disks=''

    unset tests_func_init_arr
    unset tests_func_init_done
}


function interact() {
    local prompttxt="(check)"
    local cmd
    local args

    if [ "$1" != "" ] ; then
        prompttxt="$1"
    fi

    read -e -p "${prompttxt} " cmd args
    while [ "${cmd}" != "q" ] ; do
        if [ "${cmd}" == "help" ] ; then
            cat <<EOF
make_disk()
destroy_disk()
list_disks()
new_temp_file()
new_fifo()
get_rand_number()
make_name()
make_pool()
destroy_pool()
list_pools()
make_fs()
make_clone_fs()
forget_fs()
list_fss()
zfs_send()
make_file()
list_files()
add_file()
copy_file()
remove_file()
clone_files()
forget_fs_files()
resurrect_file()
forget_file()
run_cmd()
attach_disk()
detach_disk()
run_cmd_log()
print_run_cmd_logs()
print_count_ok_fail()
run_ret()
run_ret_start()
run_ret_next()
run_ret_end()
run_abort()
run_check_regex()
get_val()
print_object()
tests_func_cleanup()

EOF
        elif [ -n "$cmd" ] ; then
            eval ${cmd} ${args}
        fi
        read -e -p "${prompttxt} " cmd args
    done
}


if [ -z "${tests_func_init_done:-}" ] ; then
    echo "run 'tests_func_init' to initialize test system."
fi

# End
