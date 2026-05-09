#!/usr/bin/env bash
# VenomOS archiso profile definition

iso_name="venomos"
iso_label="VENOMOS"
iso_publisher="VenomOS Project"
iso_application="VenomOS — Intelligence. Precision. Persistence."
iso_version="1.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-ia32.grub.esp' 'uefi-x64.grub.esp' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--ultra' '-20' '--long')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/opt/venomOS/bin"]="0:0:755"
  ["/opt/venomOS/bin/venom-setup"]="0:0:755"
  ["/opt/venomOS/bin/venom-help"]="0:0:755"
  ["/opt/venomOS/bin/venom-vm"]="0:0:755"
  ["/opt/venomOS/bin/venom-install"]="0:0:755"
)
