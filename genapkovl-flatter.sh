#!/bin/sh

tmp="$(mktemp -d /tmp/flatter-linux-ovl.XXXXXX)"
rootdir="$(mktemp -d /tmp/flatter-linux-root.XXXXXX)"
hostname=flatter

cleanup()
{
	rm -rf $tmp
	rm -rf $rootdir
}

trap cleanup EXIT

ifs=$IFS
pkg=''

strip()
{
	local i=0

	while [ $# -gt 0 ]; do
		case $1 in
		*[0-9][.]*|r[0-9]|r[0-9][0-9]) shift 1; continue;;
		*)
			if [ $i -eq 0 ]; then
				pkg="$1"
			else
				pkg="$pkg-$1"
			fi
			i=$((i + 1))
			;;
		esac
		shift 1
	done
}

add()
{
	IFS='-'; strip $@; IFS=$ifs
	apk add --root $rootdir $pkg
}

add_xf86_drivers()
{
	apk search | while read name; do
		case $name in
		xf86-video-*-doc*|xf86-video-*-dev*) continue;;
		xf86-input-*-doc*|xf86-input-*-dev*) continue;;
		xf86-video-*|xf86-input-*) add $name;;
		esac
	done
}

printf "\033[0;33m(flatter-linux)\033[0m prepare overlay\n"

mkdir $tmp/sbin
cat > $tmp/sbin/init << EOF
#!/bin/sh

printf "   \033[1;30mFlatter Linux\033[0m $(date)\n"

mkdir -p /.flatter
mount /media/cdrom/flatter-linux.img /.flatter

mkdir -p /.modules
mount /media/cdrom/boot/modloop-hardened /.modules

rm -fr /etc/*
cp -ra /.flatter/etc/* /etc/
sed -i 's/exec xterm/exec urxvt/g' /etc/fwm/.fwm/bin/main-menu
cp /etc/fwm/.fwm/bin/main-menu /etc/fwm/.fwm/panel/menu

adduser -D -s /bin/sh -k /etc/fwm -G fwm fwm
passwd -d fwm >/dev/null 2>&1
echo "PATH=\$PATH:/home/fwm/bin" >> /home/fwm/.profile
mv /home/fwm/.xinitrc-fwm /home/fwm/.xinitrc

echo 'include "/usr/share/themes/BSM Simple Dark Menu/gtk-2.0/gtkrc"' > /home/fwm/.gtkrc-2.0
echo 'gtk-icon-theme-name = "Faenza-Darker"' >> /home/fwm/.gtkrc-2.0

LD_LIBRARY_PATH=/.flatter/lib:/.flatter/usr/lib
export LD_LIBRARY_PATH

mkdir -p /var/cache/apk

dirs="bin sbin var/cache/apk"
for dir in \$dirs; do
	/.flatter/bin/busybox rm -fr /\$dir/*
	/.flatter/bin/busybox mount --bind /.flatter/\$dir /\$dir
done

rm -fr /usr/*
pwd=\$PWD
cd /.flatter/usr
for dir in *; do
	case \$dir in
	*share) continue;;
	esac
	mkdir -p /usr/\$dir
	mount --bind /.flatter/usr/\$dir /usr/\$dir
done

# setup-alpine expects /usr/share being writeable

cd /.flatter/usr/share
for dir in *; do
	mkdir -p /usr/share/\$dir
	mount --bind /.flatter/usr/share/\$dir /usr/share/\$dir
done
cd \$pwd

for item in /lib/*; do
	case \$item in
	*libc.musl*|*ld-musl*) continue;;
	esac
	rm -fr /\$item
done

read linux version kernel rest < /proc/version

mount --bind /.flatter/lib /lib

# setup-alpine expects /lib/apk being writeable

mkdir /.apk
cp -ra /lib/apk/* /.apk/
mount --bind /.apk /lib/apk

mount -ttmpfs -orw,nodev,nosuid,size=4096M tmpfs /lib/modules
mkdir -p /lib/modules/\$kernel
mount --bind /.modules/modules/\$kernel /lib/modules/\$kernel
mount --bind /.modules/modules/firmware /lib/firmware
mount -ttmpfs -orw,nodev,nosuid,size=4096M tmpfs /var/log

dbus-uuidgen > /etc/machine-id

echo "! black
*color0: #000000
*color8: #4d4d4d

! red
*color1: #707070
*color9: #ff6347

! green
*color2: #228b22
*color10: #09a709

! yellow
*color3: #cdcdb4
*color11: #817f21

! blue
*color4: #31609c
*color12: #505050

! magenta
*color5: #987595
*color13: #946566

! cyan
*color6: #2f4f4f
*color14: #4d6c6c

! white
*color7: #ffffff
*color15: #b3b3b3

*colorUL: LightSlateGrey
*colorBD: gray85

*colorMode: on
*dynamicColors: on

*background: #050505
*foreground: #efefef
*externalBorder: 1
*internalBorder: 6
*urgentOnBell: true
*saveLines: 10000
*cursorColor: darkgreen
*cursorBlink: true
*cursorOffTime: 1000
*cursorOnTime: 1000
*scrollBar: false
*scrollstyle: plain
*thickness: 1
*matcher.button: 3
*faceName: xft:mono:size=14
*font: xft:mono:regular:antohint=true:pixelsize=14
*boldFont: xft:mono:bold:antohint=true:pixelsize=14
*italicFont: xft:mono:italic:antohint=true:pixelsize=14
xscreensaver.Dialog.headingFont: -*-fixed-bold-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.Dialog.bodyFont: -*-fixed-medium-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.Dialog.labelFont: -*-fixed-medium-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.Dialog.unameFont: -*-fixed-medium-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.Dialog.buttonFont: -*-fixed-bold-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.Dialog.dateFont: -*-fixed-medium-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.passwd.passwdFont: -*-fixed-bold-r-*-*-14-*-*-*-*-*-*-*
xscreensaver.Dialog.foreground: #404040
xscreensaver.Dialog.background: #000000
xscreensaver.Dialog.topShadowColor: #151515
xscreensaver.Dialog.bottomShadowColor: #070707
xscreensaver.Dialog.Button.foreground: #505050
xscreensaver.Dialog.Button.background: #202020
xscreensaver.Dialog.text.foreground: #505050
xscreensaver.Dialog.text.background: #101010
xscreensaver.Dialog.internalBorderWidth: 1
xscreensaver.Dialog.borderWidth: 1
xscreensaver.Dialog.shadowThickness: 1
xscreensaver.passwd.thermometer.foreground: #464C69
xscreensaver.passwd.thermometer.background: #ffffff
xscreensaver.passwd.thermometer.width: 8
xscreensaver.dateFormat: %Y-%m-%d, %H:%M
xscreensaver.timeout: 10
xscreensaver.lock: true
xscreensaver.passwdTimeout: 15
xscreensaver.captureStderr: false
xscreensaver.fade: false
xscreensaver.splash: true
xscreensaver.newLoginCommand: /dev/null
xscreensaver.prefsCommand: /dev/null
" > /home/fwm/.Xdefaults
chown -R fwm.fwm /home/fwm

exec /.flatter/bin/busybox init
EOF
chmod 0755 $tmp/sbin/init

printf "\033[0;33m(flatter-linux)\033[0m make overlay image\n"
tar -v -c -C $tmp sbin | gzip -9n > flatter.apkovl.tar.gz

printf "\033[0;33m(flatter-linux)\033[0m prepare rootfs\n"

mkdir -p $rootdir/etc/network
cat > $rootdir/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto wlan0
EOF

#install -Dm644 /usr/share/mkinitfs/fstab $rootdir/etc/fstab
install -Dm644 /usr/share/mkinitfs/passwd $rootdir/etc/passwd
install -Dm644 /usr/share/mkinitfs/group $rootdir/etc/group

mkdir -p $rootdir/etc
echo $hostname > $rootdir/etc/hostname
echo "fwm:x:1001:fwm" >> $rootdir/etc/group

cat > $rootdir/etc/hosts << EOF
127.0.0.1 localhost
127.0.1.1 $hostname
EOF

apks="alpine-baselayout
alpine-conf
apk-tools
flatter-linux
bsm-simple-themes
rxvt-unicode
dbus
pcmanfm
viewnior
fwm
vim
sudo
strace
eudev
openrc
busybox
busybox-suid
musl-utils
util-linux
xorg-server
mesa-dri-swrast
ttf-dejavu
xinit
xscreensaver
xclip
xset
xsetroot
setxkbmap
openssh-client
openssh-server
firefox-esr
chromium
vim
desktop-file-utils
wireless-tools
wpa_supplicant"

cp -rav /etc/apk/ $rootdir/etc/
echo "$HOME/packages/flatter-linux" >> $rootdir/etc/apk/repositories
echo "$HOME/packages/fwm" >> $rootdir/etc/apk/repositories
apk add --root $rootdir --initdb flatter-linux
apk update --root $rootdir
apk add --no-scripts --root $rootdir busybox
mkdir -p $rootdir/bin $rootdir/sbin $rootdir/usr/bin $rootdir/usr/sbin $rootdir/lib/modules $rootdir/lib/firmware

busybox --list-full | while read plugin; do
	ln -sf /bin/busybox $rootdir/$plugin
done

ln -sf /bin/bbsuid $rootdir/usr/bin/vlock

for apk in $apks; do
	echo apk add --root $rootdir $apk
	apk add --root $rootdir $apk
done

add_xf86_drivers

defrc="local sshd wpa_supplicant"
for rc in $defrc; do
	ln -sf /etc/init.d/$rc $rootdir/etc/runlevels/default/
done

sysrc="devfs dmesg udev udev-postmount"
# udev-trigger --> FIXME: xorg freezes in qemu
for rc in $sysrc; do
	ln -sf /etc/init.d/$rc $rootdir/etc/runlevels/sysinit/
done

bootrc="bootmisc hostname hwclock keymaps modules sysctl syslog"
for rc in $bootrc; do
	ln -sf /etc/init.d/$rc $rootdir/etc/runlevels/boot/
done

find /usr/lib/gdk-pixbuf-*/ -name loaders.cache | while read path; do
	export GDK_PIXBUF_MODULE_FILE=$rootdir/$path
	echo gdk-pixbuf-query-loaders --update-cache $GDK_PIXBUF_MODULE_FILE
	gdk-pixbuf-query-loaders --update-cache
done

for theme in $rootdir/usr/share/icons/*; do
	if [ ! -e "$theme" ]; then
		continue
	fi

	gtk-update-icon-cache -q -t -f $theme
done

gtk-query-immodules-3.0 > $rootdir/etc/gtk-3.0/gtk.immodules
gdk-pixbuf-query-loaders > $rootdir/etc/gtk-3.0/gdk-pixbuf.loaders

gtk-query-immodules-2.0 > $rootdir/etc/gtk-2.0/gtk.immodules
gdk-pixbuf-query-loaders > $rootdir/etc/gtk-2.0/gdk-pixbuf.loaders

update-mime-database $rootdir/usr/share/mime
update-desktop-database $rootdir/usr/share/applications

printf "\033[0;33m(flatter-linux)\033[0m make rootfs image\n"
rm -f flatter-linux.img
mksquashfs $rootdir flatter-linux.img -all-root
