# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
make check     # Run both format and lint
make format    # Format code with stylua
make lint      # Lint with luacheck
```

## Architecture

This is a Neovim plugin that recreates the classic SkiFree game. The plugin is invoked via the `:SkiFree` command.

### Module Structure

- `plugin/skifree.lua` - Registers the `:SkiFree` user command
- `lua/skifree/init.lua` - Main entry point, orchestrates game initialization and cleanup
- `lua/skifree/game.lua` - Core game logic: state management, update loop (12 FPS), collision detection, entity spawning
- `lua/skifree/renderer.lua` - Neovim buffer/window management and rendering
- `lua/skifree/input.lua` - Keyboard input handling and keybindings
- `lua/skifree/entities.lua` - Entity definitions

### Game Loop

The game runs on a `vim.uv` timer at ~12 FPS (80ms frame time). The main loop in `game.lua`:
1. Updates game state (scrolling, obstacle movement, yeti AI, collision checks)
2. Renders to a floating window buffer

### Key Game Mechanics

- Player always moves downward; speed controlled by j/k keys (slow/medium/fast)
- Obstacles (trees, rocks) and other skiers scroll upward toward player
- Yeti spawns at 2000m distance and actively chases player
- Collision uses simple distance-based detection (dx < 2, dy < 1)

### Emoji Rendering

Game uses emoji sprites (🌲, 🪨, ⛷️, 👹, etc.) which take 2 terminal cells, handled by setting adjacent cell to empty string.
