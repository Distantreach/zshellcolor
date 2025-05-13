# 🎨 zshellcolor

A Zsh plugin to dynamically change your terminal background color based on the current directory. Customize your workspace visually with random colors, git-branch-based colors, or predefined colors for specific projects.

---

## ⚡ Features

- Changes terminal background color on `cd` to directories
- Supports:
  - Random colors
  - Git branch-based colors
  - Time-based colors
  - Project-specific colors
- CLI commands for managing colors
- Debug mode for troubleshooting

---

## 🚀 Installation

### Using Zinit

```zsh
zinit light username/zshellcolor


## Manual Installation
# Clone and Source the plugin manually

git clone https://github.com/username/zshellcolor ~/.zsh/zshellcolor
source ~/.zsh/zshellcolor/zshellcolor.plugin.zsh

## 🎛️ Usage

shellcolor set random        # Set a random shell color
shellcolor set #RRGGBB       # Set a specific hex background color
shellcolor set red           # Set a named color
shellcolor set @git          # Set color based on git branch
shellcolor set @time         # Set color based on time of day
shellcolor set @project      # Set color based on project folder
shellcolor preview #RRGGBB   # Preview a specific color
shellcolor unset             # Remove .shellcolor
shellcolor gitignore         # Add .shellcolor to .gitignore
shellcolor refresh           # Manually refresh the background

## Enable Debugging
## To enable verbose output:

export SHELLCOLOR_DEBUG=1

## 🔧 Configuration
## Create a .shellcolor file in your project directory to set a specific color. For dynamic colors, use:

@git - Branch-based color

@time - Time-of-day based color

@project - Directory-specific color

## Example

echo "@git" > .shellcolor


📝 License
This project is licensed under the MIT License. See the LICENSE file for details.
