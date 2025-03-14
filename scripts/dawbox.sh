#!/bin/sh

# Symlink distrobox shims
./distrobox-shims.sh

# Update the container and install packages
dpkg -i kxstudio-repos_11.2.0_all.deb
apt update
apt upgrade -y
grep -v '^#' ./dawbox.packages | xargs apt install -y
apt install kxstudio-meta-all -y