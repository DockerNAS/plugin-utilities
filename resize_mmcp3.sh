#!/bin/sh

mmc="/dev/mmcblk0"
partnum="3"
part="p${partnum}"
mmcpart="${mmc}${part}"

# Check to see if partition is last partition
lastpart=$(parted ${mmc} -ms unit s p | tail -n 1 | cut -f 1 -d:)

if [ "${lastpart}" != "${partnum}" ]; then
  echo "${mmcpart} is not the last partition."
  exit 2
fi

# Get the starting offset of the partition
start=$(parted ${mmc} -ms unit s p | grep "^${partnum}" | cut -f 2 -d:)
[ "${start}" ] || exit 3

# Unmount partition
umount ${mmcpart}

# Resize partition
fdisk ${mmc} <<EOF
p
d
${partnum}
n
p
${partnum}
${start}

w
EOF

# Check for changes
partprobe

# fsck filesystem
e2fsck -f ${mmcpart}

# Resize filesystem
echo "Resizing the filesystem will take a few minutes or longer."
resize2fs ${mmcpart}

# Mount partition
mount ${mmcpart}

# Remove command to execute script from startup
sed -i '/^\/root\/resize_mmcp3.sh/d' /etc/rc.local
