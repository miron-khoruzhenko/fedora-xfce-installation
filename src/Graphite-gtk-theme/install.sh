#! /usr/bin/env bash

set -Eeo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SRC_DIR="${REPO_DIR}/src"

ROOT_UID=0
DEST_DIR=

ctype=

themes=()
colors=()
sizes=()

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "$XDG_DATA_HOME" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"

THEME_NAME=Graphite
THEME_VARIANTS=('' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-teal' '-blue')
COLOR_VARIANTS=('' '-Light' '-Dark')
SIZE_VARIANTS=('' '-compact')

if [[ "$(command -v gnome-shell)" ]]; then
  gnome-shell --version
  SHELL_VERSION="$(gnome-shell --version | cut -d ' ' -f 3 | cut -d . -f -1)"
  if [[ "${SHELL_VERSION:-}" -ge "46" ]]; then
    GS_VERSION="46-0"
  elif [[ "${SHELL_VERSION:-}" -ge "44" ]]; then
    GS_VERSION="44-0"
  elif [[ "${SHELL_VERSION:-}" -ge "42" ]]; then
    GS_VERSION="42-0"
  elif [[ "${SHELL_VERSION:-}" -ge "40" ]]; then
    GS_VERSION="40-0"
  else
    GS_VERSION="3-28"
  fi
  else
    echo "'gnome-shell' not found, using styles for last gnome-shell version available."
    GS_VERSION="46-0"
fi

#  Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

#  Install needed packages
install_package() {
  if ! has_command sassc; then
    echo -e "\nsassc needs to be installed to generate the css."
    if has_command zypper; then
      sudo zypper in sassc
    elif has_command apt; then
      sudo apt install sassc
    elif has_command apt-get; then
      sudo apt-get install sassc
    elif has_command dnf; then
      sudo dnf install sassc
    elif has_command yum; then
      sudo yum install sassc
    elif has_command pacman; then
      sudo pacman -S --noconfirm sassc
    fi
  fi
}

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)

  -n, --name NAME         Specify theme name (Default: $THEME_NAME)

  -t, --theme VARIANT     Specify theme color variant(s) [default|purple|pink|red|orange|yellow|green|teal|blue|all] (Default: grey)

  -c, --color VARIANT     Specify color variant(s) [standard|light|dark] (Default: All variants)s)

  -s, --size VARIANT      Specify size variant [standard|compact] (Default: standard variants)

  -g, --gdm               Install GDM theme

  -l, --libadwaita        Install link to gtk4 config for theming libadwaita

  -u, --uninstall         Uninstall themes or link for libadwaita

  --tweaks                Specify versions for tweaks [nord|black|darker|rimless|normal]
                          (WORRING: 'nord' and 'darker' can not mix use with 'black'!)
                          1. nord       Nord colorscheme version
                          2. black      Blackness colorscheme version
                          3. darker     Darker (default|nord) color version (black option can not be darker)
                          4. rimless    Remove the 2px outline about windows and menus
                          5. normal     Normal sidebar style (Nautilus)
                          6. float      Float gnome-shell panel style
                          7. colorful   Colorful gnome-shell panel style

  -h, --help              Show help
EOF
}

install() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"
  local ctype="${6}"

  [[ "${color}" == '-Light' ]] && local ELSE_LIGHT="${color}" && local icon_color="-light"
  [[ "${color}" == '-Dark' ]] && local ELSE_DARK="${color}" && local icon_color="-dark"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  [[ -d "${THEME_DIR}" ]] && rm -rf "${THEME_DIR}"

  echo "Installing '${THEME_DIR}'..."

  theme_tweaks

  mkdir -p                                                                                   "${THEME_DIR}"

  echo "[Desktop Entry]" >>                                                                  "${THEME_DIR}/index.theme"
  echo "Type=X-GNOME-Metatheme" >>                                                           "${THEME_DIR}/index.theme"
  echo "Name=${2}${3}${4}${5}${6}" >>                                                        "${THEME_DIR}/index.theme"
  echo "Comment=An Flat Gtk+ theme based on Elegant Design" >>                               "${THEME_DIR}/index.theme"
  echo "Encoding=UTF-8" >>                                                                   "${THEME_DIR}/index.theme"
  echo "" >>                                                                                 "${THEME_DIR}/index.theme"
  echo "[X-GNOME-Metatheme]" >>                                                              "${THEME_DIR}/index.theme"
  echo "GtkTheme=${2}${3}${4}${5}${6}" >>                                                    "${THEME_DIR}/index.theme"
  echo "MetacityTheme=${2}${3}${4}${5}${6}" >>                                               "${THEME_DIR}/index.theme"
  echo "IconTheme=Tela-circle${icon_color}" >>                                               "${THEME_DIR}/index.theme"
  echo "CursorTheme=${2}-cursors" >>                                                         "${THEME_DIR}/index.theme"
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                        "${THEME_DIR}/index.theme"

  mkdir -p                                                                                   "${THEME_DIR}/gnome-shell"
  cp -r "${SRC_DIR}/main/gnome-shell/pad-osd.css"                                            "${THEME_DIR}/gnome-shell"
  sassc $SASSC_OPT "${SRC_DIR}/main/gnome-shell/gnome-shell${color}.scss"                    "${THEME_DIR}/gnome-shell/gnome-shell.css"

  cp -r "${SRC_DIR}/assets/gnome-shell/common-assets"                                        "${THEME_DIR}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/assets${ELSE_DARK:-}/"*.svg                           "${THEME_DIR}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/theme${theme}${ctype}/"*.svg                          "${THEME_DIR}/gnome-shell/assets"

  cd "${THEME_DIR}/gnome-shell"
  ln -s assets/no-events.svg no-events.svg
  ln -s assets/process-working.svg process-working.svg
  ln -s assets/no-notifications.svg no-notifications.svg

  mkdir -p                                                                                   "${THEME_DIR}/gtk-2.0"
  cp -r "${SRC_DIR}/main/gtk-2.0/gtkrc${theme}${ELSE_DARK:-}${ctype}"                        "${THEME_DIR}/gtk-2.0/gtkrc"
  cp -r "${SRC_DIR}/main/gtk-2.0/common/"*'.rc'                                              "${THEME_DIR}/gtk-2.0"
  cp -r "${SRC_DIR}/assets/gtk-2.0/assets-common${ELSE_DARK:-}${ctype}"                      "${THEME_DIR}/gtk-2.0/assets"
  cp -r "${SRC_DIR}/assets/gtk-2.0/assets${theme}${ELSE_DARK:-}${ctype}/"*.png               "${THEME_DIR}/gtk-2.0/assets"

  mkdir -p                                                                                   "${THEME_DIR}/gtk-3.0"
  cp -r "${SRC_DIR}/assets/gtk/assets${theme}"                                               "${THEME_DIR}/gtk-3.0/assets"
  cp -r "${SRC_DIR}/assets/gtk/scalable"                                                     "${THEME_DIR}/gtk-3.0/assets"
  cp -r "${SRC_DIR}/assets/gtk/thumbnail${theme}${ELSE_DARK:-}.png"                          "${THEME_DIR}/gtk-3.0/thumbnail.png"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-3.0/gtk${color}.scss"                                "${THEME_DIR}/gtk-3.0/gtk.css"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-3.0/gtk-Dark.scss"                                   "${THEME_DIR}/gtk-3.0/gtk-dark.css"

  mkdir -p                                                                                   "${THEME_DIR}/gtk-4.0"
  cp -r "${SRC_DIR}/assets/gtk/assets${theme}"                                               "${THEME_DIR}/gtk-4.0/assets"
  cp -r "${SRC_DIR}/assets/gtk/scalable"                                                     "${THEME_DIR}/gtk-4.0/assets"
  cp -r "${SRC_DIR}/assets/gtk/thumbnail${theme}${ELSE_DARK:-}.png"                          "${THEME_DIR}/gtk-4.0/thumbnail.png"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-4.0/gtk${color}.scss"                                "${THEME_DIR}/gtk-4.0/gtk.css"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-4.0/gtk-Dark.scss"                                   "${THEME_DIR}/gtk-4.0/gtk-dark.css"

  mkdir -p                                                                                   "${THEME_DIR}/cinnamon"
  cp -r "${SRC_DIR}/assets/cinnamon/common-assets"                                           "${THEME_DIR}/cinnamon/assets"
  cp -r "${SRC_DIR}/assets/cinnamon/assets${ELSE_DARK:-}/"*'.svg'                            "${THEME_DIR}/cinnamon/assets"
  cp -r "${SRC_DIR}/assets/cinnamon/theme${theme}/"*'.svg'                                   "${THEME_DIR}/cinnamon/assets"
  sassc $SASSC_OPT "${SRC_DIR}/main/cinnamon/cinnamon${color}.scss"                          "${THEME_DIR}/cinnamon/cinnamon.css"
  cp -r "${SRC_DIR}/assets/cinnamon/thumbnail${color}.png"                                   "${THEME_DIR}/cinnamon/thumbnail.png"

  mkdir -p                                                                                   "${THEME_DIR}/metacity-1"
  cp -r "${SRC_DIR}/main/metacity-1/metacity-theme-2${color}.xml"                            "${THEME_DIR}/metacity-1/metacity-theme-2.xml"
  cp -r "${SRC_DIR}/main/metacity-1/metacity-theme-3.xml"                                    "${THEME_DIR}/metacity-1"
  cp -r "${SRC_DIR}/assets/metacity-1/assets"                                                "${THEME_DIR}/metacity-1"
  cp -r "${SRC_DIR}/assets/metacity-1/thumbnail${ELSE_DARK:-}.png"                           "${THEME_DIR}/metacity-1/thumbnail.png"
  cd "${THEME_DIR}/metacity-1" && ln -s metacity-theme-2.xml metacity-theme-1.xml

  mkdir -p                                                                                   "${THEME_DIR}/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/assets${ELSE_LIGHT:-}${ctype}/"*.png                        "${THEME_DIR}/xfwm4"
  cp -r "${SRC_DIR}/main/xfwm4/themerc${ELSE_LIGHT:-}"                                       "${THEME_DIR}/xfwm4/themerc"
  mkdir -p                                                                                   "${THEME_DIR}-hdpi/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/assets${ELSE_LIGHT:-}${ctype}-hdpi/"*.png                   "${THEME_DIR}-hdpi/xfwm4"
  cp -r "${SRC_DIR}/main/xfwm4/themerc${ELSE_LIGHT:-}"                                       "${THEME_DIR}-hdpi/xfwm4/themerc"
  mkdir -p                                                                                   "${THEME_DIR}-xhdpi/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/assets${ELSE_LIGHT:-}${ctype}-xhdpi/"*.png                  "${THEME_DIR}-xhdpi/xfwm4"
  cp -r "${SRC_DIR}/main/xfwm4/themerc${ELSE_LIGHT:-}"                                       "${THEME_DIR}-xhdpi/xfwm4/themerc"

  mkdir -p                                                                                   "${THEME_DIR}/plank"
  if [[ "$color" == '-Light' ]]; then
    cp -r "${SRC_DIR}/main/plank/theme-Light/"*                                              "${THEME_DIR}/plank"
  else
    cp -r "${SRC_DIR}/main/plank/theme-Dark/"*                                               "${THEME_DIR}/plank"
  fi
}

# GDM Theme

check_exist() {
  [[ -f "${1}" || -f "${1}.bak" ]]
}

restore_file() {
  if [[ -f "${1}.bak" || -d "${1}.bak" ]]; then
    rm -rf "${1}"; mv "${1}"{".bak",""}
  fi
}

backup_file() {
  if [[ -f "${1}" || -d "${1}" ]]; then
    mv -n "${1}"{"",".bak"}
  fi
}

install_theme_deps() {
  if ! has_command glib-compile-resources; then
    echo -e "\n'glib2.0' are required for theme installation."

    if has_command zypper; then
      sudo zypper in -y glib2-devel
    elif has_command swupd; then
      sudo swupd bundle-add libglib
    elif has_command apt; then
      sudo apt install libglib2.0-dev-bin
    elif has_command dnf; then
      sudo dnf install -y glib2-devel
    elif has_command yum; then
      sudo yum install -y glib2-devel
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed glib2
    elif has_command xbps-install; then
      sudo xbps-install -Sy glib-devel
    elif has_command eopkg; then
      sudo eopkg -y install glib2
    else
      echo -e "\nWARNING: We're sorry, your distro isn't officially supported yet.\n"
    fi
  fi
}

GS_THEME_DIR="/usr/share/gnome-shell/theme"
COMMON_CSS_FILE="/usr/share/gnome-shell/theme/gnome-shell.css"
UBUNTU_CSS_FILE="/usr/share/gnome-shell/theme/ubuntu.css"
ZORIN_CSS_FILE="/usr/share/gnome-shell/theme/zorin.css"
ETC_CSS_FILE="/etc/alternatives/gdm3.css"
ETC_GR_FILE="/etc/alternatives/gdm3-theme.gresource"
YARU_GR_FILE="/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"
POP_OS_GR_FILE="/usr/share/gnome-shell/theme/Pop/gnome-shell-theme.gresource"
ZORIN_GR_FILE="/usr/share/gnome-shell/theme/ZorinBlue-Light/gnome-shell-theme.gresource"
MISC_GR_FILE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
GS_GR_XML_FILE="${SRC_DIR}/main/gnome-shell/gnome-shell-theme.gresource.xml"

install_gdm() {
  local name="${1}"
  local theme="${2}"
  local gcolor="${3}"
  local size="${4}"
  local ctype="${5}"
  local TARGET=

  [[ "${gcolor}" == '-Light' ]] && local ELSE_LIGHT="${gcolor}"
  [[ "${gcolor}" == '-Dark' ]] && local ELSE_DARK="${gcolor}"

  local THEME_TEMP="/tmp/${1}${2}${3}${4}${5}"

  theme_tweaks

  echo -e "\nInstall ${1}${2}${3}${4} GDM Theme..."

  rm -rf "${THEME_TEMP}"
  mkdir -p                                                                                   "${THEME_TEMP}/gnome-shell"
  cp -r "${SRC_DIR}/main/gnome-shell/pad-osd.css"                                            "${THEME_TEMP}/gnome-shell"
  sassc $SASSC_OPT "${SRC_DIR}/main/gnome-shell/gnome-shell${gcolor}.scss"                   "${THEME_TEMP}/gnome-shell/gnome-shell.css"

  cp -r "${SRC_DIR}/assets/gnome-shell/common-assets"                                        "${THEME_TEMP}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/assets${ELSE_DARK}/"*.svg                             "${THEME_TEMP}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/theme${theme}${ctype}/"*.svg                          "${THEME_TEMP}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/scalable"                                             "${THEME_TEMP}/gnome-shell"
  cp -r "${SRC_DIR}/assets/gnome-shell/background${gcolor}${ctype}.png"                      "${THEME_TEMP}/gnome-shell/background.png"
  mv "${THEME_TEMP}/gnome-shell/assets/process-working.svg"                                  "${THEME_TEMP}/gnome-shell/process-working.svg"

  if check_exist "${COMMON_CSS_FILE}"; then # CSS-based theme
    if check_exist "${UBUNTU_CSS_FILE}"; then
      TARGET="${UBUNTU_CSS_FILE}"
    elif check_exist "${ZORIN_CSS_FILE}"; then
      TARGET="${ZORIN_CSS_FILE}"
    fi

    backup_file "${COMMON_CSS_FILE}"; backup_file "${TARGET}"

    if check_exist "${GS_THEME_DIR}/${name}"; then
      rm -rf "${GS_THEME_DIR}/${name}"
    fi

    cp -rf "${THEME_TEMP}/gnome-shell"                                                       "${GS_THEME_DIR}/${name}"
    ln -sf "${GS_THEME_DIR}/${name}/gnome-shell.css"                                         "${COMMON_CSS_FILE}"
    ln -sf "${GS_THEME_DIR}/${name}/gnome-shell.css"                                         "${TARGET}"

    # Fix previously installed theme
    restore_file "${ETC_CSS_FILE}"
  else # GR-based theme
    if check_exist "$POP_OS_GR_FILE"; then
      TARGET="${POP_OS_GR_FILE}"
    elif check_exist "$YARU_GR_FILE"; then
      TARGET="${YARU_GR_FILE}"
    elif check_exist "$ZORIN_GR_FILE"; then
      TARGET="${ZORIN_GR_FILE}"
    elif check_exist "$MISC_GR_FILE"; then
      TARGET="${MISC_GR_FILE}"
    fi

    backup_file "${TARGET}"
    glib-compile-resources --sourcedir="${THEME_TEMP}/gnome-shell" --target="${TARGET}" "${GS_GR_XML_FILE}"

    # Fix previously installed theme
    restore_file "${ETC_GR_FILE}"
  fi
}

uninstall_gdm_theme() {
  rm -rf "${GS_THEME_DIR}/$THEME_NAME"
  restore_file "${COMMON_CSS_FILE}"; restore_file "${UBUNTU_CSS_FILE}"
  restore_file "${ZORIN_CSS_FILE}"; restore_file "${ETC_CSS_FILE}"
  restore_file "${POP_OS_GR_FILE}"; restore_file "${YARU_GR_FILE}"
  restore_file "${MISC_GR_FILE}"; restore_file "${ETC_GR_FILE}"
  restore_file "${ZORIN_GR_FILE}"
}

# Clean Old Themes

clean() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"
  local type="${6}"

  [[ "${color}" == '-light' ]] && local ELSE_LIGHT="${color}"
  [[ "${color}" == '-dark' ]] && local ELSE_DARK="${color}"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  if [[ ${color} != '' && -d ${THEME_DIR} ]]; then
    rm -rf ${THEME_DIR}
    echo -e "Find: ${THEME_DIR} ! removing it ..."
  fi
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -d|--dest)
      dest="${2}"
      if [[ ! -d "${dest}" ]]; then
        echo "Destination directory does not exist. Let's make a new one..."
        mkdir -p ${dest}
      fi
      shift 2
      ;;
    -n|--name)
      name="${2}"
      shift 2
      ;;
    -g|--gdm)
      gdm="true"
      shift
      ;;
    -l|--libadwaita)
      libadwaita="true"
      shift
      ;;
    -r|--remove|-u|--uninstall)
      uninstall="true"
      shift
      ;;
    -c|--color)
      shift
      for color in "${@}"; do
        case "${color}" in
          standard)
            colors+=("${COLOR_VARIANTS[0]}")
            lcolors+=("${COLOR_VARIANTS[0]}")
            gcolors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          light)
            colors+=("${COLOR_VARIANTS[1]}")
            lcolors+=("${COLOR_VARIANTS[1]}")
            gcolors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[2]}")
            lcolors+=("${COLOR_VARIANTS[2]}")
            gcolors+=("${COLOR_VARIANTS[2]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -t|--theme)
      accent='true'
      shift
      for variant in "$@"; do
        case "$variant" in
          default)
            themes+=("${THEME_VARIANTS[0]}")
            shift
            ;;
          purple)
            themes+=("${THEME_VARIANTS[1]}")
            shift
            ;;
          pink)
            themes+=("${THEME_VARIANTS[2]}")
            shift
            ;;
          red)
            themes+=("${THEME_VARIANTS[3]}")
            shift
            ;;
          orange)
            themes+=("${THEME_VARIANTS[4]}")
            shift
            ;;
          yellow)
            themes+=("${THEME_VARIANTS[5]}")
            shift
            ;;
          green)
            themes+=("${THEME_VARIANTS[6]}")
            shift
            ;;
          teal)
            themes+=("${THEME_VARIANTS[7]}")
            shift
            ;;
          blue)
            themes+=("${THEME_VARIANTS[8]}")
            shift
            ;;
          all)
            themes+=("${THEME_VARIANTS[@]}")
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized theme variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -s|--size)
      shift
      for variant in "$@"; do
        case "$variant" in
          standard)
            sizes+=("${SIZE_VARIANTS[0]}")
            shift
            ;;
          compact)
            sizes+=("${SIZE_VARIANTS[1]}")
            compact='true'
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized size variant '${1:-}'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    --tweaks)
      shift
      for variant in $@; do
        case "$variant" in
          nord)
            nord="true"
            ctype="-nord"
            echo -e "Install Nord version! ..."
            shift
            ;;
          black)
            blackness="true"
            echo -e "Install Blackness version! ..."
            shift
            ;;
          darker)
            darker="true"
            echo -e "Install darker version! ..."
            shift
            ;;
          rimless)
            rimless="true"
            echo -e "Install Rimless version! ..."
            shift
            ;;
          normal)
            normal="true"
            echo -e "Install Normal sidebar version! ..."
            shift
            ;;
          float)
            float="true"
            echo -e "Install Float Gnome-Shell Panel version! ..."
            shift
            ;;
          colorful)
            colorful="true"
            echo -e "Install Colorful Gnome-Shell Panel version! ..."
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized tweaks variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '$1'."
      echo "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ "${#themes[@]}" -eq 0 ]] ; then
  themes=("${THEME_VARIANTS[0]}")
fi

if [[ "${#colors[@]}" -eq 0 ]] ; then
  colors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#lcolors[@]}" -eq 0 ]] ; then
  lcolors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#gcolors[@]}" -eq 0 ]] ; then
  gcolors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#sizes[@]}" -eq 0 ]] ; then
  sizes=("${SIZE_VARIANTS[0]}")
fi

sass_temp() {
  cp -rf ${SRC_DIR}/sass/gnome-shell/_common.scss ${SRC_DIR}/sass/gnome-shell/_common-temp.scss
  cp -rf ${SRC_DIR}/sass/_tweaks.scss ${SRC_DIR}/sass/_tweaks-temp.scss
}

compact_size() {
  sed -i "/\$compact:/s/false/true/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

nord_color() {
  sed -i "/\$color_type:/s/default/nord/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

blackness_color() {
  sed -i "/\$color_type:/s/default/blackness/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

darker_color() {
  sed -i "/\$darker:/s/false/true/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

border_rimless() {
  sed -i "/\$rimless:/s/false/true/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

normal_sidebar() {
  sed -i "/\$sidebar:/s/styled/normal/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

float_panel() {
  sed -i "/\$float:/s/false/true/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

colorful_panel() {
  sed -i "/\$colorful:/s/false/true/" ${SRC_DIR}/sass/_tweaks-temp.scss
}

gnome_shell_version() {
  sed -i "/\widgets/s/40-0/${GS_VERSION}/" ${SRC_DIR}/sass/gnome-shell/_common-temp.scss

  if [[ "${GS_VERSION}" == '3-28' || "${GS_VERSION}" == '46-0' ]]; then
    sed -i "/\extensions/s/40-0/${GS_VERSION}/" ${SRC_DIR}/sass/gnome-shell/_common-temp.scss
  fi
}

theme_color() {
  if [[ "$theme" != '' ]]; then
    case "$theme" in
      -purple)
        theme_color='purple'
        ;;
      -pink)
        theme_color='pink'
        ;;
      -red)
        theme_color='red'
        ;;
      -orange)
        theme_color='orange'
        ;;
      -yellow)
        theme_color='yellow'
        ;;
      -green)
        theme_color='green'
        ;;
      -teal)
        theme_color='teal'
        ;;
      -blue)
        theme_color='blue'
        ;;
    esac
    sed -i "/\$theme:/s/default/${theme_color}/" ${SRC_DIR}/sass/_tweaks-temp.scss
  fi
}

theme_tweaks() {
  cp -rf ${SRC_DIR}/sass/_tweaks.scss ${SRC_DIR}/sass/_tweaks-temp.scss

  if [[ "$accent" = "true" ]] ; then
    theme_color
  fi

  if [[ "$compact" = "true" ]] ; then
    compact_size
  fi

  if [[ "$nord" = "true" ]] ; then
    nord_color
  fi

  if [[ "$blackness" = "true" ]] ; then
    blackness_color
  fi

  if [[ "$darker" = "true" ]] ; then
    darker_color
  fi

  if [[ "$rimless" = "true" ]] ; then
    border_rimless
  fi

  if [[ "$normal" = "true" ]] ; then
    normal_sidebar
  fi

  if [[ "$float" = "true" ]] ; then
    float_panel
  fi

  if [[ "$colorful" = "true" ]] ; then
    colorful_panel
  fi
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0"/{assets,gtk.css,gtk-dark.css}
}

link_libadwaita() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local lcolor="${4}"
  local size="${5}"
  local ctype="${6}"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  mkdir -p                                                                      "${HOME}/.config/gtk-4.0"
  ln -sf "${THEME_DIR}/gtk-4.0/assets"                                          "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css"                                         "${HOME}/.config/gtk-4.0/gtk.css"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css"                                    "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

uninstall() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"
  local ctype="${6}"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  if [[ -d "${THEME_DIR}" ]]; then
    echo -e "Uninstall ${THEME_DIR}... "
    rm -rf "${THEME_DIR}"
    rm -rf "${THEME_DIR}"-hdpi
    rm -rf "${THEME_DIR}"-xhdpi
  fi

  if [[ -d "${THEME_DIR}"-hdpi ]]; then
    rm -rf "${THEME_DIR}"-hdpi
  fi

  if [[ -d "${THEME_DIR}"-xhdpi ]]; then
    rm -rf "${THEME_DIR}"-xhdpi
  fi
}

link_theme() {
  for theme in "${themes[0]}"; do
    for lcolor in "${lcolors[1]}"; do
      for size in "${sizes[0]}"; do
        link_libadwaita "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$lcolor" "$size" "$ctype"
      done
    done
  done
}

clean_theme() {
  for theme in "${THEME_VARIANTS[@]}"; do
    for color in '' '-light' '-dark'; do
      for size in "${SIZE_VARIANTS[@]}"; do
        for type in '' '-nord'; do
          clean "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$type"
        done
      done
    done
  done

  for theme in "${THEME_VARIANTS[@]}"; do
    for color in "${COLOR_VARIANTS[@]}"; do
      for size in "${SIZE_VARIANTS[@]}"; do
        for type in '' '-nord'; do
          uninstall "${dest:-$HOME/.themes}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$type"
        done
      done
    done
  done
}

uninstall_theme() {
  for theme in "${THEME_VARIANTS[@]}"; do
    for color in "${COLOR_VARIANTS[@]}"; do
      for size in "${SIZE_VARIANTS[@]}"; do
        for type in '' '-nord'; do
          uninstall "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$type"
        done
      done
    done
  done
}

install_theme() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        install "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$ctype"
      done
    done
  done
}

install_gdm_theme() {
  for theme in "${themes[0]}"; do
    for gcolor in "${gcolors[2]}"; do
      for size in "${sizes[0]}"; do
        install_gdm "${name:-$THEME_NAME}" "$theme" "$gcolor" "$size" "$ctype"
      done
    done
  done
}

if [[ "$uninstall" == 'true' ]]; then
  if [[ "$libadwaita" == 'true' ]]; then
    echo -e "\nUninstall ${HOME}/.config/gtk-4.0 links ..."
    uninstall_link
  elif [[ "$gdm" == 'true' ]]; then
    if [[ "$UID" -eq "$ROOT_UID" ]]; then
      echo -e "\nUninstall GDM theme ..."
      uninstall_gdm_theme
    else
      echo -e "\nNeed root permission !"
    fi
  else
    echo && uninstall_theme && uninstall_link
  fi
else
  if [[ "$gdm" == 'true' ]]; then
    if [[ "$UID" -eq "$ROOT_UID" ]]; then
      install_theme_deps && install_package && sass_temp && gnome_shell_version && install_gdm_theme
    else
      echo -e "\nNeed root permission !"
    fi
  else
    clean_theme && install_package && sass_temp && gnome_shell_version && install_theme

    if [[ "$libadwaita" == 'true' ]]; then
      uninstall_link && link_theme
    fi
  fi
fi

echo
echo Done.
