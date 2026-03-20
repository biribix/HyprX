function update
    set -g BOLD (tput bold)
    set -g RESET (tput sgr0)
    set -g GREEN (tput setaf 2)
    set -g CYAN (tput setaf 6)
    set -g YELLOW (tput setaf 3)
    set -g RED (tput setaf 1)
    set -g DIM (tput dim)
    set -g ERRORS 0

    function _header
        echo ""
        echo "$BOLD$CYAN  ╔══════════════════════════════════════╗$RESET"
        echo "$BOLD$CYAN  ║       ARCH SYSTEM UPDATER            ║$RESET"
        echo "$BOLD$CYAN  ╚══════════════════════════════════════╝$RESET"
        echo "  $DIM"(date '+%A %d %B %Y — %H:%M:%S')"$RESET"
        echo ""
    end

    function _step
        echo "$BOLD$CYAN  ▶ $argv$RESET"
    end

    function _success
        echo "$GREEN  ✔ $argv$RESET"
    end

    function _warn
        echo "$YELLOW  ⚠ $argv$RESET"
    end

    function _fail
        echo "$RED  ✘ $argv$RESET"
        set -g ERRORS (math $ERRORS + 1)
    end

    function _run_step
        set label $argv[1]
        set cmd $argv[2..]

        _step $label
        eval $cmd
        if test $status -eq 0
            _success "Completado"
        else
            _fail "Error en: $label"
        end
        echo ""
    end

    clear
    _header

    if command -q reflector
        _run_step "Actualizando mirrors (reflector)" \
            "reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist"
    else
        _warn "reflector no encontrado — saltando mirrors"
        echo ""
    end

    _run_step "Actualizando paquetes AUR y oficiales (yay)" \
        "yay -Syu --noconfirm --sudoloop"

    _step "Eliminando descargas parciales"
    sudo rm -rf /var/cache/pacman/pkg/download-*
    _success "Completado"
    echo ""

    _run_step "Limpiando caché de paquetes" \
        "yay -Sc --noconfirm"

    set orphans (yay -Qdtq 2>/dev/null)
    if test -n "$orphans"
        _run_step "Eliminando paquetes huérfanos" \
            "yay -Rns --noconfirm $orphans"
    else
        _step "Buscando paquetes huérfanos"
        _success "No hay huérfanos"
        echo ""
    end

    if command -q pkgfile
        _run_step "Actualizando base de datos pkgfile" \
            "pkgfile --update"
    end

    echo "$BOLD$CYAN  ─────────────────────────────────────────$RESET"
    if test $ERRORS -eq 0
        echo "$BOLD$GREEN  ✔ Sistema actualizado correctamente$RESET"
    else
        echo "$BOLD$RED  ✘ Finalizado con $ERRORS error(es)$RESET"
    end
    echo "  $DIM"(date '+%H:%M:%S')"$RESET"
    echo "$BOLD$CYAN  ─────────────────────────────────────────$RESET"
    echo ""

    echo "  $DIM Cerrando terminal en 3 segundos...$RESET"
    sleep 3
    hyprctl dispatch killactive ""
end
