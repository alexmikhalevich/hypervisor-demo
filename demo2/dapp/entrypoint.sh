GUEST_INIT="uname -a && \
busybox ip link set dev eth0 up && \
busybox ip addr add 192.168.3.2/24 dev eth0"

/usr/sbin/rollup-init python3 dapp.py http://127.0.0.1:5004 192.168.3.1 &
echo "Waiting for rollup to start..."
sleep 30
echo "Executing hypervisor..."

lkvm run \
    --mem 256M \
    --cpus 1 \
    --virtio-transport mmio \
    --balloon \
    --rng \
    --console hv \
    --network mode=tap,tapif=tap0 \
    --kernel /hv/linux.bin \
    --disk /dev/pmem1 \
    --params "quiet earlycon=sbi console=hvc0 rw rootfstype=ext2 root=/dev/vda init=/usr/sbin/cartesi-init -- $GUEST_INIT && python3 /dapp/dapp.py http://192.168.3.1:5000"
