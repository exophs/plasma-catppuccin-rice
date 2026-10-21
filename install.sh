#!/usr/bin/env bash
# Catppuccin Mocha (Mauve) rice for KDE Plasma 6 - per-user installer, no root needed.
#
#   ./install.sh               install everything and rebuild the panels
#   ./install.sh --no-layout   install themes/configs but keep your current panels
#
# Existing files are backed up to ~/.config/catppuccin-rice-backup-<timestamp>/ first.
# Compiled extras (rounded corners, blur, Kara, audio visualizer) are separate:
#   ./scripts/build-extras.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_LAYOUT=1
[[ "${1:-}" == "--no-layout" ]] && APPLY_LAYOUT=0

CFG="$HOME/.config"
DATA="$HOME/.local/share"
BACKUP="$CFG/catppuccin-rice-backup-$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }
kw() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }

for cmd in curl git unzip tar qdbus6 kwriteconfig6 kpackagetool6 plasma-apply-colorscheme; do
  have "$cmd" || { echo "Missing required command: $cmd" >&2; exit 1; }
done

step "Backing up current config to $BACKUP"
mkdir -p "$BACKUP"
for f in kdeglobals kwinrc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc konsolerc \
         starship.toml fastfetch btop cava Kvantum klassy environment.d gtk-3.0 gtk-4.0; do
  [[ -e "$CFG/$f" ]] && cp -a "$CFG/$f" "$BACKUP/"
done
[[ -e "$HOME/.zshrc" ]] && cp -a "$HOME/.zshrc" "$BACKUP/zshrc"

step "Copying dotfiles"
cp -r "$REPO_DIR/dotfiles/." "$HOME/"

step "zsh plugins"
mkdir -p "$HOME/.zsh/plugins"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting \
            catppuccin/zsh-syntax-highlighting; do
  name="${repo##*/}"; [[ $repo == catppuccin/* ]] && name="catppuccin-$name"
  [[ -d "$HOME/.zsh/plugins/$name" ]] || git clone -q --depth 1 "https://github.com/$repo" "$HOME/.zsh/plugins/$name"
done

step "Catppuccin themes"
# KDE color scheme
fetch https://github.com/catppuccin/kde/releases/download/v0.4.0/Mocha-color-schemes.tar.gz "$TMP/kde.tgz"
mkdir -p "$DATA/color-schemes"
tar -xzf "$TMP/kde.tgz" -C "$TMP"
cp "$TMP"/Mocha-color-schemes/*.colors "$DATA/color-schemes/"
# Konsole
mkdir -p "$DATA/konsole"
fetch https://raw.githubusercontent.com/catppuccin/konsole/main/themes/catppuccin-mocha.colorscheme "$DATA/konsole/catppuccin-mocha.colorscheme"
kw konsolerc "Desktop Entry" DefaultProfile Catppuccin.profile
# Kvantum
mkdir -p "$CFG/Kvantum/catppuccin-mocha-mauve"
for ext in kvconfig svg; do
  fetch "https://raw.githubusercontent.com/catppuccin/kvantum/main/themes/catppuccin-mocha-mauve/catppuccin-mocha-mauve.$ext" \
        "$CFG/Kvantum/catppuccin-mocha-mauve/catppuccin-mocha-mauve.$ext"
done
# Klassy window decoration button colors
mkdir -p "$CFG/klassy"
fetch https://raw.githubusercontent.com/helenclx/catppuccin-klassy/main/themes/catppuccin-mocha.txt "$CFG/klassy/klassyrc"
# btop
mkdir -p "$CFG/btop/themes"
fetch https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme "$CFG/btop/themes/catppuccin_mocha.theme"
# Cursors
fetch https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-mauve-cursors.zip "$TMP/cursors.zip"
mkdir -p "$DATA/icons"; unzip -qo "$TMP/cursors.zip" -d "$DATA/icons"
# GTK 3/4
GTK=catppuccin-mocha-mauve-standard+default
fetch "https://github.com/catppuccin/gtk/releases/download/v1.0.3/$GTK.zip" "$TMP/gtk.zip"
mkdir -p "$DATA/themes"; unzip -qo "$TMP/gtk.zip" -d "$DATA/themes"
mkdir -p "$CFG/gtk-4.0"
for f in gtk.css gtk-dark.css assets; do
  rm -rf "$CFG/gtk-4.0/$f"; ln -s "$DATA/themes/$GTK/gtk-4.0/$f" "$CFG/gtk-4.0/$f"
done
# Font
if ! fc-list | grep -qi 'JetBrainsMono Nerd'; then
  fetch https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz "$TMP/jbm.tar.xz"
  mkdir -p "$DATA/fonts/JetBrainsMonoNerd"; tar -xJf "$TMP/jbm.tar.xz" -C "$DATA/fonts/JetBrainsMonoNerd"
  fc-cache -f >/dev/null
fi

step "Plasma widgets (Panel Colorizer, PlasMusic Toolbar, Shutdown or Switch)"
latest_asset() {  # repo, name-regex
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E "$2" | head -1
}
for spec in "luisbocanegra/plasma-panel-colorizer|\.plasmoid$" "ccatterina/plasmusic-toolbar|\.plasmoid$" \
            "Davide-sd/shutdown_or_switch|\.plasmoid$"; do
  url=$(latest_asset "${spec%%|*}" "${spec#*|}") || true
  if [[ -n "$url" ]]; then
    fetch "$url" "$TMP/w.plasmoid"
    kpackagetool6 -t Plasma/Applet -u "$TMP/w.plasmoid" >/dev/null 2>&1 \
      || kpackagetool6 -t Plasma/Applet -i "$TMP/w.plasmoid" >/dev/null
  else
    warn "couldn't find a release for ${spec%%|*}"
  fi
done

step "Applying settings"
plasma-apply-colorscheme CatppuccinMochaMauve >/dev/null
have plasma-apply-cursortheme && plasma-apply-cursortheme catppuccin-mocha-mauve-cursors >/dev/null || true
if [[ -d /usr/share/icons/Papirus-Dark || -d "$DATA/icons/Papirus-Dark" ]]; then
  kw kdeglobals Icons Theme Papirus-Dark
else
  warn "Papirus icons not found - install papirus-icon-theme for the full look"
fi
if [[ -e /usr/lib/qt6/plugins/styles/libkvantum.so || -e /usr/lib64/qt6/plugins/styles/libkvantum.so ]]; then
  kw kdeglobals KDE widgetStyle kvantum
else
  warn "Kvantum not installed - keeping the current app style"
fi
if ls /usr/lib*/qt6/plugins/org.kde.kdecoration3/org.kde.klassy.so >/dev/null 2>&1; then
  kw kwinrc org.kde.kdecoration2 library org.kde.klassy
  kw kwinrc org.kde.kdecoration2 theme Klassy
else
  warn "Klassy not installed - keeping the current window decoration"
fi
# GTK
for v in 3.0 4.0; do
  kwriteconfig6 --file "$CFG/gtk-$v/settings.ini" --group Settings --key gtk-theme-name "$GTK"
  kwriteconfig6 --file "$CFG/gtk-$v/settings.ini" --group Settings --key gtk-application-prefer-dark-theme true
done
have flatpak && flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro \
  --filesystem=xdg-data/themes:ro --filesystem=xdg-data/icons:ro --env=GTK_THEME="$GTK" || true
# KWin effects (take effect once scripts/build-extras.sh has built them)
kw kwinrc Plugins kwin4_effect_shapecornersEnabled true
kw kwinrc Plugins better_blur_dxEnabled true
kw kwinrc Plugins blurEnabled false
kw kwinrc Round-Corners Size 12
kw kwinrc Round-Corners InactiveCornerRadius 12
kw kwinrc Round-Corners OutlineThickness 1.5
kw kwinrc Round-Corners OutlineColor 203,166,247
kw kwinrc Round-Corners InactiveOutlineThickness 1
kw kwinrc Round-Corners InactiveOutlineColor 69,71,90
kw kwinrc Effect-better-blur-dx WindowClasses $'konsole\norg.kde.konsole'
kw kwinrc Effect-better-blur-dx BlurMatching true
kw kwinrc Effect-better-blur-dx BlurMenus true
kw kwinrc Effect-better-blur-dx BlurDocks true
kw kwinrc Effect-better-blur-dx CornerRadius 12
kw kwinrc Effect-better-blur-dx BlurStrength 10
# 4 virtual desktops
while (( $(qdbus6 org.kde.KWin /VirtualDesktopManager org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager count) < 4 )); do
  n=$(qdbus6 org.kde.KWin /VirtualDesktopManager org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager count)
  qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop "$n" "$((n + 1))" >/dev/null
done
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

if (( APPLY_LAYOUT )); then
  step "Rebuilding panels (top bar + dock on every screen)"
  PRESET="$DATA/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/Rounded Widgets Floating/settings.json"
  if [[ -f "$PRESET" ]]; then
    PRESET_JS=$(python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1]))["globalSettings"]))' "$PRESET")
  else
    PRESET_JS=null
  fi
  SCRIPT=$(<"$REPO_DIR/plasma/layout.js")
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${SCRIPT/__COLORIZER_PRESET__/"$PRESET_JS"}"
  # Restart so list-type settings (dock launchers) are re-read from disk
  sleep 3; kquitapp6 plasmashell >/dev/null 2>&1 || true; sleep 2
  (setsid kstart plasmashell >/dev/null 2>&1 &)
fi

step "Done"
echo "  Backup: $BACKUP"
echo "  Optional next steps (see README.md):"
echo "    ./scripts/build-extras.sh      rounded corners, blur, Kara, audio visualizer"
echo "    Spicetify / Vesktop themes, boot splash"
echo "  Log out and back in to apply everything."
