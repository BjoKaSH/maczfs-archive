#! /bin/bash

#
# This script gathers information about the installed version auf MacZFS
#
    set -x -v

# config
PKGTOOL=pkgutil
OUTFILE=collect-mazfs-state-info.txt
TMPFILE=$(mktemp collect-mazfs-state-info.XXXXXX)
function run_cmd() {
    set -x -v
    local msg="$1";
    shift

    echo "" >> ${OUTFILE}
    echo "${msg}"  >> ${OUTFILE}
    echo "# $*"  >> ${OUTFILE}

    {
        if [ "${1}" == "-r" ] ; then
            sudo $*  >> ${OUTFILE}  
        else
            eval $* >> ${OUTFILE}
        fi
    } 2> ${TMPFILE}
    if [ -s ${TMPFILE} ] ; then
        # tmp file (holds stderr) has non-zero length
        echo ""  >> ${OUTFILE}
        echo "STDERR"  >> ${OUTFILE}
        cat ${TMPFILE}  >> ${OUTFILE}
        # truncate file
        cat </dev/null >${TMPFILE}
    fi
}


function scan_plist() {
    local file="$1"
    shift
    local key
    local line
    local found=0
    if [ ! -r "${file}" ] ; then
        echo "file '${file}' not found or not readable."  >> ${OUTFILE}
        return 0
    fi
    echo "${file}:"  >> ${OUTFILE}
    while read line ; do
        if [ ${found} -eq 1 ] ; then
            echo " ${key} : $(expr "${line}" : ".*<[^>][^>]*>\([^<][^<]*\)<")"
        fi
        found=0
        for key in $* ; do
            if expr "${line}" : "${key}" >/dev/null ; then
                found=1
                break;
            fi
        done
    done < "${file}"  >> ${OUTFILE}
    echo "------"  >> ${OUTFILE}
}


# find installed version(s)
run_cmd "Looking for ZFS packages"  "${PKGTOOL} --pkgs | grep -e zfs -e ZFS -e ZEVO -e zevo"

# iterate over installed packages and collect all installed zfs binaries
# all packages
pkgs=($(${PKGTOOL} --pkgs | grep -e zfs -e ZFS -e zevo -e ZEVO))
if [ ! -z "${pkgs[0]}" ] ; then
    # all files
    for p in "${pkgs[@]}" ; do
        ${PKGTOOL}  --files ${p}
    done | sort -u >${TMPFILE}
    echo ""  >> ${OUTFILE}
    if [ -s ${TMPFILE} ] ; then
        echo "List of ZFS related files and directories in package database"  >> ${OUTFILE}
        echo "-->>>>--"  >> ${OUTFILE}
        cat ${TMPFILE}  >> ${OUTFILE}
        echo "--<<<<--"  >> ${OUTFILE}
        # check which file exist in the file system
        echo ""  >> ${OUTFILE}
        echo "List of ZFS related files in package database and present in the file system"  >> ${OUTFILE}
        echo "-->>>>--"  >> ${OUTFILE}
        kextcnt=0
        fscnt=0
        libcnt=0
        cmdcnt=0
        while read f ; do
            for prefix in "" / /System/Library/Extensions/  /System/Library/Filesystems/  /Library/Extensions/  /Library/Filesystems/ ; do
                n="${prefix}${f}"
                if [ -f "${n}" ] ; then
                    ls -l "$n"
                    if expr "${n}" : ".*bin/" >/dev/null ; then
                        cmdlist[${cmdcnt}]="${n2}"
                        cmdpathlist[${cmdcnt}]="${n}"
                        ((cmdcnt++))
                    fi
                fi
                if  [ -f "${n}" -o -d "${n}" ] ; then
                    n2="${n##*/}"
                    n3="${n2##.}"
                    case "${n3}" in
                    (kext)
                        kextlist[${kextcnt}]="${n2}"
                        kextpathlist[${kextcnt}]="${n}"
                        ((kextcnt++))
                        ;;
                    (fs)
                        fslist[${fscnt}]="${n2}"
                        fspathlist[${fscnt}]="${n}"
                        ((fscnt++))
                        ;;
                    (dylib)
                        liblist[${libcnt}]="${n2}"
                        libpathlist[${libcnt}]="${n}"
                        ((libcnt++))
                        ;;
                    esac
                fi
            done
        done <${TMPFILE}  >> ${OUTFILE}
        echo "--<<<<--"  >> ${OUTFILE}
        cat </dev/null  > ${TMPFILE}
    else
        echo "No ZFS related files in package database"  >> ${OUTFILE}
    fi
else
    echo ""  >> ${OUTFILE}
    echo "No ZFS related packages in database"  >> ${OUTFILE}
fi

# try to get version info from files found so far
if [ ${kextcnt} -gt 0 ] ; then
    echo ""  >> ${OUTFILE}
    echo "Looking for version info in found kext"  >> ${OUTFILE}
    for i in "${kextpathlist[@]}" ; do
        scan_plist ${i}/Contents/Info.plist  CFBundleIdentifier  CFBundleName  CFBundleShortVersionString  CFBundleVersion
        for i2 in ${i}/Contents/MacOS/* ; do
            echo " ${i2} : $(strings ${i2} | grep -e VERSION -e BUILT -e PROG  >> ${OUTFILE})"
        done
    done
fi

if [ ${cmdcnt} -gt 0 ] ; then
    echo ""  >> ${OUTFILE}
    echo "Looking for version info in found zfs tools"  >> ${OUTFILE}
    for i in "${cmdpathlist[@]}" ; do
        echo " ${i} : $(strings ${i} | grep -e VERSION -e BUILT -e PROG  >> ${OUTFILE})"
    done
fi

if [ ${libcnt} -gt 0 ] ; then
    echo ""  >> ${OUTFILE}
    echo "Looking for version info in found libraries"  >> ${OUTFILE}
    for i in "${libpathlist[@]}" ; do
        echo " ${i} : $(strings ${i} | grep -e VERSION -e BUILT -e PROG  >> ${OUTFILE})"
    done
fi

run_cmd "Looking for other zfs binaries"  "find /usr/bin /usr/sbin /bin /sbin /usr/local /opt/local '(' -iname zfs -o -iname zpool -o -iname zdb -o -iname ztest -o -iname 'libzfs*' -o -iname 'libzpool*' ')' -a -type f -a -ls"

run_cmd "Looking for loaded kexts"  "kextstat | grep -e zfs -e ZFS -e ZEVO -e zevo -e spl -e com.greenbyte -e com.bandlem"

rm ${TMPFILE}

echo "Done."
echo
echo "You may examine to log file at '${OUTFILE}' (current directory: $(pwd))"
echo "and then attach it to your problem report at 'http://code.google.com/p/maczfs/issues/'."
echo

# End
