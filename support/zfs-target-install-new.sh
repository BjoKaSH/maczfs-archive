#! /bin/bash

while [ $# -gt 1 ] ; do
    if [ "$1" == "-i" ] ; then
        shift
        INSTBASE="$1"
        shift
        continue
    elif [ "$1" == "-u" ] ; then
        shift
        TARGET_SYS="$1"
        shift
        continue
    else
        echo "Unknown option '$1'"
        exit 1
    fi
done

if [ -z "${INSTBASE}" ] ; then
    read -p "path to install base (should contain the arch dirs 'x86_64', 'i386' ... : " INSTBASE
fi

if ! [ -d "${INSTBASE}/x86_64" -o -d "${INSTBASE}/i386" -o -d "${INSTBASE}/ppc" ] ; then
    echo "install base '${INSTBASE}' is not valid."
    exit 1
fi

if [ -z "${TARGET_SYS}" ] ; then
    read -p "Enter target user and machine as 'user@machine' " TARGET_SYS
fi

cp -p $(dirname $0)/zfs-target-install-new-remote.sh  ${INSTBASE}/
read -p "rsync -aH '${INSTBASE}' to '${TARGET_SYS}:'? (y/n)" ANS
if [ "${ANS}" != "y" ] ; then
    echo "Not confirmd."
    exit 1
fi
rsync -aH --stats  ${INSTBASE} ${TARGET_SYS}:

read -p "Run remote install script ? (y/n)" ANS
if [ "${ANS}" != "y" ] ; then
    echo "Not confirmd."
    exit 1
fi
ssh -t ${TARGET_SYS} $(basename ${INSTBASE})/zfs-target-install-new-remote.sh
