ifeq ($(ARCH),)
ARCH = x86_64
endif

pwd = $(PWD)
mkimage = ./mkimage.sh --tag edge --outdir $(pwd)/tmp --arch $(ARCH) --profile flatter
mkimage += --repository http://dl-cdn.alpinelinux.org/alpine/edge/main
#mkimage += --extra-repository ~/packages/fwm
#mkimage += --extra-repository ~/packages/flatter-linux
#mkimage += --extra-repository http://nl.alpinelinux.org/alpine/latest-stable/community

pkg = flatter-linux
ver = 0.1.0
apkbuild = \# Contributor: Aliaksei Katovich <aliaksei.katovich at gmail.com>\n
apkbuild += \# Maintainer: Aliaksei Katovich <aliaksei.katovich@gmail.com>\n
apkbuild += pkgname=$(pkg)\n
apkbuild += pkgver=$(ver)\n
apkbuild += pkgrel=0\n
apkbuild += pkgdesc=\"Flatter Linux\"\n
apkbuild += url=\"./\"\n
apkbuild += arch=\"noarch\"\n
apkbuild += license=\"GPL2\"\n
apkbuild += source=\"\$$pkgname-\$$pkgver.tar.gz\"\n
apkbuild += builddir=\"\$$srcdir/\"\n
apkbuild += check() { echo \"check ok\"; }\n
apkbuild += package() { mkdir -p \$$pkgdir; echo \"package ok\"; }\n

postinst = \#!/bin/sh\n
postinst += addgroup -S fwm 2>/dev/null\n
postinst += adduser -k /etc/fwm -D fwm\n
postinst += addgroup fwm fwm 2>/dev/null\n
postinst += exit 0\n

mkimg = profile_flatter() {\n
mkimg += PATH=./:\$$PATH
mkimg += export PATH
mkimg += title=\"Flatter Linux\"\n
mkimg += desc=\"Alpine Linux + Flatter window manager\"\n
mkimg += profile_base\n
mkimg += image_ext=\"iso\"\n
mkimg += output_format=\"iso\"\n
mkimg += arch=\"$(ARCH)\"\n
mkimg += kernel_cmdline=\"nomodeset\"\n
mkimg += kernel_addons=\"xtables-addons\"\n
mkimg += apkovl=\"genapkovl-flatter.sh\"\n
mkimg += hostname=\"$(pkg)\"\n
mkimg += }\n
workdir = aports/scripts

all:
	@mkdir -p tmp; \
	cd tmp; \
	if [ ! -d aports ]; then \
		git clone git://git.alpinelinux.org/aports; \
	fi; \
	printf "$(apkbuild)" > APKBUILD; \
	printf "$(postinst)" > $(pkg).post-install; \
	chmod 0755 $(pkg).post-install; \
	printf "$(mkimg)" > $(workdir)/mkimg.flatter.sh; \
	chmod 0755 $(workdir)/mkimg.flatter.sh; \
	cp -v ../genapkovl-flatter.sh $(workdir)/; \
	chmod 0755 $(workdir)/genapkovl-flatter.sh; \
	mkdir -p $(pkg)-$(ver); \
	tar cfz $(pkg)-$(ver).tar.gz $(pkg)-$(ver); \
	abuild checksum && abuild -r; \
	cd $(workdir); \
	$(mkimage); \
