![zshellcolor banner](https://github.com/Distantreach/zshellcolor/blob/main/zshellcolorbanner.png)

<b> # 🎨 zshellcolor </b>

A Zsh plugin to dynamically change your terminal background color based on context. Enhance your workflow with visual feedback for:
- Git branches
- Time of day
- Project-specific folders
- Command success/failure
- Predefined themes (Solarized, Dracula, etc.)
- Automatic cycling

---

## ⚡ Features
- **Directory-based background colors**  
  Automatically switch background color when changing directories.
- **Git Branch Awareness**  
  Display unique colors per Git branch.
- **Time-Based Coloring**  
  Morning, afternoon, evening, and night colors change with the clock.
- **Project-specific Themes**  
  Assign specific colors to project folders.
- **Color Cycling Mode**  
  Rotate through color palettes automatically.
- **Command Status Mode**  
  Background turns **green** or **red** based on command success or failure.
- **Predefined Themes**  
  Use `solarized-dark`, `solarized-light`, or `dracula` for instant theming.
- **Foreground Contrast Adjustment**  
  Ensures text remains readable against the background.

---

## 🚀 Installation

### Using Zinit
```zsh
zinit light Distantreach/zshellcolor
```

### Manual Installation
```sh
git clone https://github.com/Distantreach/zshellcolor ~/.zsh/zshellcolor
source ~/.zsh/zshellcolor/zshellcolor.plugin.zsh
```

---

## 🎛️ Usage

### 🌈 Set Background Color
```sh
shellcolor set random        # Set a random shell color
shellcolor set #RRGGBB       # Set a specific hex background color
shellcolor set red           # Set a named color
shellcolor set solarized-dark # Apply Solarized Dark theme
shellcolor set dracula       # Apply Dracula theme
```

### 🔄 Dynamic Modes
```sh
shellcolor set @git          # Set color based on Git branch
shellcolor set @time         # Set color based on time of day
shellcolor set @project      # Set color based on project folder
shellcolor set @cycle        # Automatically cycle through colors (PERIOD-based)
shellcolor set @status       # Change color based on command success (green) or failure (red)
```

### 🔍 Preview Mode
```sh
shellcolor preview #RRGGBB   # Preview a specific color
shellcolor preview teal      # Preview a named color
```

### 🧹 Cleanup and Refresh
```sh
shellcolor unset             # Remove .shellcolor
shellcolor gitignore         # Add .shellcolor to .gitignore
shellcolor refresh           # Manually refresh the background
```

---

## 🔧 Configuration

### 📁 Project-Specific Colors
To set a specific color for a project:
```sh
echo "#003366" > .shellcolor
```

### ⌚ Time-Based Colors
Automatically switch colors based on the time of day:
- **Morning (6 AM - 12 PM):** Soft Yellow (`#FFFAE3`)
- **Afternoon (12 PM - 6 PM):** Light Blue (`#D1F0FF`)
- **Evening (6 PM - 9 PM):** Pink (`#FFD1DC`)
- **Night (9 PM - 6 AM):** Dark Slate (`#1E1E2E`)

```sh
echo "@time" > .shellcolor
```

### 🌐 Git Branch Coloring
Unique background colors for each Git branch:
```sh
echo "@git" > .shellcolor
```

### 🔄 Color Cycling
Automatically change colors every minute:
```sh
echo "@cycle" > .shellcolor
```

### ✅ Status Mode
Background changes to **green** or **red** based on the last command's exit status:
```sh
echo "@status" > .shellcolor
```

---

## 🔍 Debugging
Enable verbose output:
```sh
export SHELLCOLOR_DEBUG=1
```

Check loaded colors and themes:
```sh
shellcolor_debug
```

---

## 🎨 Predefined Themes
| Theme            | Background | Foreground |
|-------------------|------------|------------|
| solarized-dark   | `#002B36` | `#839496`  |
| solarized-light  | `#FDF6E3` | `#586E75`  |
| dracula          | `#282A36` | `#F8F8F2`  |

To apply:
```sh
shellcolor set solarized-dark
```

---

## 💡 Tips
- If you use `@project`, the color persists for that folder.  
- `@git` overrides project color if you are in a Git repo.  
- `@time` is a global setting and overrides both project and Git-based colors.  
- `@cycle` will continuously rotate through colors if set.  
- `@status` is perfect for command-heavy work to instantly see success or failure.

---

## 📝 License
This project is licensed under the MIT License. See the [LICENSE](https://github.com/Distantreach/zshellcolor/blob/main/LICENSE) file for details.
