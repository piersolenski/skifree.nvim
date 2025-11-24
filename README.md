# 🎿 SkiFree.nvim

A Neovim plugin inspired by the classic Windows 3.1 game [SkiFree](https://en.wikipedia.org/wiki/SkiFree)!

https://github.com/user-attachments/assets/6d7102a5-04c3-4cd9-99bb-3755ed3f2d7f

## 📦 Installation

### Using lazy.nvim

```lua
{
  'piersolenski/skifree.nvim',
  cmd = 'SkiFree',
}
```

### Using packer.nvim

```lua
use("piersolenski/skifree.nvim")
```

## 🎮 Usage

```vim
:SkiFree
```

## ⌨️ Controls

| Key | Action |
|-----|--------|
| `←` or `h` | Move left |
| `→` or `l` | Move right |
| `↓` or `j` | Slow down |
| `↑` or `k` | Speed up |
| `p` | Pause |
| `r` | Restart (after game over) |
| `q` | Quit |

## 🎯 Gameplay

- Ski down the mountain avoiding obstacles
- 🌲 Trees and 🪨 rocks will fuck you up
- After 2000m, the 👹 yeti appears
- Try to ski as far as possible
