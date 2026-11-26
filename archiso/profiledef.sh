#!/usr/bin/env bash
# shellcheck disable=SC2034
# Modelo: os marcadores de branding são substituídos por scripts/assemble-profile.sh a partir de branding/brisa.conf.

iso_name="@BRISA_ID@"
iso_label="@BRISA_ID_UPPER@_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="@BRISA_NAME@"
iso_application="@BRISA_NAME@ Live"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/brisa-selftest"]="0:0:755"
  ["/etc/sudoers.d/brisa-live"]="0:0:440"
  ["/usr/lib/brisa/selftest.d/"]="0:0:755"
)
