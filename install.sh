#!/usr/bin/env bash
# ==============================================================================
# FocalTech (2808:a658) Fingerprint Driver Installer for Arch Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " FocalTech (2808:a658) Arch Linux Driver Installer        "
echo "=========================================================="

# 1. Hardware verification
echo "[1/6] Checking for compatible hardware..."
if ! command -v lsusb &>/dev/null; then
    sudo pacman -S --needed --noconfirm usbutils
fi

if lsusb | grep -qi "2808"; then
    echo "  ✓ Detected device: $(lsusb | grep -i '2808')"
else
    echo "  ⚠️ Warning: FocalTech fingerprint sensor (2808:xxxx) not detected in lsusb."
    read -rp "  Do you want to continue anyway? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || exit 1
fi

# 2. Dependencies
echo "[2/6] Installing build and runtime dependencies..."
sudo pacman -S --needed --noconfirm base-devel git patchelf fprintd

# 3. Build package
echo "[3/6] Building custom libfprint driver package..."
cd "$SCRIPT_DIR"
# Clean old build artifacts if present
rm -rf src/ pkg/ libfprint-focaltech-*.pkg.tar.zst
makepkg -sf --noconfirm

# 4. Install package
echo "[4/6] Installing libfprint-focaltech..."
PKG_FILE=$(ls -t libfprint-focaltech-*.pkg.tar.zst | grep -v 'debug' | head -n 1)
sudo pacman -U --noconfirm "$PKG_FILE"

# 5. Polkit permissions for enrollment
echo "[5/6] Setting up Polkit permissions for enrollment..."
sudo tee /etc/polkit-1/rules.d/50-fprintd.rules > /dev/null << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("net.reactivated.fprint.") === 0 && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

# 6. Service reload and pacman protection
echo "[6/6] Reloading udev and restarting fprintd service..."
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo systemctl restart polkit
sudo systemctl restart fprintd

# Protect driver against pacman -Syu
if ! grep -q "^IgnorePkg.*libfprint" /etc/pacman.conf; then
    echo "==> Adding 'IgnorePkg = libfprint' to /etc/pacman.conf to prevent update overwrite..."
    if grep -q "^#IgnorePkg" /etc/pacman.conf; then
        sudo sed -i '/^#IgnorePkg/s/^#//; /^IgnorePkg/s/$/ libfprint/' /etc/pacman.conf
    elif grep -q "^IgnorePkg" /etc/pacman.conf; then
        sudo sed -i '/^IgnorePkg/s/$/ libfprint/' /etc/pacman.conf
    else
        sudo sed -i '/\[options\]/a IgnorePkg = libfprint' /etc/pacman.conf
    fi
fi

# Clean build artifacts
rm -rf src/ pkg/

echo ""
echo "=========================================================="
echo " ✅ Installation Complete!"
echo "=========================================================="
echo ""
echo "Next Steps:"
echo "1. Enroll your fingerprint:"
echo "   fprintd-enroll"
echo ""
echo "2. Verify your fingerprint:"
echo "   fprintd-verify"
echo ""
echo "3. Enable for sudo (optional):"
echo "   Add this line to the TOP of /etc/pam.d/sudo:"
echo "   auth    sufficient    pam_fprintd.so"
echo ""
echo "4. Enable for Hyprlock (optional):"
echo "   In ~/.config/hypr/hyprlock.conf, add:"
echo "   auth { fingerprint { enabled = true } }"
echo "=========================================================="
