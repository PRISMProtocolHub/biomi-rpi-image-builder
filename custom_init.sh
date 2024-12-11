#!/bin/bash
# Mount the host environment shared folder in QEMU
echo "=== Init script exists ==="

# Execute custom init script
if [[ -f /mnt/hostshare/init.sh ]];
  echo "Trigger custom init script..."
  then /mnt/hostshare/init.sh
fi