#! /bin/bash

#
# This script gathers information about the installed version auf MacZFS
#
#    set -x -v

# config
PKGTOOL=pkgutil
OUTFILE=collect-mazfs-state-info.txt
TMPFILE=$(mktemp collect-mazfs-state-info.XXXXXX)
TMPFILE2=$(mktemp collect-mazfs-state-info-2.XXXXXX)
function run_cmd() {
#    set -x -v
    local msg="$1"
    local keep=0
    local var=""
    local root=0
    local suml=""
    local resultarr
    shift

    echo "${msg}"
    echo "" >> ${OUTFILE}
    echo "${msg}"  >> ${OUTFILE}
    echo "# $*"  >> ${OUTFILE}

    while [ "${1:0:1}" == "-" ] ; do
        if [ "${1}" == "-k" ] ; then
            keep=1
            shift
        elif [ "${1}" == "-r" ] ; then
            root=1
            shift
        elif [ "${1}" == "-v" ] ; then
            shift
            var="${1}"
            shift
        elif [ "${1}" == "-sl" ] ; then
            shift
            suml="${1}"
            shift
        else
            echo "Internal error"  | tee -a ${OUTFILE}
            rm ${TMPFILE}  ${TMPFILE2}
            exit 1
        fi
    done

    {
        if [ ${root} -eq 1 ] ; then
            sudo $*  | tee  ${TMPFILE2}  >> ${OUTFILE}
        else
            eval $*  | tee  ${TMPFILE2}  >> ${OUTFILE}
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
    resultarr=($(wc -l ${TMPFILE2}))
    # global variable:
    resultlines=${resultarr[0]}
    if [ ! -z "${suml}" ] ; then
        printf "${suml}\n"  ${resultlines}  | tee -a ${OUTFILE}
    fi
    if [ ! -z "${var}" ] ; then
        eval ${var}=\(\$\(cat ${TMPFILE2}\)\)
    fi
    if [ ${keep} -eq 0 ] ; then
        cat </dev/null >${TMPFILE2}
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

# system version
run_cmd "Determinig system version"  "uname -a"

# find installed version(s)
run_cmd "Looking for ZFS packages" -v pkgs -sl "Found %d packages" "${PKGTOOL} --pkgs | grep -e zfs -e ZFS -e ZEVO -e zevo"

# iterate over installed packages and collect all installed zfs binaries
# all packages
echo "Looking for installed ZFS modules and tools from packages ..."
#pkgs=($(${PKGTOOL} --pkgs | grep -e zfs -e ZFS -e zevo -e ZEVO))
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
                    n2="${n##*/}"
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
                        ls -ld "$n"
                        kextlist[${kextcnt}]="${n2}"
                        kextpathlist[${kextcnt}]="${n}"
                        ((kextcnt++))
                        ;;
                    (fs)
                        ls -ld "$n"
                        fslist[${fscnt}]="${n2}"
                        fspathlist[${fscnt}]="${n}"
                        ((fscnt++))
                        ;;
                    (dylib)
                        # "ls -l" done in first "if" block
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
        echo "Found ${libcnt} ZFS related libraries, ${kextcnt} ZFS kernel modules and ${cmdcnt} ZFS tools." | tee -a ${OUTFILE}
    else
        echo "No ZFS related files in package database"  | tee -a ${OUTFILE}
    fi
else
    echo ""  >> ${OUTFILE}
    echo "No ZFS related packages in database"  | tee -a ${OUTFILE}
fi

# try to get version info from files found so far
if [ ${kextcnt} -gt 0 ] ; then
    echo ""  >> ${OUTFILE}
    echo "Looking for version info in ${kextcnt} found kext" | tee -a ${OUTFILE}
    for i in "${kextpathlist[@]}" ; do
        scan_plist ${i}/Contents/Info.plist  CFBundleIdentifier  CFBundleName  CFBundleShortVersionString  CFBundleVersion
        for i2 in ${i}/Contents/MacOS/* ; do
            echo " ${i2} : $(strings ${i2} | grep -e VERSION -e BUILT -e PROG  >> ${OUTFILE})"
        done
    done
fi

if [ ${cmdcnt} -gt 0 ] ; then
    echo ""  >> ${OUTFILE}
    echo "Looking for version info in ${cmdcnt} found zfs tools" | tee -a ${OUTFILE}
    for i in "${cmdpathlist[@]}" ; do
        echo " ${i} : $(strings ${i} | grep -e VERSION -e BUILT -e PROG  >> ${OUTFILE})"
    done
fi

if [ ${libcnt} -gt 0 ] ; then
    echo ""  >> ${OUTFILE}
    echo "Looking for version info in ${libcnt} found libraries"  | tee -a  ${OUTFILE}
    for i in "${libpathlist[@]}" ; do
        echo " ${i} : $(strings ${i} | grep -e VERSION -e BUILT -e PROG  >> ${OUTFILE})"
    done
fi

run_cmd "Looking for other zfs binaries" -k -sl "Found %d other ZFS files" "find /usr/bin /usr/sbin /bin /sbin /usr/local /opt/local '(' -iname zfs -o -iname zpool -o -iname zdb -o -iname ztest -o -iname 'libzfs*' -o -iname 'libzpool*' ')' -a -type f -a -ls"

run_cmd "Looking for loaded kexts"  "kextstat | grep -e zfs -e ZFS -e ZEVO -e zevo -e spl -e com.greenbyte -e com.bandlem"

echo "looking for panic reports"
# Determine OS X version
osxrel_str=$(uname -r)
osxrel=$(expr ${osxrel_str} : '[0-9]*\.\([0-9][0-9]*\)')
if [ ${osxrel} -eq 5 ] ; then
	# For 10.5 systems
	PANICS='/Library/Logs/PanicReporter'
else
	# All else
	PANICS='/Library/Logs/DiagnosticReports'
fi

panicCnt=0
panicCntTot=0
for i in x $(ls -tr "${PANICS}" ) ; do
    if [ "${i}" == "x" ] ; then
        continue
    fi
    if [ ! -f "${PANICS}/${i}" ] ; then
        continue
    fi
    ((panicCntTot++))
    if grep -e 'zfs' "${PANICS}/${i}" >/dev/null ; then
        echo "   ${i}"
        echo "" >>${OUTFILE}
        ls -l  "${PANICS}/${i}" >>${OUTFILE}
        echo "-->>>>--"  >> ${OUTFILE}
        cat "${PANICS}/${i}" >>${OUTFILE}
        echo "--<<<<--"  >> ${OUTFILE}
        ((panicCnt++))
    fi
done
if [ ${panicCntTot} -eq 0 ] ; then
    echo "No Panic logs found."
else
    echo "Found ${panicCnt} MacZFS related panic logs out of ${panicCntTot} recorded panics."
fi

rm ${TMPFILE}

echo "Done."
echo
echo "You may examine the log file at '${OUTFILE}' (current directory: $(pwd))"
echo "and then attach it to your problem report at 'http://code.google.com/p/maczfs/issues/'."
echo

# End