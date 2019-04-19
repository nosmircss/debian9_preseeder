#!/bin/bash
# 
# this will check that you have the dependencies installed
# will take the preseed from ../preseed/preseed.cfg and add it to the iso you supply
# change the boot menu to instantly boot the auto install
set -e
#verify required binaries are installed (md5sum, gzip, gunzip, genisoimage, isohybrid, udevil)
function dependency_check {

deplist=(md5sum gzip gunzip genisoimage isohybrid udevil)
for i in "${deplist[@]}"
  do
    if ! [ -x "$(command -v $i)" ]; then
      echo 'Error: '$i' is not installed.' >&2
      echo 'please install all deps' >&2 
      echo 'sudo apt-get install genisoimage udevil gzip syslinux-utils' >&2
      exit 1
    fi
done
}

######## MAIN #########

dependency_check

# $1 = preseed file
# $2 = iso file
# $3 = output iso name


isofile="$(basename -- $2)"
preseedfile="$(basename -- $1)"
echo mounting iso....
udevil mount $2 1>/dev/null
echo copying files....
cp -rT /media/$USER/$isofile/ isofiles/
chmod +w -R isofiles
echo gunzip initrd....
gunzip isofiles/install.amd/initrd.gz
echo install preseed....
/bin/cp -f $1 ./preseed.cfg
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
/bin/rm -f ./preseed.cfg
echo rezipping initrd....
gzip isofiles/install.amd/initrd
echo chmod -w isofiles/install.amd....
chmod -w -R isofiles/install.amd/
cd isofiles
echo md5sum....
chmod 666 md5sum.txt && md5sum `find -follow -type f` > md5sum.txt && chmod 444 md5sum.txt
cd ..
echo making iso....
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $3 isofiles
isohybrid $3
echo deleteing isofiles....
chmod +w -R isofiles && /bin/rm -rf isofiles
echo unmounting iso....
udevil unmount /media/$USER/$isofile
if [[ $EUID -eq 0 ]]; then
   echo ran as root, deleteing loopback....
   losetup -d /dev/loop0  
fi

exit 0


update isolinux.cfg with 1 sec timeout
change default line to "default auto"
