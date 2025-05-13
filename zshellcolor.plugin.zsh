
# zshellcolor — Zsh plugin to dynamically change terminal background color
# Author: Rival89 (Refactored)

: "${DEFAULT_SHELLCOLOR:=#000000}"
: "${SHELLCOLOR_DEBUG:=0}"

# Color name to hex map with improved handling of spaces
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

# Normalize input: remove whitespace, lowercase, and remove extra spaces
normalize_color_name() {
  echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | sed 's/ //g'
}

# Resolve color from name or hex with enhanced logic
lookup_color() {
  local input="$1"
  input=$(normalize_color_name "$input")

  # Check named color
  if [[ -n "${SHELLCOLOR_NAMES[$input]}" ]]; then
    echo "${SHELLCOLOR_NAMES[$input]}"
    return
  fi

  # Check for valid hex color
  if [[ "$input" =~ ^#([A-Fa-f0-9]{6})$ ]]; then
    echo "$input"
    return
  fi

  # Invalid color, return empty
  if [[ "$SHELLCOLOR_DEBUG" == 1 ]]; then
    echo "[zshellcolor] Invalid color name or hex: '$1'"
  fi
  echo ""
}

# Improved shellcolor command to handle errors better
shellcolor() {
  case "$1" in
    set)
      local input="$2$3"
      local norm=$(normalize_color_name "$input")
      local hex=$(lookup_color "$norm")

      if [[ -n "$hex" ]]; then
        echo "$norm" > .shellcolor
        echo "[zshellcolor] Set .shellcolor to: $norm → $hex"
      else
        echo "[zshellcolor] Error: Unknown color '$input'"
        echo "Available colors: ${(j:,:)${(k)SHELLCOLOR_NAMES[@]}}"
        return 1
      fi
      ;;
    *)
      echo "Usage: shellcolor set [color name or hex]"
      return
      ;;
  esac
  change_background
}
