FROM --platform=linux/riscv64 riscv64/ubuntu:22.04
ARG TOOLS_DEB=machine-emulator-tools-v0.14.0.deb

RUN <<EOF
# Update system
apt-get update && apt-get upgrade -y

# Install busybox
apt-get install -y busybox-static

# Install python3
apt-get install -y python3 python3-pip

# Install network tools
apt-get install -y iproute2

# Make build more or less reproducible
rm -rf /var/lib/apt/lists/* /var/log/*
EOF

# Install emulator tools
ADD ${TOOLS_DEB} /tmp/
RUN <<EOF
dpkg -i /tmp/${TOOLS_DEB}
rm -f /tmp/${TOOLS_DEB}
EOF

# Replace machine name
RUN echo guest-machine > /etc/hostname

# Add dapp
RUN mkdir /dapp
ADD ./.external/dapp/dapp_guest.py /dapp/dapp.py
ADD ./.external/dapp/requirements_guest.txt /dapp/requirements.txt
RUN pip3 install -r /dapp/requirements.txt
