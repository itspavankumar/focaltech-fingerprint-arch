# FocalTech (2808:a658) Fingerprint Driver for Arch Linux

[![Platform](https://img.shields.io/badge/Platform-Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](#)
[![Compositor](https://img.shields.io/badge/Hyprland%20%7C%20Wayland-Ready-00bcd4?style=for-the-badge)](#)
[![License](https://img.shields.io/badge/License-LGPL--2.1-blue?style=for-the-badge)](#)

A working setup and automated installer to get **FocalTech fingerprint sensors (USB ID 2808:A658)** working on **Arch Linux**, with support for standalone Wayland compositors like **Hyprland**, as well as desktop environments (KDE, GNOME).

---

## Compatible Hardware

| Device | USB ID | Status |
|--------|--------|--------|
| Asus laptops (Realtek / FocalTech sensor) | `2808:a658` | Confirmed working |
| Other FocalTech readers | `2808:xxxx` | May work (verify with `lsusb`) |

Verify your hardware with:
```bash
lsusb | grep -i 2808
```
Expected output:
```text
Bus 003 Device 004: ID 2808:a658 Realtek USB2.0 Finger Print Bridge FocalTech Fingerprint Device
```

---

## Quick Start (Automated Installation)

On a fresh Arch Linux installation, clone this repository and run the installer:

```bash
git clone https://github.com/itspavankumar/focaltech-fingerprint-arch.git
cd focaltech-fingerprint-arch
chmod +x install.sh
./install.sh
```

### What `install.sh` does automatically:
1. Detects and verifies the `2808:a658` USB fingerprint hardware.
2. Installs required dependencies: `base-devel`, `git`, `patchelf`, `fprintd`.
3. Patches Debian symbol versions (`LIBGUSB_0.1.0`) in the driver binary so it links dynamically without errors on modern Arch.
4. Builds and installs a clean Arch package (`libfprint-focaltech`) that provides `libfprint` and `libfprint-2.so=2-64`.
5. Adds Polkit permissions (`/etc/polkit-1/rules.d/50-fprintd.rules`) so users in the `wheel` group can enroll fingerprints without requiring a graphical polkit prompt.
6. Installs udev rules for device `2808:a658`.
7. Reloads udev and starts the `fprintd` daemon.
8. Adds `IgnorePkg = libfprint` in `/etc/pacman.conf` to protect against accidental overwrites during `pacman -Syu`.

---

## Enrolling Your Fingerprint

Since standalone Wayland compositors (like Hyprland) do not have a GNOME Settings panel, enrollment is done via the CLI:

### 1. Enroll
```bash
fprintd-enroll
```
*(By default, this registers your **right index finger**. For another finger like your thumb, run `fprintd-enroll -f right-thumb`)*

Swipe or tap your finger repeatedly until you see:
```text
Enroll result: enroll-completed
```

### 2. Verify
```bash
fprintd-verify
```
Touch the sensor. You should see `Verify result: verify-match (done)`.

---

## Enabling Fingerprint Authentication

### 1. Enable for sudo in Terminal
Edit `/etc/pam.d/sudo`:
```bash
sudo nano /etc/pam.d/sudo
```
Add `auth sufficient pam_fprintd.so` as the **first auth line**:
```pam
#%PAM-1.0
auth		sufficient	pam_fprintd.so
auth		include		system-auth
account		include		system-auth
session		include		system-auth
session		optional	pam_systemd.so class=none
```

### 2. Enable for GUI Root Escalation (Polkit)
Create `/etc/pam.d/polkit-1` so GUI prompts (e.g. GParted, Timeshift) support fingerprint:
```bash
sudo tee /etc/pam.d/polkit-1 << 'EOF'
#%PAM-1.0
auth       sufficient   pam_fprintd.so
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF
```

### 3. Enable for Hyprlock (Hyprland Lockscreen)
`hyprlock` features native asynchronous fingerprint support over D-Bus. In `~/.config/hypr/hyprlock.conf`:

```ini
auth {
    fingerprint {
        enabled = true
        ready_message = (Scan fingerprint or type password)
        present_message = Scanning fingerprint...
        retry_delay = 250
    }
}

label {
    monitor =
    text = $FPRINTPROMPT
    color = rgb(136, 192, 208)
    font_size = 14
    position = 0, -140
    halign = center
    valign = center
}
```

---

## Manual Installation & Troubleshooting

<details>
<summary><strong>Manual step-by-step installation without script</strong></summary>

```bash
# 1. Install dependencies
sudo pacman -S --needed base-devel git patchelf fprintd

# 2. Build and install package
makepkg -sf
sudo pacman -U libfprint-focaltech-*.pkg.tar.zst

# 3. Add polkit rule
sudo tee /etc/polkit-1/rules.d/50-fprintd.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("net.reactivated.fprint.") === 0 && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

# 4. Reload and restart
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo systemctl restart polkit
sudo systemctl restart fprintd
```
</details>

<details>
<summary><strong>Enrollment fails with "PermissionDenied: Not Authorized"</strong></summary>

Make sure the Polkit rule exists at `/etc/polkit-1/rules.d/50-fprintd.rules` and your user is a member of the `wheel` group (`groups $USER`). Then restart polkit:
```bash
sudo systemctl restart polkit
```
Alternatively, you can run enrollment with sudo:
```bash
sudo fprintd-enroll $USER
```
</details>

<details>
<summary><strong>fprintd.service: static unit notice</strong></summary>

`fprintd` is a D-Bus activated service on Arch Linux — it doesn't have an `[Install]` section because systemd automatically starts it on-demand whenever biometric auth is invoked. You don't need to enable it with `systemctl enable`.
</details>

---

## Credits & Acknowledgements

- **Meet Suthar ([@Meetsuthar32778](https://github.com/Meetsuthar32778))**: Original porter and maintainer of the FocalTech `2808:A658` driver package at [Meetsuthar32778/2808-A658-fingerprint-arch-linux-driver](https://github.com/Meetsuthar32778/2808-A658-fingerprint-arch-linux-driver).
- **Pranshu Saxena ([@Theewebwizard](https://github.com/Theewebwizard))**: Contributor to initial Debian/Ubuntu installer scripts.
- **The libfprint and fprintd projects**: Upstream fingerprint management and D-Bus daemon.
