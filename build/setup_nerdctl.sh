#! /bin/sh

# limactl start intel_on_arm_with_nerdctl.yaml
limactl shell intel_on_arm_with_nerdctl sudo systemctl start containerd
limactl shell intel_on_arm_with_nerdctl sudo nerdctl run --privileged --rm tonistiigi/binfmt:qemu-v7.0.0-28@sha256:66e11bea77a5ea9d6f0fe79b57cd2b189b5d15b93a2bdb925be22949232e4e55 --install all
limactl shell intel_on_arm_with_nerdctl CONTAINERD_NAMESPACE=default containerd-rootless-setuptool.sh install-buildkit-containerd
