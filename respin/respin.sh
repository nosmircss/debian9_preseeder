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
      echo 'please install all deps apt-get install genisoimage udevil gzip md5sum' >&2
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
udevil mount $2
cp -rT /media/$USER/$isofile/ isofiles/
chmod +w -R isofiles/install.amd/
gunzip isofiles/install.amd/initrd.gz
/bin/cp -f $1 ./preseed.cfg
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
/bin/rm -f ./preseed.cfg
gzip isofiles/install.amd/initrd
chmod -w -R isofiles/install.amd/
cd isofiles
md5sum `find -follow -type f` > md5sum.txt
cd ..
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $3 isofiles
isohybrid $3
chmod +w -R isofiles
rm -r isofiles
udevil unmount /media/$USER/$isofile
losetup -d /dev/loop0  

exit 0


update isolinux.cfg with 1 sec timeout
change default line to "default auto"
