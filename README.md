# Toddler POV Camera Adjuster (FiveM)

A dynamic camera adjustment script for FiveM that automatically detects small/toddler character models and adjusts the camera perspective (First Person & Third Person) to match their height.

## 🌟 Features

- **Smart Height Detection**: Uses a combination of model dimensions and 3D bone distance (Head to Foot) to accurately identify toddler peds, even when running or performing animations.
- **Smooth POV Camera**: Custom First-Person camera attached to the head bone with a slight forward offset to prevent clipping inside the head.
- **Advanced Third-Person Smoothing**: Implements Z-axis interpolation (Lerp) to ensure the camera doesn't "flicker" or "jump" when walking over uneven terrain or stopping suddenly.
- **Anti-Flicker Logic**: "Sticky" detection prevents the camera from resetting during fast movement, ducking, or quick animation changes.
- **Collision Detection**: Built-in raycasting for the custom third-person camera to prevent it from clipping through walls and objects.
- **Optimized Performance**: Dynamic tick rates (low CPU usage when playing as a normal-sized character).

## 🚀 Installation

1. Download or clone this repository.
2. Place the `todlerview` folder into your server's `resources` directory.
3. Add `ensure todlerview` to your `server.cfg`.
4. Restart your server or start the resource in-game.

## 🛠️ Configuration

You can adjust the height threshold in `client.lua`:

```lua
local TODDLER_HEIGHT_THRESHOLD = 1.3 -- Characters below this height (in units) will trigger the toddler camera.
```

## 🎮 Usage

Simply switch to any small ped model (e.g., child or toddler peds). The script will automatically:
- Lower the **Third-Person** camera angle.
- Adjust the **First-Person** POV to be at the character's actual eye level.
- Sync your character's heading with the camera direction when moving.

## 📄 License

Created by **allan**. Free to use and modify for your community.
