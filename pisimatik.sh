repo=$1
kurpak=$2
dizin=kur
isodizin=iso_icerik
#temel chroot ortaminin olusturulmasi
python rootfs_olustur.py $dizin $repo &&

#gerekli servislerin baslatilmasi
chroot $dizin /bin/bash -c "rm -r /boot/boot"
chroot $dizin /bin/bash -c "service dbus on"
chroot $dizin /bin/bash -c "service dbus start"

#base sistemin kurulumu
#chroot $dizin /bin/bash -c "pisi -y it -c system.base"
chroot $dizin /bin/bash -c "pisi -y it kernel"
chroot $dizin /bin/bash -c "pisi rm mkinitramfs --ignore-safe --ignore-dep"

#dracut entegre1
rsync -av paket/dracut/* $dizin/var/cache/pisi/packages
chroot $dizin /bin/bash -c "pisi -y it /var/cache/pisi/packages/dracut*.pisi"
chroot $dizin /bin/bash -c "pisi -y it /var/cache/pisi/packages/lsinitrd*.pisi"
chroot $dizin /bin/bash -c "pisi -y it /var/cache/pisi/packages/mkinitrd*.pisi"

while read p; do
  chroot $dizin /bin/bash -c "pisi -y it ""$p"
done < $kurpak

#paket ayarlama
chroot $dizin /bin/bash -c "pisi cp"
rm -r $dizin/boot/initramfs*
#mevcut parola dosyasinin aktarilmasi
mv $dizin/etc/shadow $dizin/etc/shadow.orj
cp /etc/shadow $dizin/etc/

#dns sunucu ayarlama
mv $dizin/etc/resolv.conf $dizin/etc/resolv.conf.orj
cp /etc/resolv.conf $dizin/etc/

umount $dizin/proc
umount $dizin/sys
rm -r -f $dizin/dev
mkdir -p $dizin/dev
mknod -m 600 $dizin/dev/console c 5 1
mknod -m 666 $dizin/dev/null c 1 3
mknod -m 666 $dizin/dev/random c 1 8
mknod -m 666 $dizin/dev/urandom c 1 9
chmod 777 $dizin/tmp
#mkinitramfs eski
#touch $dizin/etc/initramfs.conf
#echo "liveroot=LABEL=PisiLive" > $dizin/etc/initramfs.conf
echo "exec openbox-session" > $dizin/root/.xinitrc
rsync -av $dizin/var/cache/pisi/packages/* paket/
rm -r -f $dizin/var/cache/pisi/packages/*
rm -r -f $dizin/tmp/*

#mkinitramfs eski
#chroot $dizin /bin/bash -c "mkinitramfs"
#dracut entegre2
chroot $dizin /bin/bash -c "dracut /boot/initramfs.img 3.19.8"

mv $dizin/boot/kernel* $isodizin/boot/kernel
mv $dizin/boot/initramfs* $isodizin/boot/initrd
#eski vers.
#mksquashfs $dizin $isodizin/boot/pisi.sqfs
./squash.sh
genisoimage -l -V PisiLive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -o milis_pisi2.0.iso $isodizin && isohybrid milis_pisi2.0.iso
