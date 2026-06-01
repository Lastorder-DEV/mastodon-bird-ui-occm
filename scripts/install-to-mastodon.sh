#!/bin/bash
# Mastodon Bird UI - Install as a glitch-soc skin for the glitch flavour
# https://github.com/ronilaukkarinen/mastodon-bird-ui
#
# glitch-soc does not use upstream Mastodon's config/themes.yml site-theme
# pipeline. Its default frontend is the `glitch` flavour, and CSS-only themes
# for that frontend are installed as skins under:
#   app/javascript/skins/glitch/<skin-name>/common.scss
#
# Usage: sudo bash scripts/install-to-mastodon.sh --path /opt/mastodon

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
MASTODON_PATH="${MASTODON_PATH:-}"
ADD_VARIATIONS=""
SET_DEFAULT=""

# Get script directory and version
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../src"
VERSION=$(grep -m1 -E '^### [0-9]' "$SCRIPT_DIR/../CHANGELOG.md" | sed 's/### \([^:]*\):.*/\1/' | tr -d '\r' || true)
VERSION=${VERSION:-unknown}

usage() {
  echo "Usage: sudo bash $0 [-p|--path /path/to/glitch-soc] [-v|--variations] [-d|--default]"
  echo ""
  echo "Installs Mastodon Bird UI as a glitch-soc skin for the glitch flavour."
  echo ""
  echo "Options:"
  echo "  -p, --path        Path to glitch-soc/Mastodon installation"
  echo "  -v, --variations  Add accessible skin variations"
  echo "  -d, --default     Set the server default flavour/skin to glitch/Mastodon Bird UI"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  sudo bash $0 --path /opt/mastodon"
  echo "  sudo bash $0 --path /opt/mastodon --variations --default"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--path)
      MASTODON_PATH="$2"
      shift 2
      ;;
    -v|--variations)
      ADD_VARIATIONS="y"
      shift
      ;;
    -d|--default)
      SET_DEFAULT="y"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

# Check if Mastodon path is provided. Keep non-interactive installs safe by
# failing fast when stdin is not a TTY.
if [ -z "$MASTODON_PATH" ]; then
  if [ -t 0 ]; then
    echo -e "${YELLOW}glitch-soc path not specified.${NC}"
    read -r -p "Enter your glitch-soc installation path: " MASTODON_PATH
  else
    echo -e "${RED}Error: --path is required in non-interactive mode.${NC}"
    exit 1
  fi
fi

# Validate Mastodon/glitch-soc path
if [ ! -d "$MASTODON_PATH" ]; then
  echo -e "${RED}Error: Directory not found: $MASTODON_PATH${NC}"
  exit 1
fi

FLAVOUR_DIR="$MASTODON_PATH/app/javascript/flavours/glitch"
GLITCH_THEME_FILE="$FLAVOUR_DIR/theme.yml"
SKINS_ROOT="$MASTODON_PATH/app/javascript/skins/glitch"
BASE_SKIN="mastodon-bird-ui"
BASE_SKIN_PATH="$SKINS_ROOT/$BASE_SKIN"
BASE_MODULE_PATH="$BASE_SKIN_PATH/mastodon-bird-ui"
SETTINGS_FILE="$MASTODON_PATH/config/settings.yml"

if [ ! -f "$GLITCH_THEME_FILE" ]; then
  echo -e "${RED}Error: glitch flavour not found at $GLITCH_THEME_FILE${NC}"
  echo "This installer targets glitch-soc. For upstream Mastodon custom CSS, use dist/mastodon-bird-ui.css instead."
  exit 1
fi

if [ ! -d "$SKINS_ROOT" ]; then
  echo -e "${RED}Error: Skins directory not found: $SKINS_ROOT${NC}"
  exit 1
fi

if [ ! -f "$SETTINGS_FILE" ]; then
  echo -e "${RED}Error: settings.yml not found: $SETTINGS_FILE${NC}"
  exit 1
fi

echo -e "${GREEN}Mastodon Bird UI $VERSION for glitch-soc${NC}"
echo ""

# Ask about variations if not specified via flag. Default to no when running
# non-interactively.
if [ -z "$ADD_VARIATIONS" ]; then
  if [ -t 0 ]; then
    read -r -p "Add/update accessible skin variations? [y/N]: " ADD_VARIATIONS
    ADD_VARIATIONS=${ADD_VARIATIONS:-n}
  else
    ADD_VARIATIONS="n"
  fi
fi

# --- Step 1: Copy module files into the base skin ---
echo -e "${BLUE}[1/4] Updating Bird UI skin module files...${NC}"

mkdir -p "$BASE_MODULE_PATH/components/profile/icons"
mkdir -p "$BASE_MODULE_PATH/layouts"
mkdir -p "$BASE_MODULE_PATH/micro-interactions"
mkdir -p "$BASE_MODULE_PATH/variables"
mkdir -p "$BASE_MODULE_PATH/variants"

copy_if_exists() {
  local src="$1"
  local dest="$2"
  if [ -f "$src" ]; then
    cp "$src" "$dest"
    echo -e "  ${GREEN}Updated:${NC} ${dest#$MASTODON_PATH/app/javascript/}"
  fi
}

# Core module files
copy_if_exists "$SRC_DIR/_index.scss" "$BASE_MODULE_PATH/_index.scss"

# Variables
for f in "$SRC_DIR/variables/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/variables/$(basename "$f")"
done

# Components
for f in "$SRC_DIR/components/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/components/$(basename "$f")"
done

# Profile components
for f in "$SRC_DIR/components/profile/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/components/profile/$(basename "$f")"
done

# Profile icons
for f in "$SRC_DIR/components/profile/icons/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/components/profile/icons/$(basename "$f")"
done

# Layouts
for f in "$SRC_DIR/layouts/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/layouts/$(basename "$f")"
done

# Micro-interactions
for f in "$SRC_DIR/micro-interactions/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/micro-interactions/$(basename "$f")"
done

# Variants
for f in "$SRC_DIR/variants/"_*.scss; do
  [ -f "$f" ] && copy_if_exists "$f" "$BASE_MODULE_PATH/variants/$(basename "$f")"
done

# Module entry point used by the skin packs.
cat > "$BASE_MODULE_PATH/mastodon-bird-ui.scss" <<'SCSS'
@use "index";
SCSS

echo -e "${GREEN}Module files updated.${NC}"

write_skin_names() {
  local skin_path="$1"
  local skin_key="$2"
  local en_name="$3"
  local ko_name="$4"

  cat > "$skin_path/names.yml" <<YAML
en:
  skins:
    glitch:
      $skin_key: $en_name
ko:
  skins:
    glitch:
      $skin_key: $ko_name
YAML
}

# --- Step 2: Create glitch-soc skin packs ---
echo ""
echo -e "${BLUE}[2/4] Writing glitch skin packs...${NC}"

cat > "$BASE_SKIN_PATH/common.scss" <<'SCSS'
// Mastodon Bird UI for glitch-soc's glitch flavour.
//
// A glitch skin replaces the flavour's common stylesheet instead of layering on
// top of it, so this pack imports the default glitch application stylesheet
// first and then applies Bird UI overrides.
@use '@/flavours/glitch/styles/application';
@use 'mastodon-bird-ui';
SCSS
write_skin_names "$BASE_SKIN_PATH" "$BASE_SKIN" "Mastodon Bird UI" "유사 트위터"
echo -e "  ${GREEN}Updated:${NC} skins/glitch/$BASE_SKIN/common.scss"

if [[ "$ADD_VARIATIONS" =~ ^[Yy]$ ]]; then
  ACCESSIBLE_SKIN_PATH="$SKINS_ROOT/mastodon-bird-ui-accessible"
  ACCESSIBLE_PLUS_SKIN_PATH="$SKINS_ROOT/mastodon-bird-ui-accessible-plus"
  mkdir -p "$ACCESSIBLE_SKIN_PATH" "$ACCESSIBLE_PLUS_SKIN_PATH"

  cat > "$ACCESSIBLE_SKIN_PATH/common.scss" <<'SCSS'
// Accessible Mastodon Bird UI for glitch-soc's glitch flavour.
@use '@/flavours/glitch/styles/application';
@use '../mastodon-bird-ui/mastodon-bird-ui';
@use '../mastodon-bird-ui/mastodon-bird-ui/variants/accessible';
SCSS
  write_skin_names "$ACCESSIBLE_SKIN_PATH" "mastodon-bird-ui-accessible" "Mastodon Bird UI (Accessible)" "유사 트위터 (접근성)"
  echo -e "  ${GREEN}Updated:${NC} skins/glitch/mastodon-bird-ui-accessible/common.scss"

  cat > "$ACCESSIBLE_PLUS_SKIN_PATH/common.scss" <<'SCSS'
// Accessible Plus Mastodon Bird UI for glitch-soc's glitch flavour.
@use '@/flavours/glitch/styles/application';
@use '../mastodon-bird-ui/mastodon-bird-ui';
@use '../mastodon-bird-ui/mastodon-bird-ui/variants/accessible-plus';
SCSS
  write_skin_names "$ACCESSIBLE_PLUS_SKIN_PATH" "mastodon-bird-ui-accessible-plus" "Mastodon Bird UI (Accessible Plus)" "유사 트위터 (접근성 플러스)"
  echo -e "  ${GREEN}Updated:${NC} skins/glitch/mastodon-bird-ui-accessible-plus/common.scss"
fi

# --- Step 3: Optionally update server defaults ---
if [ -z "$SET_DEFAULT" ]; then
  if [ -t 0 ]; then
    read -r -p "Set glitch/Mastodon Bird UI as the server default flavour and skin? [y/N]: " SET_DEFAULT
    SET_DEFAULT=${SET_DEFAULT:-n}
  else
    SET_DEFAULT="n"
  fi
fi

echo ""
echo -e "${BLUE}[3/4] Updating glitch-soc defaults...${NC}"

if [[ "$SET_DEFAULT" =~ ^[Yy]$ ]]; then
  sed -i "s/^  flavour: .*/  flavour: 'glitch'/" "$SETTINGS_FILE"
  sed -i "s/^  skin: .*/  skin: '$BASE_SKIN'/" "$SETTINGS_FILE"
  echo -e "  ${GREEN}Set:${NC} config/settings.yml default flavour: glitch"
  echo -e "  ${GREEN}Set:${NC} config/settings.yml default skin: $BASE_SKIN"
  echo -e "  ${YELLOW}Note:${NC} Existing database-backed admin settings may override config/settings.yml."
  echo "        If needed, set the default flavour/skin in Administration > Server settings, or run:"
  echo "        RAILS_ENV=production bin/tootctl settings set flavour glitch"
  echo "        RAILS_ENV=production bin/tootctl settings set skin $BASE_SKIN"
else
  echo -e "  ${YELLOW}Skipped:${NC} Server default unchanged. Users can select the skin in Preferences > Flavours."
fi

# --- Step 4: Fix ownership and permissions ---
echo ""
echo -e "${BLUE}[4/4] Fixing file ownership and permissions...${NC}"
chmod -R a+r "$BASE_SKIN_PATH"
find "$BASE_SKIN_PATH" -type d -exec chmod a+rx {} \;

if [[ "$ADD_VARIATIONS" =~ ^[Yy]$ ]]; then
  chmod -R a+r "$SKINS_ROOT/mastodon-bird-ui-accessible" "$SKINS_ROOT/mastodon-bird-ui-accessible-plus"
  find "$SKINS_ROOT/mastodon-bird-ui-accessible" "$SKINS_ROOT/mastodon-bird-ui-accessible-plus" -type d -exec chmod a+rx {} \;
fi

if id mastodon >/dev/null 2>&1; then
  chown -R mastodon:mastodon "$BASE_SKIN_PATH"
  if [[ "$ADD_VARIATIONS" =~ ^[Yy]$ ]]; then
    chown -R mastodon:mastodon "$SKINS_ROOT/mastodon-bird-ui-accessible" "$SKINS_ROOT/mastodon-bird-ui-accessible-plus"
  fi
  chown mastodon:mastodon "$SETTINGS_FILE"
else
  echo -e "  ${YELLOW}Skipped chown:${NC} user 'mastodon' does not exist on this system."
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Installed skins:"
echo "  - glitch/$BASE_SKIN"
if [[ "$ADD_VARIATIONS" =~ ^[Yy]$ ]]; then
  echo "  - glitch/mastodon-bird-ui-accessible"
  echo "  - glitch/mastodon-bird-ui-accessible-plus"
fi
echo ""
echo "Next steps:"
echo "  cd $MASTODON_PATH"
echo "  RAILS_ENV=production bundle exec rails assets:precompile"
echo "  sudo systemctl restart mastodon-web"
echo ""
echo "Users can select the skin in Preferences > Flavours with flavour 'glitch'."
