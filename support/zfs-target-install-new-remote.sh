#! /bin/bash


INSTBASE=$(dirname $0)
arch=$(uname -m)
read -p "Install arch '${arch}' into system root ? (y/n) " ANS
if [ "${ANS}" == "y" ] ; then
    if [ -d "${INSTBASE}/${arch}" ] ; then
        sudo chown -R root:wheel ${INSTBASE}
        sudo ditto ${INSTBASE}/${arch}/ /
        sudo touch /System/Library/Extensions
        sudo chown -R $(id -u):$(id -g) ${INSTBASE}
        read -p "Load kext? (y/n) " ANS
        if [ "${ANS}" == "y" ] ; then
            sudo kextload /System/Library/Extensions/zfs.kext
            kextstat
        else
            echo "Load not confirmed."
        fi
    else
        echo "Host architecture '${arch}' not found in '${INSTBASE}'."
    fi
else
    echo "Copy to system root not confirmed."
fi
