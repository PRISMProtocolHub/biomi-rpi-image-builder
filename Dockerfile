# Create the raspberry OS image for SDCard, output gzipped in $BUILD_DIR/raspios.qcow2.gz
FROM debian:latest
ARG DEBIAN_FRONTEND="noninteractive"

ARG BUILD_DIR=/build
ARG DISTRO_DATE_FOLDER=2022-09-26
ARG DISTRO_DATE=2022-09-22
ARG DISTRO_NAME=bullseye
ARG DISTRO_IMAGE_OUTPUT_FILE_NAME=raspios
ARG DISTRO_IMAGE_TYPE=full
ARG DISTRO_FILE="${DISTRO_DATE}-raspios-${DISTRO_NAME}-arm64-${DISTRO_IMAGE_TYPE}.img"
ARG FULL_DISTRO_IMAGE_TYPE="raspios_${DISTRO_IMAGE_TYPE}_arm64"
ARG DISTRO_IMG="https://downloads.raspberrypi.com/${FULL_DISTRO_IMAGE_TYPE}/images/${FULL_DISTRO_IMAGE_TYPE}-${DISTRO_DATE_FOLDER}/${DISTRO_FILE}.xz"

# Add docker repository
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

# Install regular dependencies
RUN apt-get update && apt-get install -y  \
    qemu-user-static \
    libguestfs-tools \
    libssl-dev \
    wget \
    openssl \
    linux-image-generic \
    xz-utils && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/locale/*


# Download and extract image
WORKDIR /tmp
RUN wget -nv -O $DISTRO_FILE.xz $DISTRO_IMG \
    && unxz $DISTRO_FILE.xz \
    && mkdir -p /mnt/root /mnt/boot

RUN guestfish add $DISTRO_FILE : run : mount /dev/sda1 / : copy-out / /mnt/boot : umount / : mount /dev/sda2 / : copy-out / /mnt/root \
    && rm $DISTRO_FILE

COPY config/fstab /mnt/root/etc/
COPY config/cmdline.txt /mnt/boot/
COPY config/99-qemu.rules /mnt/root/etc/udev/rules.d/
COPY config/login.conf /mnt/root/etc/systemd/system/serial-getty@ttyAMA0.service.d/override.conf
COPY config/dphys-swapfile /etc/dphys-swapfile

COPY custom_init.sh /mnt/root/usr/local/bin/custom_init.sh
RUN chmod +x /mnt/root/usr/local/bin/custom_init.sh

RUN sed -i '/exit 0/i /usr/local/bin/custom_init.sh &' /mnt/root/etc/rc.local && \
    chmod +x /mnt/root/etc/rc.local

RUN touch /mnt/boot/ssh \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /mnt/root/etc/ssh/sshd_config \
    && sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /mnt/root/etc/ssh/sshd_config \
    && sed -i 's/^root:\\*:/root::/' /mnt/root/etc/shadow \
    && sed -i '/^pi/d' /mnt/root/etc/shadow \
    && sed -i '/^pi/d' /mnt/root/etc/passwd \
    && sed -i '/^pi/d' /mnt/root/etc/group \
    && rm -r /mnt/root/home/pi \
    && mkdir -p /mnt/root/etc/systemd/system/serial-getty@ttyAMA0.service.d/ \
    && rm -f /mnt/root/usr/lib/systemd/system/userconfig.service \
    && rm -f /mnt/root/etc/systemd/system/multi-user.target.wants/userconfig.service

# Create final image
WORKDIR $BUILD_DIR
ARG DIST_IMAGE_PATH=$BUILD_DIR/distro.img
RUN cp /mnt/boot/kernel8.img $BUILD_DIR/kernel8.img \
  && cp /mnt/boot/bcm2710-rpi-zero-2-w.dtb $BUILD_DIR/bcm2710-rpi-zero-2-w.dtb

RUN guestfish -N $DIST_IMAGE_PATH=bootroot:vfat:ext4:2G \
    && guestfish add $DIST_IMAGE_PATH : run : mount /dev/sda1 / : glob copy-in /mnt/boot/* / : umount / : mount /dev/sda2 / : glob copy-in /mnt/root/* / \
    && sfdisk --part-type $DIST_IMAGE_PATH 1 c \
    && qemu-img convert -f raw -O qcow2 $DIST_IMAGE_PATH $BUILD_DIR/$DISTRO_IMAGE_OUTPUT_FILE_NAME.qcow2 \
    && gzip $BUILD_DIR/$DISTRO_IMAGE_OUTPUT_FILE_NAME.qcow2 \
    && gzip $DIST_IMAGE_PATH