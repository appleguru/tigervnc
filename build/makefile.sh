# Makefile.osx
# Modified October 15, 2019 by Adam Urban
TOPDIR:=$(shell pwd)

.PHONY: sources

FLTK_VER:=1.3.5
FLTK_SUBVER:=""
GNUTLS_VER:=3.6.10
GETTEXT_VER:=0.19.8.1
LIBICONV_VER:=1.15
PKGCONFIG_VER:=0.29.2
ZLIB_VER:=1.2.11
GMP_VER:=6.1.2
NETTLE_VER:=3.5.1
LIBTASN1_VER:=4.14
LIBIDN_VER:=1.33

PREFIX=/opt/tigervnc

CC:=/usr/bin/llvm-gcc
CXX:=/usr/bin/llvm-g++
CPP:="/usr/bin/llvm-gcc -E"
CFLAGS:=-I$(PREFIX)/include -O2 -isysroot /Users/Shared/SDKs/MacOSX10.14.sdk -mmacosx-version-min=10.14 -m64
CXXFLAGS:=-I$(PREFIX)/include -O2 -isysroot /Users/Shared/SDKs/MacOSX10.14.sdk -mmacosx-version-min=10.14 -m64
CPPFLAGS:=-I$(PREFIX)/include -O2 -isysroot /Users/Shared/SDKs/MacOSX10.14.sdk -mmacosx-version-min=10.14 -m64
LDFLAGS:=-L$(PREFIX)/lib -isysroot /Users/Shared/SDKs/MacOSX10.14.sdk -mmacosx-version-min=10.14 -m64
PKG_CONFIG_PATH:=$(PREFIX)/lib/pkgconfig:${PKG_CONFIG_PATH}
PATH:=$(PREFIX)/bin:$(PATH)

all: dmg

src:
	rm -rf tigervnc-*
	tar xjf ../tigervnc-$(VERSION)$(SNAP:+-$(SNAP)).tar.bz2

sources:
	pushd SOURCES && \
	curl -OL https://gmplib.org/download/gmp/gmp-$(GMP_VER).tar.bz2 && \
	curl -OL https://ftp.gnu.org/gnu/nettle/nettle-$(NETTLE_VER).tar.gz && \
	curl -OL https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-$(GNUTLS_VER).tar.xz && \
	curl -OL http://fltk.org/pub/fltk/$(FLTK_VER)/fltk-$(FLTK_VER)$(FLTK_SUBVER)-source.tar.gz && \
	curl -OL https://ftp.gnu.org/gnu/libtasn1/libtasn1-$(LIBTASN1_VER).tar.gz && \
	curl -OL https://ftp.gnu.org/gnu/gettext/gettext-$(GETTEXT_VER).tar.gz && \
	curl -OL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(LIBICONV_VER).tar.gz && \
	curl -OL https://ftp.gnu.org/gnu/libidn/libidn-$(LIBIDN_VER).tar.gz && \
	curl -OL https://pkg-config.freedesktop.org/releases/pkg-config-$(PKGCONFIG_VER).tar.gz && \
	curl -OL http://zlib.net/zlib-$(ZLIB_VER).tar.gz

zlib: 
	rm -rf zlib-* && \
	tar xzf $(TOPDIR)/SOURCES/zlib-$(ZLIB_VER).tar.gz && \
	cd zlib-* && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --static --prefix=$(PREFIX) && \
	make && \
	sudo make install

libiconv: zlib
	rm -rf libiconv-* && \
	tar xzf $(TOPDIR)/SOURCES/libiconv-$(LIBICONV_VER).tar.gz && \
	cd libiconv-* && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --enable-static --disable-shared --prefix=$(PREFIX) && \
	make && \
	sudo make install

pkgconfig: libiconv
	rm -rf pkg-config-* && \
  	tar xzf $(TOPDIR)/SOURCES/pkg-config-$(PKGCONFIG_VER).tar.gz && \
	cd pkg-config-* && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --enable-static --disable-shared --prefix=$(PREFIX) --with-internal-glib && \
	make && \
	sudo make install

gettext: pkgconfig
	rm -rf gettext-* && \
	tar xzf $(TOPDIR)/SOURCES/gettext-$(GETTEXT_VER).tar.gz && \
	cd gettext-* && \
	autoreconf -fiv && \
	CC=$(CC) CXX=$(CXX) CPP="/usr/bin/llvm-gcc -E" CXXCPP="/usr/bin/llvm-g++ -E" CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --enable-static --disable-shared --prefix=$(PREFIX) --with-libiconv-prefix=$(PREFIX) --disable-java && \
	make && \
	sudo make install && \
	cd ../libiconv-* && \
	sudo make uninstall && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --enable-static --disable-shared --prefix=$(PREFIX) && \
	make && \
	sudo make install

gmp: gettext
	rm -rf gmp-* && \
	tar xjf $(TOPDIR)/SOURCES/gmp-$(GMP_VER).tar.bz2 && \
	cd gmp-* && \
	AWK=/usr/bin/awk CC=$(CC) CPP=$(CPP) CXX=$(CXX) CFLAGS="$(CFLAGS)" CPPFLAGS="$(CPPFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ABI=64 CC_FOR_BUILD=$(CC) ./configure --enable-static --disable-shared --prefix=$(PREFIX) --enable-cxx && \
	make && \
	make check && \
	sudo make install

nettle: gmp
	rm -rf nettle-* && \
	tar xzf $(TOPDIR)/SOURCES/nettle-$(NETTLE_VER).tar.gz && \
	cd nettle-* && \
	CC=$(CC) CPP=$(CPP) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS) -v" ./configure --enable-static --disable-shared --prefix=$(PREFIX) --disable-openssl && \
	make && \
	sudo make install

libidn: nettle
	rm -rf libidn-* && \
	tar xzf $(TOPDIR)/SOURCES/libidn-$(LIBIDN_VER).tar.gz && \
	cd libidn-* && \
	autoreconf -fiv && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --enable-static --disable-shared --prefix=$(PREFIX) && \
	make && \
	sudo make install

libtasn1: nettle
	rm -rf libtasn1-* && \
	tar xzf $(TOPDIR)/SOURCES/libtasn1-$(LIBTASN1_VER).tar.gz && \
	cd libtasn1-* && \
	autoreconf -fiv && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ./configure --enable-static --disable-shared --prefix=$(PREFIX) && \
	make && \
	sudo make install

gnutls: libtasn1
	rm -rf gnutls-* && \
	tar --xz -xf $(TOPDIR)/SOURCES/gnutls-$(GNUTLS_VER).tar.xz && \
	cd gnutls-* && \
	autoreconf -fiv && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS) -framework CoreFoundation -lintl -liconv" \
	./configure \
		--with-libiconv-prefix=$(PREFIX) \
		--with-libintl-prefix=$(PREFIX) \
		--with-libz-prefix=$(PREFIX) \
		--without-p11-kit \
		--disable-guile \
		--disable-srp-authentication \
		--prefix=$(PREFIX) \
		--enable-static \
		--disable-shared \
		--disable-libdane \
		--disable-doc \
		--enable-local-libopts \
		--without-tpm \
		--disable-dependency-tracking \
		--disable-silent-rules \
		--with-included-unistring \
		--disable-heartbeat-support && \
	make && \
	sudo make install

fltk:
	rm -rf fltk-*
	tar -xzf $(TOPDIR)/SOURCES/fltk-$(FLTK_VER)$(FLTK_SUBVER)-source.tar.gz
	cd fltk-* && \
	CC=$(CC) CXX=$(CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="-framework Cocoa $(LDFLAGS)" cmake -G"Unix Makefiles" \
  		-DCMAKE_INSTALL_PREFIX=$(PREFIX) \
  		-DCMAKE_BUILD_TYPE=Release \
  		-DOPTION_BUILD_EXAMPLES=off \
  		-DCMAKE_OSX_SYSROOT=/Users/Shared/SDKs/MacOSX10.14.sdk \
  		-DCMAKE_OSX_DEPLOYMENT_TARGET=10.14 \
  		-DOPTION_USE_SYSTEM_LIBPNG=0 \
  		-DOPTION_USE_SYSTEM_LIBJPEG=0 \
  		-DOPTION_USE_SYSTEM_ZLIB=0 \
  		. && \
	make && \
	sudo make install

prereqs: pkgconfig gettext gnutls fltk

dmg: 
	rm -rf tigervnc && \
	git clone https://github.com/appleguru/tigervnc.git && \
	cd tigervnc && \
	CC=$(CC) CXX=$(CXX) CFLAGS="-I/usr/local/Cellar/jpeg-turbo/2.0.3/include $(CFLAGS)" CXXFLAGS="-I/usr/local/Cellar/jpeg-turbo/2.0.3/include $(CXXFLAGS)" LDFLAGS="-framework Cocoa -framework Security $(LDFLAGS)" cmake -G"Unix Makefiles" \
  		-DJPEG_INCLUDE_DIR=/usr/local/Cellar/jpeg-turbo/2.0.3/include \
  		-DJPEG_LIBRARY=/usr/local/Cellar/jpeg-turbo/2.0.3/lib/libjpeg.a \
  		-DFLTK_INCLUDE_DIR=$(PREFIX)/include \
  		-DFLTK_BASE_LIBRARY=$(PREFIX)/lib/libfltk.a \
  		-DFLTK_IMAGES_LIBRARY=$(PREFIX)/lib/libfltk_images.a \
  		-DGNUTLS_INCLUDE_DIR=$(PREFIX)/include \
  		-DGNUTLS_LIBRARY="$(PREFIX)/lib/libgnutls.a;$(PREFIX)/lib/libtasn1.a;$(PREFIX)/lib/libnettle.a;$(PREFIX)/lib/libhogweed.a;$(PREFIX)/lib/libgmp.a;$(PREFIX)/lib/libz.a;$(PREFIX)/lib/libintl.a;$(PREFIX)/lib/libiconv.a" \
  		-DZLIB_INCLUDE_DIR=$(PREFIX)/include \
  		-DZLIB_LIBRARY=$(PREFIX)/lib/libz.a \
  		-DICONV_INCLUDE_DIR=$(PREFIX)/include \
  		-DICONV_LIBRARIES="$(PREFIX)/lib/libintl.a;$(PREFIX)/lib/libiconv.a" \
  		-DINTL_INCLUDE_DIR=$(PREFIX)/include \
  		-DLIBINTL_LIBRARY=$(PREFIX)/lib/libintl.a \
  		-DGETTEXT_INCLUDE_DIR=$(PREFIX)/include \
  		-DGETTEXT_MSGMERGE_EXECUTABLE=$(PREFIX)/bin/msgmerge \
  		-DGETTEXT_MSGFMT_EXECUTABLE=$(PREFIX)/bin/msgfmt \
  		-DBUILD_STATIC=off \
  		-DCMAKE_OSX_SYSROOT=/Users/Shared/SDKs/MacOSX10.14.sdk \
  		-DCMAKE_OSX_DEPLOYMENT_TARGET=10.14 \
  		. && \
	make && \
	make dmg

