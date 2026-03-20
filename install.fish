#!/usr/bin/env fish
# =============================================================================
# HyprX - Script de instalación automática
# https://github.com/biribix/HyprX
# =============================================================================

set RED '\033[0;31m'
set GREEN '\033[0;32m'
set YELLOW '\033[1;33m'
set BLUE '\033[0;34m'
set CYAN '\033[0;36m'
set NC '\033[0m'

function log_info
    printf "$CYAN[INFO]$NC %s\n" "$argv"
end

function log_ok
    printf "$GREEN[OK]$NC %s\n" "$argv"
end

function log_warn
    printf "$YELLOW[WARN]$NC %s\n" "$argv"
end

function log_error
    printf "$RED[ERROR]$NC %s\n" "$argv"
end

function log_section
    echo ""
    printf "$BLUE══════════════════════════════════════$NC\n"
    printf "$BLUE  %s$NC\n" "$argv"
    printf "$BLUE══════════════════════════════════════$NC\n"
end

# =============================================================================
# COMPROBACIONES PREVIAS
# =============================================================================

log_section "Comprobando el sistema"

# Verificar que es Arch Linux
if not test -f /etc/arch-release
    log_error "Este script es solo para Arch Linux."
    exit 1
end
log_ok "Arch Linux detectado"

# Verificar que NO se ejecuta como root
if test (id -u) -eq 0
    log_error "No ejecutes este script como root."
    exit 1
end
log_ok "Ejecutando como usuario normal"

# Verificar yay
if not command -v yay >/dev/null 2>&1
    log_warn "yay no encontrado. Instalando yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    if command -v yay >/dev/null 2>&1
        log_ok "yay instalado correctamente"
    else
        log_error "No se pudo instalar yay. Instálalo manualmente y vuelve a ejecutar el script."
        exit 1
    end
else
    log_ok "yay encontrado"
end

# =============================================================================
# PAQUETES OBLIGATORIOS
# =============================================================================

log_section "Instalando dependencias principales"

set PKGS \
    base \
    base-devel \
    vim \
    git \
    sddm \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    foot \
    fish \
    rofi \
    btop \
    swww \
    waypaper \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    playerctl \
    nautilus \
    starship

log_info "Instalando paquetes de pacman..."
sudo pacman -S --needed --noconfirm $PKGS
log_ok "Paquetes principales instalados"

# =============================================================================
# PAQUETES AUR
# =============================================================================

log_section "Instalando paquetes del AUR"

set AUR_PKGS \
    nerd-fonts \
    whitesur-icon-theme \
    whitesur-cursor-theme-git \
    noctalia-shell

log_info "Instalando paquetes AUR..."
yay -S --needed --noconfirm $AUR_PKGS
log_ok "Paquetes AUR instalados"

# =============================================================================
# DRIVERS NVIDIA (opcional)
# =============================================================================

log_section "Drivers NVIDIA"
 
read -l -P "¿Tienes una GPU NVIDIA? [s/N] " nvidia_respuesta
 
if test "$nvidia_respuesta" = "s" -o "$nvidia_respuesta" = "S"
    log_info "Instalando drivers NVIDIA..."
    sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms nvidia-settings nvidia-utils lib32-nvidia-utils
 
    log_info "Configurando módulos NVIDIA en initramfs..."
    sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
    log_ok "Initramfs regenerado"
 
    set modeset (cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null)
    if test "$modeset" != "Y"
        log_info "Configurando parámetros del kernel en GRUB..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        log_ok "GRUB actualizado"
    else
        log_ok "nvidia_drm.modeset ya está activado, saltando configuración de GRUB"
    end
 
    log_info "Activando servicios NVIDIA..."
    sudo systemctl enable nvidia-suspend.service
    sudo systemctl enable nvidia-hibernate.service
    sudo systemctl enable nvidia-resume.service
    log_ok "Servicios NVIDIA activados"
else
    log_info "Saltando instalación de drivers NVIDIA"
end

# =============================================================================
# COPIAR DOTFILES
# =============================================================================

log_section "Instalando dotfiles"

set REPO_DIR (dirname (status --current-filename))

# Backup de configs existentes
if test -d ~/.config/hypr
    log_warn "Haciendo backup de ~/.config/hypr en ~/.config/hypr.bak"
    mv ~/.config/hypr ~/.config/hypr.bak
end

log_info "Copiando configuración de Hyprland..."
mkdir -p ~/.config/hypr
cp -r $REPO_DIR/config/hypr/* ~/.config/hypr/
log_ok "Hyprland configurado"

log_info "Copiando configuración de Fish..."
mkdir -p ~/.config/fish/functions
cp -r $REPO_DIR/config/fish/* ~/.config/fish/
log_ok "Fish configurado"

log_info "Copiando configuración de Foot..."
mkdir -p ~/.config/foot
cp -r $REPO_DIR/config/foot/* ~/.config/foot/
log_ok "Foot configurado"

log_info "Copiando configuración de btop..."
mkdir -p ~/.config/btop/themes
cp -r $REPO_DIR/config/btop/* ~/.config/btop/
log_ok "btop configurado"

log_info "Copiando configuración de GTK..."
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
cp $REPO_DIR/config/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini
cp $REPO_DIR/config/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini
log_ok "GTK configurado"

log_info "Copiando configuración de Rofi..."
mkdir -p ~/.local/share/rofi/themes
cp -r $REPO_DIR/local/share/rofi/themes/* ~/.local/share/rofi/themes/
log_ok "Rofi configurado"

log_info "Copiando configuración de Noctalia..."
mkdir -p ~/.config/noctalia
cp -r $REPO_DIR/config/noctalia/* ~/.config/noctalia/
log_ok "Noctalia configurado"

log_info "Copiando starship.toml..."
cp $REPO_DIR/starship.toml ~/.config/starship.toml
log_ok "Starship configurado"

log_info "Copiando wallpapers..."
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures/Screenshots
cp -r $REPO_DIR/Pictures/Wallpapers/* ~/Pictures/Wallpapers/
log_ok "Wallpapers copiados"

log_info "Copiando .desktop de actualización..."
mkdir -p ~/.local/share/applications
cp $REPO_DIR/local/share/applications/update.desktop ~/.local/share/applications/
log_ok "Acceso directo de actualización instalado"

# =============================================================================
# CONFIGURACIÓN DEL SISTEMA
# =============================================================================

log_section "Configuración del sistema"

# Fish como shell por defecto
log_info "Cambiando shell por defecto a Fish..."
chsh -s /usr/bin/fish
log_ok "Shell cambiada a Fish"

# Activar SDDM
log_info "Activando SDDM..."
sudo systemctl enable sddm
log_ok "SDDM activado"

# Tema oscuro con gsettings
log_info "Aplicando tema oscuro..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null
log_ok "Tema oscuro aplicado"

# ILoveCandy en pacman.conf
if not grep -q "ILoveCandy" /etc/pacman.conf
    log_info "Añadiendo ILoveCandy a pacman.conf..."
    sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf
    log_ok "ILoveCandy activado (la verdadera experiencia Pacman)"
else
    log_ok "ILoveCandy ya estaba activado"
end

# =============================================================================
# PAQUETES OPCIONALES
# =============================================================================

log_section "Paquetes opcionales"

set OPC_PKGS \
    "vscodium" \
    "brave-bin" \
    "openrgb" \
    "zip" \
    "unzip" \
    "nwg-look" \
    "noto-fonts" \
    "noto-fonts-emoji" \
    "zoxide" \
    "tldr"

set OPC_DESC \
    "Editor de código VSCodium" \
    "Navegador Brave" \
    "Control de iluminación RGB" \
    "Compresión zip" \
    "Descompresión unzip" \
    "Configurador GTK para Wayland" \
    "Fuentes Noto" \
    "Fuentes Noto Emoji" \
    "Alternativa moderna a cd" \
    "Alternativa simplificada a man"

for i in (seq 1 (count $OPC_PKGS))
    read -l -P "¿Instalar $OPC_DESC[$i]? [s/N] " respuesta
    if test "$respuesta" = "s" -o "$respuesta" = "S"
        yay -S --needed --noconfirm $OPC_PKGS[$i]
        log_ok "$OPC_PKGS[$i] instalado"
    end
end

# =============================================================================
# FINALIZADO
# =============================================================================

log_section "¡Instalación completada!"

echo ""
log_ok "HyprX instalado correctamente."
echo ""
printf "$YELLOW  Recuerda:$NC\n"
echo "  - Reinicia el sistema para aplicar todos los cambios"
echo "  - Si tienes NVIDIA, el reinicio es obligatorio"
echo "  - Al iniciar sesión selecciona Hyprland en SDDM"
echo ""
read -l -P "¿Reiniciar ahora? [s/N] " reiniciar
if test "$reiniciar" = "s" -o "$reiniciar" = "S"
    sudo reboot
else
    log_info "Recuerda reiniciar manualmente cuando estés listo."
end
