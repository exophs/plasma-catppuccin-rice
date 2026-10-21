#!/usr/bin/env bash
# Builds the compiled extras into ~/.local (no root for the build itself):
#   KDE Rounded Corners, Better Blur DX, Kara (workspace indicator), Audio Visualizer plugin.
# ~/.config/environment.d/90-rice-local-plugins.conf (installed by install.sh) points
# KWin/Plasma at ~/.local. Re-run after every KWin/Plasma update, then log out and in.
#
# On AerynOS the build dependencies are installed with moss (needs sudo).
# On other distros, install the equivalents listed in each project's README first.
set -euo pipefail

PREFIX="$HOME/.local"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/catppuccin-rice/src"
JOBS=$(nproc)

# name | git url | tag/branch | extra cmake args
PROJECTS=(
  "kde-rounded-corners|https://github.com/matinlotfali/KDE-Rounded-Corners|v0.10.0|"
  "better-blur-dx|https://github.com/xarblu/kwin-effects-better-blur-dx|main|"
  "kara|https://github.com/dhruv8sh/kara|v1.0.0|"
  "audio-visualizer|https://github.com/luisbocanegra/plasma-audio-visualizer|v3.6.1|-DBUILD_PLUGIN=ON -DINSTALL_PLASMOID=ON"
)

AERYN_PKGS=(
  cava python-dbus qt6-websockets
  cmake extra-cmake-modules ninja gcc gcc-devel g++ libstdc++-devel binutils pkgconf gettext
  qt6-base-devel qt6-base-private-devel qt6-declarative-devel qt6-tools-devel qt6-shadertools-devel qt6-websockets-devel
  kwin-devel kdecoration-devel libplasma-devel plasma-workspace-devel plasma-activities-devel
  kf6-kconfigwidgets-devel kf6-kcmutils-devel kf6-ki18n-devel kf6-kservice-devel kf6-kwindowsystem-devel
  kf6-knotifications-devel kf6-kio-devel kf6-kcrash-devel kf6-kguiaddons-devel kf6-kglobalaccel-devel
  kf6-kdeclarative-devel kf6-kconfig-devel kf6-kcoreaddons-devel
  libepoxy-devel libdrm-devel wayland-devel libxcb-devel libx11-devel vulkan-headers
)

step() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }

if command -v moss >/dev/null; then
  missing=()
  for p in "${AERYN_PKGS[@]}"; do
    moss list installed 2>/dev/null | grep -q "^$p " || missing+=("$p")
  done
  if ((${#missing[@]})); then
    step "Installing build dependencies with moss"
    sudo moss install -y "${missing[@]}"
  fi
else
  echo "Not AerynOS: make sure a C++ compiler, cmake, ninja, extra-cmake-modules and the"
  echo "KWin/Plasma/KF6/Qt6 development packages are installed (see each project's README)."
fi

mkdir -p "$SRC"
for entry in "${PROJECTS[@]}"; do
  IFS='|' read -r name url ref extra <<<"$entry"
  step "Building $name ($ref)"
  rm -rf "$SRC/$name"
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$ref" "$url" "$SRC/$name"
  # shellcheck disable=SC2086
  cmake -S "$SRC/$name" -B "$SRC/$name/build" -G Ninja -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF \
    -DKDE_INSTALL_PLUGINDIR=lib/qt6/plugins -DKDE_INSTALL_QMLDIR=lib/qt6/qml $extra
  cmake --build "$SRC/$name/build" -j"$JOBS"
  cmake --install "$SRC/$name/build"
done

# cmake's plasma_install_package drops the exec bit on the visualizer helper
chmod 700 "$PREFIX/share/plasma/plasmoids/luisbocanegra.audio.visualizer/contents/ui/tools/commandMonitor" 2>/dev/null || true

step "Done. Log out and back in so KWin loads the effects."
