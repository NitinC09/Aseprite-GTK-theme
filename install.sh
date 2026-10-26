#!/bin/sh
# Install the Aseprite theme for the current user.
#
#   ./install.sh                  copy the theme to ~/.local/share/themes/Aseprite
#   ./install.sh --libadwaita     same, and also style libadwaita apps
#   ./install.sh --libadwaita-only
#                                 only style libadwaita apps, straight from
#                                 this folder (for a git clone you symlink into
#                                 ~/.themes yourself; `git pull` updates it)
#   ./install.sh --uninstall      remove the copy and the libadwaita override
#
# libadwaita apps ignore GTK themes, so the override is a small
# ~/.config/gtk-4.0/gtk.css that @imports this theme's GTK 4 stylesheet.
set -eu

SRC=$(cd "$(dirname "$0")" && pwd -P)
DEST="${XDG_DATA_HOME:-$HOME}/.themes/Aseprite-GTK-theme"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
MARK="/* aseprite-theme: written by install.sh */"

is_ours() { [ -f "$CFG/gtk.css" ] && head -n1 "$CFG/gtk.css" | grep -qF "$MARK"; }

remove_libadwaita() {
  if is_ours; then
    rm -f "$CFG/gtk.css"
    rm -rf "$CFG/assets"   # left behind by older versions of this script
    [ -f "$CFG/gtk.css.bak" ] && mv "$CFG/gtk.css.bak" "$CFG/gtk.css"
    echo "Removed the libadwaita override from $CFG"
  fi
}

# $1 = theme folder whose gtk-4.0/ stylesheets should be imported
write_libadwaita() {
  mkdir -p "$CFG"
  if [ -f "$CFG/gtk.css" ] && ! is_ours; then
    mv "$CFG/gtk.css" "$CFG/gtk.css.bak"
    echo "Backed up your existing $CFG/gtk.css to gtk.css.bak"
  fi
  rm -rf "$CFG/assets"
  {
    echo "$MARK"
    echo "@import url(\"file://$1/gtk-4.0/gtk.css\");"
    echo "/* CSS variables for libadwaita 1.6+; needs GTK 4.16+ */"
    echo "@import url(\"file://$1/gtk-4.0/libadwaita.css\");"
  } > "$CFG/gtk.css"
  echo "libadwaita apps now load the theme from $1"
}

case "${1:-}" in
  --uninstall)
    rm -rf "$DEST"
    echo "Removed $DEST"
    remove_libadwaita
    exit 0 ;;
  --libadwaita-only)
    write_libadwaita "$SRC"
    exit 0 ;;
  ""|--libadwaita) ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac

mkdir -p "$DEST"
cp -r "$SRC/index.theme" "$SRC/gtk-3.0" "$SRC/gtk-4.0" "$SRC/xfwm4" "$DEST/"
echo "Installed to $DEST"
[ "${1:-}" = "--libadwaita" ] && write_libadwaita "$DEST"

cat <<'EOF'

Select the theme:
  Xfce (xfwm4):  Settings > Appearance > Style: Aseprite
                 Settings > Window Manager > Style: Aseprite
  Wayland (niri, Sway, Hyprland, labwc, ...):
                 gsettings set org.gnome.desktop.interface gtk-theme Aseprite
                 and/or put  gtk-theme-name=Aseprite  under [Settings] in
                 ~/.config/gtk-3.0/settings.ini and ~/.config/gtk-4.0/settings.ini
Restart running apps to see the change.
EOF
