# Item Transporter Range Mod

A mod for **Abiotic Factor** that increases the range of Item Transporters.

## 📋 Description

This mod automatically modifies the range of Item Transporters in Abiotic Factor, allowing you to collect items from much greater distances. The mod runs automatically when the game loads and provides both chat and console commands for configuration.

**Current Version:** 2.3

## ⚙️ Features

- **Automatic Range Modification**: Automatically increases Item Transporter range when transporters are placed or when the game loads
- **Configurable Range**: Set custom range values via chat or console commands
- **Real-time Monitoring**: Track how many transporters have been modified
- **Chat Commands**: Easy-to-use in-game chat commands with `/tr` prefix
- **Console Commands**: Advanced configuration via console
- **Visual Feedback**: In-game notifications for all actions
- **Reset Functionality**: Reset all modifications and reprocess transporters

## 🎮 Default Configuration

- **Default Game Range**: 1600 units
- **Mod Default Range**: 5000 units (~3x default)
- **Recommended Values**:
  - `3200` = 2x default
  - `5000` = ~3x default
  - `8000` = 5x default
  - `16000` = 10x default

## 🎯 Chat Commands

Use `/tr` or `/transporter` followed by:

| Command | Description |
|---------|-------------|
| `/tr` or `/tr help` | Show available commands |
| `/tr status` | Display current range and statistics |
| `/tr reset` | Reset all modifications and reprocess transporters |
| `/tr range <value>` | Set new range value (e.g., `/tr range 8000`) |

### Chat Command Examples
```
/tr status
/tr range 8000
/tr reset
```

## 🖥️ Console Commands

Open the console and use:

| Command | Description |
|---------|-------------|
| `transporter.help` | Show all available commands |
| `transporter.status` | Display detailed status information |
| `transporter.reset` | Reset modifications and reprocess |
| `transporter.range <value>` | Set new range (e.g., `transporter.range 8000`) |
| `transporter.range` | Show current range without arguments |

### Console Command Examples
```
transporter.status
transporter.range 10000
transporter.reset
```

## 📦 Installation

1. Ensure you have **UE4SS** installed for Abiotic Factor
2. Copy the `ItemTransporterRange` folder to your mods directory:
   ```
   AbioticFactor\Binaries\Win64\ue4ss\Mods\
   ```
3. The complete path should be:
   ```
   AbioticFactor\Binaries\Win64\ue4ss\Mods\ItemTransporterRange\
   ```
4. Launch the game - the mod will activate automatically

## 📁 File Structure

```
ItemTransporterRange/
├── enabled.txt                  # Automatically enables the mod
├── scripts/
│   ├── main.lua                 # Main mod file
│   └── AFUtils/                 # Utility framework
│       ├── AFUtils.lua         # Core utilities
│       ├── AFBase.lua          # Base functions
│       ├── Enums.lua           # Game enumerations
│       ├── StaticClasses.lua   # Static class references
│       ├── DefaultObjects.lua  # Default object definitions
│       ├── ObjectsGetter.lua   # Object retrieval functions
│       └── BaseUtils/          # Additional utilities
│           ├── BaseUtils.lua
│           ├── DefaultObjects.lua
│           ├── FNames.lua
│           ├── LinearColors.lua
│           ├── MathUtils.lua
│           ├── StaticClasses.lua
│           └── prepare_release.py
```

## 🔧 Configuration

### Manual Configuration
Edit the `NEW_RADIUS` value in `scripts/main.lua`:
```lua
local NEW_RADIUS = 5000.0  -- Adjust this value (in Unreal units)
```

### Runtime Configuration
Use chat or console commands to change the range without restarting the game.

## 🚀 How It Works

1. **Automatic Detection**: The mod hooks into the game's component activation system
2. **Range Modification**: When an Item Transporter is detected, its sphere radius is modified
3. **Tracking**: Each modified transporter is tracked to prevent duplicate modifications
4. **Persistence**: Settings persist during the game session (reset on game restart unless manually configured)

## 🐛 Troubleshooting

### Common Issues

**Transporters not being modified:**
- Use `/tr reset` to reprocess all transporters
- Check `/tr status` to see current statistics
- Ensure transporters are fully placed/activated

**Commands not working:**
- Make sure to use the exact command syntax
- Chat commands require `/tr` or `/transporter` prefix
- Console commands require `transporter.` prefix

**Mod not loading:**
- Verify UE4SS is properly installed
- Check that the mod folder is in the correct location
- Ensure `main.lua` is in the `scripts` folder

### Debug Information
The mod logs detailed information to the console. Check the game's console output for:
- Mod initialization messages
- Transporter modification confirmations
- Error messages

## 📊 Technical Details

- **Framework**: Built using UE4SS for Unreal Engine 4 games
- **Language**: Lua scripting
- **Dependencies**: AFUtils framework (included)
- **Compatibility**: Abiotic Factor (tested with current version)
- **Performance**: Minimal impact - only processes transporters when placed

## 🔄 Version History

### Version 2.3
- Current stable version
- Full chat and console command support
- Automatic transporter detection and modification
- Real-time configuration changes
- Enhanced error handling and user feedback

## 🤝 Contributing

This mod uses the AFUtils framework for Abiotic Factor modding. When making modifications:

1. Test thoroughly in single-player before multiplayer use
2. Follow Lua best practices
3. Maintain compatibility with the AFUtils framework
4. Document any new features or changes

## ⚠️ Disclaimer

- This mod modifies game behavior and may affect gameplay balance
- Use at your own discretion
- Always backup your save files before using mods
- The mod may need updates when the game is updated

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Use `/tr status` and `transporter.status` to gather information
3. Check console output for error messages
4. Try `/tr reset` to resolve common issues

---
