pkgname=libfprint-focaltech
pkgver=1.94.5
pkgrel=1
pkgdesc="FocalTech custom libfprint driver for 2808:a658"
arch=('x86_64')
url="https://github.com/Meetsuthar32778/2808-A658-fingerprint-arch-linux-driver"
license=('LGPL-2.1-or-later')
depends=('glib2' 'glibc' 'gcc-libs' 'libgudev' 'libgusb' 'nss' 'pixman' 'systemd-libs')
provides=('libfprint' 'libfprint-2.so=2-64')
conflicts=('libfprint' 'libfprint-2-2')
replaces=('libfprint-2-2')

prepare() {
  tar -I zstd -xf "$startdir/libfprint.pkg.tar.zst" -C "$srcdir"
  patchelf --clear-symbol-version g_usb_device_get_release \
           --clear-symbol-version g_usb_interface_get_class \
           --clear-symbol-version g_usb_interface_get_subclass \
           --clear-symbol-version g_usb_device_get_interfaces \
           --clear-symbol-version g_usb_interface_get_protocol \
           --clear-symbol-version g_usb_interface_get_number \
           "$srcdir/usr/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0"
}

package() {
  install -d "$pkgdir/usr/lib"
  install -m755 "$srcdir/usr/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0" "$pkgdir/usr/lib/"
  ln -s libfprint-2.so.2.0.0 "$pkgdir/usr/lib/libfprint-2.so.2"
  ln -s libfprint-2.so.2 "$pkgdir/usr/lib/libfprint-2.so"

  install -d "$pkgdir/usr/lib/udev/rules.d"
  install -m644 "$srcdir/usr/lib/udev/rules.d/60-libfprint-2.rules" "$pkgdir/usr/lib/udev/rules.d/"

  if ! grep -q 'a658' "$pkgdir/usr/lib/udev/rules.d/60-libfprint-2.rules"; then
    cat << 'RULE' >> "$pkgdir/usr/lib/udev/rules.d/60-libfprint-2.rules"

# FocalTech 2808:a658
SUBSYSTEM=="usb", ATTRS{idVendor}=="2808", ATTRS{idProduct}=="a658", ATTRS{dev}=="*", TEST=="power/control", ATTR{power/control}="auto", MODE="0660", GROUP="plugdev"
SUBSYSTEM=="usb", ATTRS{idVendor}=="2808", ATTRS{idProduct}=="a658", ENV{LIBFPRINT_DRIVER}="FocalTech Systems Co., Ltd Fingerprint"
RULE
  fi
}
