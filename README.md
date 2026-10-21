# Catppuccin Mocha · KDE Plasma 6 rice

A Catppuccin **Mocha** (Mauve accent) setup for **KDE Plasma 6** on Wayland, built and tested on
[AerynOS](https://aerynos.com) with Plasma 6.7. It should work on any distro with Plasma 6.

- **Top bar:** app launcher, Kara workspace pills, global app menu, now-playing music controls,
  audio visualizer, centered clock, CPU/RAM graphs and tray, each group in its own floating
  rounded "pill" (Panel Colorizer)
- **Dock:** centered, floating, fit-to-content, always visible, compact icon spacing
- **Windows:** rounded corners with a mauve outline on the focused window, blur behind
  Konsole/menus/panels, Klassy decorations, Kvantum Catppuccin app style
- **Everywhere:** Catppuccin color scheme, cursors, GTK 3/4 + Flatpak theming, Papirus-Dark icons
- **Terminal:** Konsole profile (90% opacity + blur), zsh with autosuggestions and syntax highlighting,
  starship prompt, fastfetch, btop, cava
- **Extras:** Spotify (Spicetify), Vesktop/Discord and a Plymouth boot splash, all in Mocha

## Quick start

```bash
git clone https://github.com/exophs/plasma-catppuccin-rice
cd plasma-catppuccin-rice
./install.sh                 # themes, configs, widgets, panels (no root needed)
./scripts/build-extras.sh    # optional: rounded corners, blur, Kara, audio visualizer
```

Then log out and back in.

> [!WARNING]
> `install.sh` **replaces all your panels** with this layout. To keep your own panels, run
> `./install.sh --no-layout`. Every file it touches is backed up to
> `~/.config/catppuccin-rice-backup-<timestamp>/` first.

### Requirements

| Needed for | Packages |
|---|---|
| `install.sh` | Plasma 6, `curl`, `git`, `unzip`, `python3`, `qdbus6`, `kwriteconfig6` |
| Full look (installed separately) | `kvantum`, `klassy`, `papirus-icon-theme`, `zsh` |
| Terminal extras | `starship`, `fastfetch`, `btop`, `cava` |
| `build-extras.sh` | C++ compiler, `cmake`, `ninja`, `extra-cmake-modules`, KWin/Plasma/KF6/Qt6 dev packages (installed automatically on AerynOS) |

The installer skips anything that's missing and tells you, so you can install it later and re-run.

<details>
<summary>AerynOS one-liner for the packages</summary>

```bash
sudo moss install -y kvantum klassy papirus-icon-theme zsh starship fastfetch btop cava
```
</details>

## What goes where

```
dotfiles/            copied into $HOME
  .zshrc
  .config/starship.toml, fastfetch/, btop/, cava/, Kvantum/
  .config/environment.d/90-rice-local-plugins.conf   lets KWin/Plasma load plugins from ~/.local
  .local/share/konsole/Catppuccin.profile
plasma/layout.js     Plasma scripting layout: top bar + dock on every screen
install.sh           per-user installer (downloads the Catppuccin themes, applies settings)
scripts/build-extras.sh   builds the compiled KWin effects and widgets into ~/.local
packages/            AerynOS (moss) package recipe for the boot splash
```

## Optional extras

### Rounded corners, blur, Kara, audio visualizer

```bash
./scripts/build-extras.sh
```

These are compiled against your installed KWin, so **re-run this after every Plasma update**
(if the corners or blur disappear after an update, that's why).
Everything installs into `~/.local`, never `/usr`.

| Project | Version |
|---|---|
| [KDE Rounded Corners](https://github.com/matinlotfali/KDE-Rounded-Corners) | v0.10.0 |
| [Better Blur DX](https://github.com/xarblu/kwin-effects-better-blur-dx) | main |
| [Kara](https://github.com/dhruv8sh/kara) | v1.0.0 |
| [Plasma Audio Visualizer](https://github.com/luisbocanegra/plasma-audio-visualizer) | v3.6.1 |

Tweak them in **System Settings → Window Management → Desktop Effects** (gear icon next to
*ShapeCorners* / *Better Blur DX*), or right-click a widget → *Configure*.

### Spotify (Spicetify)

```bash
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
git clone --depth 1 https://github.com/catppuccin/spicetify /tmp/ctp-spicetify
cp -r /tmp/ctp-spicetify/catppuccin ~/.config/spicetify/Themes/
spicetify config current_theme catppuccin color_scheme mocha inject_css 1 inject_theme_js 1 replace_colors 1 overwrite_assets 1
spicetify backup apply
```

**Flatpak Spotify:** Spicetify has to write into Spotify's install folder, so first run (with
Spotify closed):

```bash
SP=/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify
sudo chmod a+wr "$SP" && sudo chmod a+wr -R "$SP/Apps"
spicetify config spotify_path "$SP" prefs_path ~/.var/app/com.spotify.Client/config/spotify/prefs
```

Spotify has to have been opened once so the `prefs` file exists. Repeat the `chmod` and
`spicetify backup apply` after Spotify updates.

### Vesktop / Discord (Vencord)

Vencord settings → *Themes* → *Online Themes*, add:

```
https://catppuccin.github.io/discord/dist/catppuccin-mocha-mauve.theme.css
```

### Brave / Chrome

Install the [Catppuccin Mocha Chrome theme](https://github.com/catppuccin/chrome).

### Boot splash (Plymouth)

**AerynOS:** `/usr` is rebuilt on every `moss` transaction, so the theme ships as a local
moss package (`packages/plymouth-theme-catppuccin-mocha`). It also adds a small shared initrd
(`/usr/lib/kernel/initrd.d/90-catppuccin-plymouth.initrd`) so the theme is used during early boot.

```bash
cd packages/plymouth-theme-catppuccin-mocha
boulder build -u stone.yaml
mkdir -p ~/.local/share/rice-repo && mv *.stone ~/.local/share/rice-repo/ && moss index ~/.local/share/rice-repo
sudo moss repo add -p 10 rice-local file://$HOME/.local/share/rice-repo/stone.index
sudo moss install plymouth-theme-catppuccin-mocha
sudo install -Dm644 pkg/plymouthd.conf /etc/plymouth/plymouthd.conf
```

If it misbehaves, pick the previous entry in the boot menu, or
`sudo moss remove plymouth-theme-catppuccin-mocha`.

**Other distros:** use [catppuccin/plymouth](https://github.com/catppuccin/plymouth) and your
distro's `plymouth-set-default-theme -R catppuccin-mocha`.

## Notes for AerynOS

- **Never install into `/usr` by hand**: `moss` rebuilds `/usr` on every install/update and
  anything not owned by a package disappears. That's why the extras build into `~/.local` and the
  boot splash is a package.
- **NVIDIA hybrid laptops:** for Prism Launcher / Minecraft on the dGPU with the open nouveau/NVK
  stack, enable *Settings → Minecraft → Tweaks → Use discrete GPU* in Prism.

## Wallpaper

Not included (unknown license). Any dark, low-contrast wallpaper works; the
[Catppuccin wallpapers](https://github.com/zhichaoh/catppuccin-wallpapers) collection is a good start.

## Credits

Everything here stands on [Catppuccin](https://github.com/catppuccin) ports (KDE, Kvantum, Konsole,
GTK, cursors, btop, cava, starship, Plymouth, Spicetify, Discord) plus
[Klassy](https://github.com/paulmcauley/klassy),
[Panel Colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer),
[PlasMusic Toolbar](https://github.com/ccatterina/plasmusic-toolbar),
[Kara](https://github.com/dhruv8sh/kara),
[KDE Rounded Corners](https://github.com/matinlotfali/KDE-Rounded-Corners),
[Better Blur DX](https://github.com/xarblu/kwin-effects-better-blur-dx),
[Plasma Audio Visualizer](https://github.com/luisbocanegra/plasma-audio-visualizer),
[catppuccin-klassy](https://github.com/helenclx/catppuccin-klassy) and the
[zsh-users](https://github.com/zsh-users) plugins.

## License

MIT for this repo's scripts and configs. Bundled Catppuccin files keep their own MIT licenses.
