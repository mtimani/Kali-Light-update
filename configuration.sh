#!/bin/bash

#changement de la langue du clavier en FR
echo "setxkbmap fr" | tee -a /etc/init.d/rc.local

img_desktop="/usr/share/images/desktop-base/"
mv ${img_desktop}default ${img_desktop}default.old
cp configuration/images/* ${img_desktop}
chmod 644 ${img_desktop}*.png
chmod 644 ${img_desktop}*.jpg

# grub
grub="/usr/share/images/desktop-base/grub-background.jpg"
echo "GRUB_BACKGROUND='$grub'" | tee -a /etc/default/grub

grub_color="/etc/grub.d/05_debian_theme"
old_color='		echo "  true"'
new_color='#		echo "  true"\
		echo "    set color_highlight=white\/dark-gray"\
		echo "    set color_normal=light-gray\/black"'
sed -i -e "s/${old_color}/${new_color}/" ${grub_color}

update-grub

# Configuration du réseau
rm -rf /etc/NetworkManager/system-connections/*
cp -r configuration/network/* /etc/NetworkManager/system-connections/
chmod 600 /etc/NetworkManager/system-connections/*
nmcli con reload
