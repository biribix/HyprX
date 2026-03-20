# HyprX
Mi propia configuracion de Hyprland para ArchLinux

## Dependencias
* base && base-devel
* grub
* vim
* git
* sddm
* hyprland
* xdg-desktop-portal-hyprland
* xdg-desktop-portal-gtk
* starship
* foot
* fish
* rofi
* btop
* nerd-fonts
* swww
* waypaper
* grim
* slurp
* wl-clipboard
* cliphist
* whitesur-icon-theme
* whitesur-cursor-theme-git
* noctalia-shell
* playerctl
* nautilus

### Drivers para NVIDIA GPUs
```
sudo pacman -S linux-headers nvidia-dkms nvidia-settings nvidia-utils lib32-nvidia-utils amd-ucode intel-ucode
```
#### Edita los initramfs
sudo vim /etc/mkinitcpio.conf

Busca MODULES=() y ponlo así:
```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

Y regenera:
```
sudo mkinitcpio -P
```

#### Variables de entorno en hyprland.conf
Edita ~./config/hypr/env.conf y añade esto:
```
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
```

#### Activa los servicios de NVIDIA
```
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service
```

Y por ultimo reinicia para que se apliquen los cambios.


## Opcional
* VSCodium
* openrgb
* zip && upzip
* sddm-silent-theme
* nwg-look
* noto-fonts && noto-fonts-emoji
