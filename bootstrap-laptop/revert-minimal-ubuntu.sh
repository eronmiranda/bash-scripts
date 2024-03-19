#!/bin/bash

set -euo pipefail

ME=$(basename "$0")

log() {
  >&2 echo "${ME}: $*"
}

die() {
  log "$@"
  exit 1
}

OS="$(uname)"
[[ "$OS" != "Linux" ]] && die  "Unsupported operating system ${OS}"

PACKAGES=(
aisleriot
baobab
branding-ubuntu
cheese
deja-dup
example-content
gir1.2-rb-3.0
gir1.2-totem-1.0
gir1.2-totemplparser-1.0
gnome-mahjongg
gnome-mines
gnome-sudoku
gnome-todo-common
gnome-video-effects
guile-2.0-libs
hyphen-en-us
libabw-0.1-1
libavahi-ui-gtk3-0
libdmapsharing-3.0-2
libexttextcat-2.0-0
libexttextcat-data
libfreehand-0.1-1
libgnome-games-support-1-3
libgnome-games-support-common
libgnome-todo
libmessaging-menu0
libmhash2
libminiupnpc10
libmwaw-0.3-3
libmythes-1.2-0
libnatpmp1
libneon27-gnutls
liborcus-0.13-0
libpagemaker-0.0-0
libraptor2-0
librasqal3
librdf0
libreoffice-avmedia-backend-gstreamer
libreoffice-base-core
libreoffice-calc
libreoffice-common
libreoffice-core
libreoffice-draw
libreoffice-gnome
libreoffice-gtk3
libreoffice-help-en-us
libreoffice-impress
libreoffice-math
libreoffice-ogltrans
libreoffice-pdfimport
libreoffice-style-breeze
libreoffice-style-galaxy
libreoffice-style-tango
libreoffice-writer
librhythmbox-core10
libtotem0
libvisio-0.1-1
libwpd-0.10-10
libwpg-0.3-3
libwps-0.4-4
libyajl2
mythes-en-us
python3-uno
remmina
remmina-common
remmina-plugin-rdp
remmina-plugin-secret
remmina-plugin-vnc
rhythmbox
rhythmbox-data
rhythmbox-plugin-alternative-toolbar
rhythmbox-plugins
shotwell
shotwell-common
simple-scan
thunderbird
thunderbird-gnome-support
thunderbird-locale-en
thunderbird-locale-en-us
totem
totem-common
totem-plugins
transmission-common
transmission-gtk
ubuntu-web-launchers
uno-libs3
ure
usb-creator-gtk
vino
zeitgeist-core
)

log "updating package lists..."
sudo apt-get update

log "reverting to minimal installation"
for package in "${PACKAGES[@]}"; do
  if ! dpkg -s "$package" &>/dev/null; then
    log "${package}: package is not installed, skipping..."
    continue
  fi

  log "${package}: removing package"
  sudo apt-get --assume-yes --purge autoremove "$package"
done

log "package removal complete!"
