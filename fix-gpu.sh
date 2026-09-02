#!/bin/bash
# Post-3090-removal cleanup. Run: sudo bash ~/fix-gpu.sh
set -e

# 1. DRM aliases keyed on driver, not PCI address (address moved 15:00.0 -> 14:00.0
#    when the 3090 came out and the bridge collapsed).
cat > /etc/udev/rules.d/61-drm-stable-names.rules <<'RULES'
# Colon-free stable names for the DRM primary nodes.
#
# AQ_DRM_DEVICES (aquamarine) splits its value on ':', so /dev/dri/by-path
# names cannot be used there -- the PCI address' own colons shred the path.
#
# Keyed on the PCI DRIVER, not on ID_PATH: removing the discrete card collapses
# a PCIe bridge and renumbers the bus (iGPU 15:00.0 -> 14:00.0 on 2026-08-30),
# which silently broke the address-keyed version of this rule and took the
# session down with "CBackend::create() failed!".
SUBSYSTEM=="drm", KERNEL=="card*", SUBSYSTEMS=="pci", DRIVERS=="amdgpu", SYMLINK+="dri/gpu-amd"
SUBSYSTEM=="drm", KERNEL=="card*", SUBSYSTEMS=="pci", DRIVERS=="nvidia", SYMLINK+="dri/gpu-nvidia"
RULES
udevadm control --reload-rules
udevadm trigger --subsystem-match=drm

# 2. The only Vulkan ICD installed is nvidia's, pointing at a card that is gone.
pacman -S --needed --noconfirm vulkan-radeon

echo
echo "gpu-amd -> $(readlink -f /dev/dri/gpu-amd 2>/dev/null || echo MISSING)"
ls /usr/share/vulkan/icd.d/
