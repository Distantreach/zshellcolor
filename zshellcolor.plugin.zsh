# zshellcolor — Zsh plugin to dynamically change terminal background color (with foreground contrast)
# Author: Rival89
#
# Features:
#  - Recognizes .shellcolor files or directory-based mapping for project-specific colors
#  - Dynamic background color modes: @git (branch-based), @time (time-of-day), @project (directory name)
#  - Named colors (extended list including teal, navy, gold, cyan, magenta, etc.)
#  - Auto-adjusts text color (black or white) for readability based on background brightness
#  - Predefined themes (solarized-dark, solarized-light, dracula) set both background and foreground
#  - Cycle mode (@cycle) periodically changes background color (uses $PERIOD interval)
#  - Status mode (@status) shows last command status (green=success, red=failure) via precmd hook

# Default colors and settings
: "${DEFAULT_SHELLCOLOR:=#000000}"   # Fallback background color if none specified
: "${SHELLCOLOR_DEBUG:=0}"          # Debug mode (set to 1 for verbose logs)
: "${PERIOD:=60}"                   # Default cycle interval in seconds for @cycle mode (if not already set)

# Color name to hex map (expanded with additional common color names)
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
  teal        "#008080"
  navy        "#000080"
  gold        "#FFD700"
  cyan        "#00FFFF"
  magenta     "#FF00FF"
  aqua        "#00FFFF"
  fuchsia     "#FF00FF"
  maroon      "#800000"
  olive       "#808000"
  silver      "#C0C0C0"
  violet      "#EE82EE"
  indigo      "#4B0082"
  darkgreen   "#006400"
)

# Predefined color themes (background;foreground pairs)
typeset -A SHELLCOLOR_THEMES=(
  solarized-dark  "#002B36;#839496"
  solarized-light "#FDF6E3;#586E75"
  dracula         "#282A36;#F8F8F2"
)

# Normalize input by removing all whitespace and lowercasing
normalize_color_name() {
  echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

# Resolve a color value from name or hex (returns hex or empty string if invalid)
lookup_color() {
  local input="$1"
  # Remove whitespace (if any) from the input
  input="${input//[$'\t\r\n ']}"

  # If input is a valid 6-digit hex code (with leading #), return it
  if [[ "$input" == \#([A-Fa-f0-9])## && "${#input}" -eq 7 ]]; then
    echo "$input"
    return
  fi

  # Check if input matches a named color
  local key=$(normalize_color_name "$input")
  if [[ -n "${SHELLCOLOR_NAMES[$key]}" ]]; then
    echo "${SHELLCOLOR_NAMES[$key]}"
    return
  fi

  # Unrecognized color name or format
  echo ""
}

# Git branch → deterministic color (hash the branch name into a hex color)
git_branch_color() {
  local branch hash
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  hash=$(printf "%s" "$branch" | cksum | cut -d' ' -f1)
  printf "#%06x" $((hash % 0xFFFFFF))
}

# Time-of-day → color (morning/afternoon/evening/night themes)
time_based_color() {
  local hour=$(date +%H)
  if   (( hour >= 6 && hour < 12 )); then echo "#FFFAE3"    # Morning (soft yellow)
  elif (( hour >= 12 && hour < 18 )); then echo "#D1F0FF"   # Afternoon (light blue)
  elif (( hour >= 18 && hour < 21 )); then echo "#FFD1DC"   # Evening (pinkish)
  else echo "#1E1E2E"                                       # Night (dark)
  fi
}

# Folder-specific color mappings (project directories)
project_based_color() {
  local dir=$(basename "$(pwd)")
  case "$dir" in
    reconftw) echo "#8B0000" ;;  # Dark red
    Tools)    echo "#003366" ;;  # Navy blue
    Git)      echo "#228B22" ;;  # Forest green
    *)        echo "$DEFAULT_SHELLCOLOR" ;;  # Fallback to default if no match
  esac
}

# Last command exit status → color (green for success, red for failure)
status_color() {
  if (( $? == 0 )); then
    echo "#00FF00"
  else
    echo "#FF0000"
  fi
}

# Find the nearest .shellcolor file in current or parent directories
find_nearest_shellcolor() {
  local dir="$(pwd)"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.shellcolor" ]]; then
      # Read first line of .shellcolor (trim whitespace and newline)
      head -n1 "$dir/.shellcolor" | tr -d '\r\n\t '
      return
    fi
    dir="$(dirname "$dir")"
  done
  # No .shellcolor file found; use the default color
  echo "$DEFAULT_SHELLCOLOR"
}

# Determine the final color (or theme) to apply based on .shellcolor content
resolve_color() {
  local raw="$(find_nearest_shellcolor 2>/dev/null)"
  local norm="$(normalize_color_name "$raw")"
  case "$norm" in
    @git)     git_branch_color ;;
    @time)    time_based_color ;;
    @project) project_based_color ;;
    @cycle)   cycle_color ;;
    @status)  status_color ;;
    *)
      # Check for predefined theme names
      if [[ -n "${SHELLCOLOR_THEMES[$norm]}" ]]; then
        echo "${SHELLCOLOR_THEMES[$norm]}"
      else
        # Fallback to standard color lookup
        lookup_color "$raw"
      fi
      ;;
  esac
}

# Apply background (and appropriate foreground) color to the terminal
apply_color() {
  local color="$1"
  # Theme: color string contains "bg;fg" pair
  if [[ "$color" == *";"* ]]; then
    local bg="${color%%;*}"
    local fg="${color#*;}"
    # Apply background and foreground from theme (if valid)
    if [[ "$bg" == \#([A-Fa-f0-9])## && "${#bg}" -eq 7 ]]; then
      printf '\033]11;%s\007' "$bg"
    else
      [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Invalid theme background: '$bg'"
    fi
    if [[ "$fg" == \#([A-Fa-f0-9])## && "${#fg}" -eq 7 ]]; then
      printf '\033]10;%s\007' "$fg"
    else
      [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Invalid theme foreground: '$fg'"
    fi
    return
  fi

  # Single color (not a theme)
  if [[ "$color" == \#([A-Fa-f0-9])## && "${#color}" -eq 7 ]]; then
    # Valid hex color – set as background
    printf '\033]11;%s\007' "$color"
    # Compute and apply contrasting foreground (text) color
    local fg="$(contrast_color "$color")"
    [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Chose contrast text color: $fg for background $color"
    printf '\033]10;%s\007' "$fg"
  else
    # Invalid color input – log and fall back to default
    [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Invalid color, skipping: '$color'"
    if [[ -n "$DEFAULT_SHELLCOLOR" ]]; then
      local defhex="$(lookup_color "$DEFAULT_SHELLCOLOR")"
      if [[ -n "$defhex" ]]; then
        [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Fallback to default color: $defhex"
        printf '\033]11;%s\007' "$defhex"
        local fg="$(contrast_color "$defhex")"
        [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Chose contrast text color: $fg for background $defhex"
        printf '\033]10;%s\007' "$fg"
      fi
    fi
  fi
}

# Calculate an appropriate foreground (text) color for a given background (black or white for contrast)
contrast_color() {
  local hex="${1#\#}"  # strip leading '#' if present
  # If not a 6-digit hex code, default to white
  if (( ${#hex} != 6 )); then
    echo "#FFFFFF"
    return
  fi
  # Split hex into RGB components
  local r_hex="${hex:0:2}"
  local g_hex="${hex:2:2}"
  local b_hex="${hex:4:2}"
  # Convert hex components to decimal
  local r=$((16#$r_hex))
  local g=$((16#$g_hex))
  local b=$((16#$b_hex))
  # Compute luminance-weighted brightness (YIQ formula scaled by 1000)
  local brightness=$(( r*299 + g*587 + b*114 ))
  if (( brightness > 186000 )); then
    echo "#000000"  # bright background -> black text
  else
    echo "#FFFFFF"  # dark background -> white text
  fi
}

# Change the terminal background (and text color) to the resolved color
change_background() {
  local color="$(resolve_color)"
  [[ "$SHELLCOLOR_DEBUG" == 1 ]] && {
    if [[ "$color" == *";"* ]]; then
      # If theme, log both components
      echo "[zshellcolor] Applying theme: BG=${color%%;*}, FG=${color#*;}"
    else
      echo "[zshellcolor] Applying: $color"
    fi
  }
  apply_color "$color"
}

# Generate a random low-saturation color (pastel-like)
generate_color() {
  # Seed RANDOM from /dev/urandom for better randomness
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

# Cycle to the next color (for @cycle mode). Uses generate_color for a random color.
cycle_color() {
  local newcolor="$(generate_color)"
  if [[ -n "$SHELLCOLOR_LAST" && "$newcolor" == "$SHELLCOLOR_LAST" ]]; then
    # Ensure we don't repeat the previous color (try once more)
    newcolor="$(generate_color)"
  fi
  SHELLCOLOR_LAST="$newcolor"
  echo "$newcolor"
}

# Command-line interface for the shellcolor plugin
shellcolor() {
  case "$1" in
    set)
      local input="$2$3"
      local norm="$(normalize_color_name "$input")"

      if [[ "$norm" == "random" ]]; then
        # Set to a new random color
        local color="$(generate_color)"
        echo "$color" > .shellcolor
        echo "[zshellcolor] Set .shellcolor to random: $color"

      elif [[ "$norm" == @git || "$norm" == @time || "$norm" == @project || "$norm" == @cycle || "$norm" == @status ]]; then
        # Preset dynamic mode (@git, @time, @project, @cycle, @status)
        echo "$norm" > .shellcolor
        echo "[zshellcolor] Set .shellcolor to preset: $norm"

      elif [[ -n "${SHELLCOLOR_THEMES[$norm]}" ]]; then
        # Predefined theme name
        echo "$norm" > .shellcolor
        echo "[zshellcolor] Set .shellcolor to theme: $norm"

      else
        # Interpret input as a color name or hex code
        local hex="$(lookup_color "$norm")"
        if [[ -n "$hex" ]]; then
          echo "$norm" > .shellcolor
          echo "[zshellcolor] Set .shellcolor to: $norm → $hex"
        else
          echo "Unknown color: '$input'"
          echo "Try: shellcolor set red, light blue, teal, or #1a2b3c"
          return 1
        fi
      fi
      ;;
    preview)
      # Temporarily apply a color (does not persist .shellcolor)
      local input="$2$3"
      local hex="$(lookup_color "$input")"
      if [[ -n "$hex" ]]; then
        echo "[zshellcolor] Previewing: $hex"
        apply_color "$hex"
      else
        echo "Unknown color: '$input'"
        return 1
      fi
      ;;
    unset)
      # Remove .shellcolor to revert to default
      rm -f .shellcolor && echo "[zshellcolor] Removed .shellcolor"
      ;;
    gitignore)
      # Ignore .shellcolor in Git (adds to .gitignore)
      echo ".shellcolor" >> .gitignore && echo "[zshellcolor] Added .shellcolor to .gitignore"
      ;;
    refresh|reshim)
      # Manually re-apply the background color (e.g., after changing .shellcolor)
      echo "[zshellcolor] Refreshing background..."
      change_background
      ;;
    help|-h|--help|*)
      # Show usage information
      cat <<EOF
Usage:
  shellcolor set [random|#RRGGBB|<color-name>|<theme-name>|@git|@time|@project|@cycle|@status]
  shellcolor preview [color]
  shellcolor unset
  shellcolor gitignore
  shellcolor refresh
EOF
      return
      ;;
  esac

  # After handling the command, apply the (new) background
  change_background
}

# Hook function: run before each prompt to handle @status mode
shellcolor_precmd() {
  local last_status=$?                                  # capture the last command's exit status
  local raw="$(find_nearest_shellcolor 2>/dev/null)"
  if [[ "$raw" == "@status" ]]; then
    # Determine color based on exit status
    local color
    if (( last_status == 0 )); then
      color="#00FF00"    # success -> green
    else
      color="#FF0000"    # failure -> red
    fi
    [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Status mode: exit=$last_status → $color"
    apply_color "$color"
  fi
}

# Hook function: run periodically (every $PERIOD seconds) to handle @cycle mode
shellcolor_periodic() {
  local raw="$(find_nearest_shellcolor 2>/dev/null)"
  if [[ "$raw" == "@cycle" ]]; then
    [[ "$SHELLCOLOR_DEBUG" == 1 ]] && echo "[zshellcolor] Cycle tick"
    change_background   # cycle to the next color
  fi
}

# Activate hooks
autoload -Uz add-zsh-hook
add-zsh-hook chpwd change_background         # Directory change -> update background
add-zsh-hook precmd shellcolor_precmd        # Before prompt -> handle @status mode
add-zsh-hook periodic shellcolor_periodic    # Periodic timer -> handle @cycle mode

# Initial application of background color on plugin load
change_background
