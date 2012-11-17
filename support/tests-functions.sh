#! / bin/bash

### list of functions ###
#
# make_disk size_in_gb name [ band size ]
# globals: ${name}_attached, ${name}_disk, ${name}_size, ${name}_path
#
# new_temp_file [ -p ]
# stdout: filename, with path if "-p" given.
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
# command [ args .. ]
# globals:
# curtest : incremented by 1, if message given
function run_cmd_log() {
    ((curtest++))

    echo "$*"  >${tests_logdir}/test_${curtest}.cmd

    run_cmd  --outname ${tests_logdir}/test_${curtest}.out  --errname ${tests_logdir}/test_${curtest}.err  "$@"
}


# print a log previously captured by run_cmd_log.
#
# args:
function print_run_cmd_logs() {
    if [ -s ${tests_logdir}/test_${curtest}.out ] ; then
        echo "out:"
        gawk '{print " | " $0;}' <${tests_logdir}/test_${curtest}.out
    fi

    if [ -s ${tests_logdir}/test_${curtest}.err ] ; then
        echo "err:"
        gawk '{print " | " $0;}' <${tests_logdir}/test_${curtest}.err
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
# args:
# expected_retval message command [ args ]
# globals:
# last_cmd_retval : set to return value from command
# curtest : incremented by 1, if message given
# okcnt   : incremented by 1, if message given and return value matches
# failcnt : incremented by 1, if message given and return value dose not match
function run_ret() {
    local exp_ret=$1
    local message="$2"
    local retval=0
    shift
    shift

    if [ -z "${message}" ] ; then
        run_cmd "$@"
        retval=$?
    else
        echo -n "${message}"
        echo -n -e "\t "

        run_cmd_log "$@"
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
