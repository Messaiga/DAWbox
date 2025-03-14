#!/bin/sh

# Symlink distrobox shims
./distrobox-shims.sh

# Update the container and install packages
apt update
apt upgrade -y
grep -v '^#' ./dawbox.packages | xargs apt install -y
apt update
apt install kxstudio-meta-all -y