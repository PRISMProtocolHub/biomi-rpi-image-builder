#!/bin/bash

# Mount the host environment shared folder in QEMU
#mount -t 9p -o trans=virtio hostshare /mnt/hostshare
#mkdir -p /mnt/hostshare

# Execute custom init script
if [[ -f /mnt/hostshare/init.sh ]];
  then /mnt/hostshare/init.sh
fi