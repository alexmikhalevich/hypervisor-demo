FROM --platform=$BUILDPLATFORM ubuntu:22.04 as cross-builder
ENV BUILD_BASE=/tmp/build-extra
ENV LIBFDT_DIR=${BUILD_BASE}/dtc
ENV LKVM_DIR=${BUILD_BASE}/kvmtool
ENV CROSS_COMPILE=/usr/bin/riscv64-linux-gnu-

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        wget \
        crossbuild-essential-riscv64 \
        gcc-12-riscv64-linux-gnu \
        git \
        pkg-config \
        flex \
        bison \
        python3 \
        && \
    adduser developer -u 499 --gecos ",,," --disabled-password && \
    mkdir -p ${BUILD_BASE} && chown -R developer:developer ${BUILD_BASE} && \
    rm -rf /var/lib/apt/lists/*

USER developer
WORKDIR ${BUILD_BASE}

# Build libfdt
RUN <<EOF
cd ${BUILD_BASE}
git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git
cd dtc
CC="riscv64-linux-gnu-gcc-12 -mabi=lp64d -march=rv64gc" make libfdt
make NO_PYTHON=1 NO_YAML=1 INCLUDEDIR=${LIBFDT_DIR} LIBDIR=${LIBFDT_DIR} install-lib install-includes
cd ..
EOF

# Build kvmtool
RUN <<EOF
git clone https://github.com/edubart/kvmtool.git
cd kvmtool
ls ${LIBFDT_LIBDIR}
WERROR=0 ARCH=riscv LIBFDT_DIR=${LIBFDT_DIR} CROSS_COMPILE=${CROSS_COMPILE} make lkvm-static -j4
install lkvm-static ${LKVM_DIR}/lkvm
EOF

# Final image
FROM --platform=linux/riscv64 riscv64/ubuntu:22.04
ARG TOOLS_DEB=machine-emulator-tools-v0.14.0.deb
ARG KERNEL_VERSION=6.5.9-ctsi-1
ARG KERNEL_RELEASE=v0.19.1
# Download guest kernel
ADD https://github.com/cartesi/image-kernel/releases/download/${KERNEL_RELEASE}/linux-${KERNEL_VERSION}-${KERNEL_RELEASE}-no-opensbi.bin /tmp/linux.bin
ADD ${TOOLS_DEB} /tmp/
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        busybox-static=1:1.30.1-7ubuntu3 \
        coreutils=8.32-4.1ubuntu1 \
        bash=5.1-6ubuntu1 \
        psmisc=23.4-2build3 \
        bc=1.07.1-3build1 \
        curl=7.81.0-1ubuntu1.15 \
        device-tree-compiler=1.6.1-1 \
        jq=1.6-2.1ubuntu3 \
        lua5.4=5.4.4-1 \
        lua-socket=3.0~rc1+git+ac3201d-6 \
        xxd=2:8.2.3995-1ubuntu2.15 \
        file=1:5.41-3ubuntu0.1 \
        python3 \
        python3-pip \
        iproute2 \
        /tmp/${TOOLS_DEB} \
        && \
    useradd --create-home --user-group dapp && \
    rm -rf /var/lib/apt/lists/* /tmp/${TOOLS_DEB}
RUN mkdir hv && mv /tmp/linux.bin /hv/
COPY --chown=root:root --from=cross-builder /tmp/build-extra/kvmtool/lkvm /usr/bin/

# Add dapp
RUN mkdir /dapp
ADD ./.external/dapp/dapp_host.py /dapp/dapp.py
ADD ./.external/dapp/requirements_host.txt /dapp/requirements.txt
ADD ./.external/dapp/entrypoint.sh /dapp/entrypoint.sh
RUN pip3 install -r /dapp/requirements.txt
