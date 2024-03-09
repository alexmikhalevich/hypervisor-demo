import subprocess


class Hypervisor:
    def __init__(self):
        self.guest_ip = "192.168.3.2/24"
        self.guest_rootfs_dev = "/dev/pmem1"
        self.guest_memory_mb = 256
        self.guest_cpus = 1
        self.guest_kernel = "/hv/linux.bin"

    def set_guest_ip(self, ip: str):
        self.guest_ip = ip

    def set_guest_rootfs_dev(self, dev: str):
        self.guest_rootfs_dev = dev

    def set_guest_memory(self, mem_mb: int):
        self.guest_memory_mb = mem_mb

    def set_guest_cpus(self, cpus: int):
        self.guest_cpus = cpus

    def set_guest_kernel(self, kernel: str):
        self.guest_kernel = kernel

    def __run_command(self, cmd):
        init = f"""
        uname -a && \
        busybox ip link set dev eth0 up && \
        busybox ip addr add {self.guest_ip} dev eth0
        """
        print(f"Starting hypervisor with command: `{cmd}`")
        subprocess.run([
            "lkvm",
            "run",
            "--mem", f"{self.guest_memory_mb}M",
            "--cpus", str(self.guest_cpus),
            "--virtio-transport", "mmio",
            "--balloon",
            "--rng",
            "--console", "hv",
            "--network", "mode=tap,tapif=tap0",
            "--kernel", self.guest_kernel,
            "--disk", self.guest_rootfs_dev,
            "--params", f"'quiet earlycon=sbi console=hvc0 rw rootfstype=ext2 root=/dev/vda init=/usr/sbin/cartesi-init -- {init} && {cmd}'"
        ])

    def execute_python_script(self, script: str):
        # all quotes should be escaped in `script`, omitting here for simplicity

        # the line below should be cleaned up for production code
        cmd = f"""
        python3 -c "\"{script}"'
        """
        self.__run_command(cmd)
