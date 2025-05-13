# zshellcolor — Zsh plugin to dynamically change terminal background color
# Author: Rival89

: "${DEFAULT_SHELLCOLOR:=#000000}"
: "${SHELLCOLOR_DEBUG:=0}"

# Color name to hex map
typeset -A SHELLCOLOR_NAMES=(
  red         "#FF0000"
  green       "#00FF00"
  blue        "#0000FF"
  lightblue   "#ADD8E6"
  darkblue    "#00008B"
  yellow      "#FFFF00"
  orange      "#FFA500"
  purple      "#800080"
  pink        "#FFC0CB"
  black       "#000000"
  white       "#FFFFFF"
  gray        "#808080"
  lightgray   "#D3D3D3"
  darkgray    "#404040"
  brown       "#8B4513"
)

# Normalize input (remove whitespace, lowercase)
normalize_color_name() {
  echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

# Resolve color from name or hex
lookup_color() {
  local input="$1"
  input="${input//[$'\t\r\n ']}"

  # Validate hex
  if [[ "$input" == \#([A-Fa-f0-9])## && "${#input}" -eq 7 ]]; then
    echo "$input"
    return
  fi

  # Check named color
  local key=$(normalize_color_name "$input")
  if [[ -n "${SHELLCOLOR_NAMES[$key]}" ]]; then
    echo "${SHELLCOLOR_NAMES[$key]}"
    return
  fi

  # Invalid
  echo ""
}

# Git branch → color hash
git_branch_color() {
  local branch hash
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  hash=$(printf "%s" "$branch" | cksum | cut -d' ' -f1)
  printf "#%06x" $((hash % 0xFFFFFF))
}

# Time-of-day → color
time_based_color() {
  local hour=$(date +%H)
  if   (( hour >= 6 && hour < 12 )); then echo "#FFFAE3"
  elif (( hour >= 12 && hour < 18 )); then echo "#D1F0FF"
  elif (( hour >= 18 && hour < 21 )); then echo "#FFD1DC"
  else echo "#1E1E2E"
  fi
}

# Folder-specific color mappings
project_based_color() {
  local dir=$(basename "$(pwd)")
  case "$dir" in
    reconftw) echo "#8B0000" ;;
    Tools)    echo "#003366" ;;
    Git)      echo "#228B22" ;;
    *)        echo "$DEFAULT_SHELLCOLOR" ;;
  esac
}

# Find nearest .shellcolor file
find_nearest_shellcolor() {
  local dir=$(pwd)
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.shellcolor" ]]; then
      head -n1 "$dir/.shellcolor" | tr -d '\r\n\t '
      return
    fi
    dir=$(dirname "$dir")
  done
  echo "$DEFAULT_SHELLCOLOR"
}

# Determine final color to apply
resolve_color() {
  local raw=$(find_nearest_shellcolor 2>/dev/null)
  case "$raw" in
    @git)     git_branch_color ;;
    @time)    time_based_color ;;
    @project) project_based_color ;;
    *)        lookup_color "$raw" ;;
  esac
}

# Actually apply the background color
apply_color() {
  local color="$1"
  if [[ "$color" == \#([A-Fa-f0-9])## && "${#color}" -eq 7 ]]; then
    printf '\033]11;%s\007' "$color"
  elif [[ "$SHELLCOLOR_DEBUG" == 1 ]]; then
    echo "[zshellcolor] Invalid color, skipping: '$color'"
  fi
}

# Master function to apply on dir change
change_background() {
  local color=$(resolve_color)
  [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Applying: $color"
  apply_color "$color"
}

# Generate low-saturation color
generate_color() {
  RANDOM=$(( $(od -An -N2 -tu2 </dev/urandom) ))
  local base=$((RANDOM % 150))
  local r=$(( base + RANDOM % 50 - 25 ))
  local g=$(( base + RANDOM % 50 - 25 ))
  local b=$(( base + RANDOM % 50 - 25 ))
  (( r < 0 )) && r=0; (( r > 255 )) && r=255
  (( g < 0 )) && g=0; (( g > 255 )) && g=255
  (( b < 0 )) && b=0; (( b > 255 )) && b=255
  printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# CLI interface
shellcolor() {
  case "$1" in
    set)
      local input="$2$3"
      local norm=$(normalize_color_name "$input")

      if [[ "$norm" == "random" ]]; then
        local color=$(generate_color)
        echo "$color" > .shellcolor
        echo "[zshellcolor] Set .shellcolor to random: $color"

      elif [[ "$norm" == @git || "$norm" == @time || "$norm" == @project ]]; then
        echo "$norm" > .shellcolor
        echo "[zshellcolor] Set .shellcolor to preset: $norm"

      else
        local hex=$(lookup_color "$norm")
        if [[ -n "$hex" ]]; then
          echo "$norm" > .shellcolor
          echo "[zshellcolor] Set .shellcolor to: $norm → $hex"
        else
          echo "Unknown color: '$input'"
          echo "Try: shellcolor set red, light blue, or #1a2b3c"
          return 1
        fi
      fi
      ;;
    preview)
      local input="$2$3"
      local hex=$(lookup_color "$input")
      if [[ -n "$hex" ]]; then
        echo "[zshellcolor] Previewing: $hex"
        apply_color "$hex"
      else
        echo "Unknown color: '$input'"
        return 1
      fi
      ;;
    unset)
      rm -f .shellcolor && echo "[zshellcolor] Removed .shellcolor"
      ;;
    gitignore)
      echo ".shellcolor" >> .gitignore && echo "[zshellcolor] Added to .gitignore"
      ;;
    refresh|reshim)
      echo "[zshellcolor] Refreshing background..."
      change_background
      ;;
    help|-h|--help|*)
      cat <<EOF
Usage:
  shellcolor set [random|#RRGGBB|<named>|@git|@time|@project]
  shellcolor preview [color]
  shellcolor unset
  shellcolor gitignore
  shellcolor refresh
EOF
      return
      ;;
  esac

  change_background
}

# Hook on directory change
autoload -Uz add-zsh-hook
add-zsh-hook chpwd change_background

# Initial run
change_background

