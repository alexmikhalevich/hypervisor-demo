HOST_INIT=uname -a && \
busybox tunctl -t tap0 >/dev/null && \
busybox ip link set tap0 up && \
busybox ip addr add 192.168.3.1/24 dev tap0

KERNEL_ADDR=https://github.com/cartesi/image-kernel/releases/download/v0.19.1/linux-6.5.9-ctsi-1-v0.19.1.bin

submodules:
	git submodule update --init --recursive

%-fs:
	@echo 'Building $* fs...'
	@mkdir -p build
	@mkdir -p deps/tools/.external
	@cp $*/fs/rootfs-host.Dockerfile deps/tools/fs/rootfs-$*-host.Dockerfile
	@cp $*/fs/rootfs-guest.Dockerfile deps/tools/fs/rootfs-$*-guest.Dockerfile
	@cp -R $*/dapp deps/tools/.external/
	$(MAKE) -C deps/tools rootfs-$*-host.ext2
	$(MAKE) -C deps/tools rootfs-$*-guest.ext2
	@mv deps/tools/rootfs-$*-* build/
	@rm -rf deps/tools/.external
	@rm deps/tools/fs/rootfs-$*-*

downloads:
	@mkdir downloads
	@wget -O downloads/linux.bin $(KERNEL_ADDR)

%-inputs:
	@echo 'Building $* inputs...'
	$(MAKE) -C $* inputs
	@mv $*/inputs/* build/
	@rm -rf $*/inputs

demo1: downloads demo1-fs demo1-inputs
	jsonrpc-remote-cartesi-machine --server-address=localhost:8080 2>&1 &
	#while ! netstat -ntl 2>&1 | grep 8080; do sleep 1; done
	@sleep 3
	cartesi-machine \
		--ram-length=1024Mi \
		--ram-image=downloads/linux.bin \
		--append-init="$(HOST_INIT)" \
		--flash-drive=label:root,filename:build/rootfs-demo1-host.ext2 \
		--flash-drive=label:guest-root,filename:build/rootfs-demo1-guest.ext2,mount:false \
		--no-init-splash \
		--quiet \
		--no-default-init \
		--remote-address="localhost:8080" \
		--remote-protocol="jsonrpc" \
		--remote-shutdown \
		--rollup-advance-state=input:"build/epoch-%e-input-%i.bin",input_metadata:"build/epoch-%e-input-metadata-%i.bin",epoch_index:0,input_index_begin:1,input_index_end:2 \
		-- "cd /dapp && /usr/sbin/rollup-init python3 dapp.py http://127.0.0.1:5004"

clean:
	rm -rf build downloads deps/tools/.external deps/tools/fs/rootfs-demo* *.bin

help:
	@echo 'available commands:'
	@echo '  submodules      - checkout submodules'
	@echo '  downloads       - download the necessary files'
	@echo '  demo1           - execute demo1: pass a python program as an input and execute it inside the hypervisor'
	@echo '  help            - list makefile commands'
	@echo '  clean           - remove the generated artifacts'

.PHONY: demo1 help
