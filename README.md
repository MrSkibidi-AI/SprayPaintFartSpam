# Fart_Spam

A Roblox Lua GUI script featuring configurable fart effects, timing tools, and character/camera utilities.

> **Status:** Private development repository  
> **Reviewed file:** `Fart_Spam_V2.9.1.lua`

## Features

- Single fart trigger and configurable repeat mode
- Adjustable delay and keyboard shortcuts
- Pattern recorder and pattern playback
- Customisable interface size, transparency, and themes
- Fart Orbit player interaction
- Ninja Teleport with Camera Lock and Freecam modes
- Face Fart player interaction
- Counters, settings, and cleanup controls

## Repository contents

| File | Description |
| --- | --- |
| `Fart_Spam_V2.9.1.lua` | Main Lua script |
| `README.md` | Project overview and notes |

## Important notes

- This project depends on game-specific Roblox objects, including `ReplicatedStorage.Remotes.Misc.Fart`. It may stop working if the game changes those objects.
- The script changes local character positioning and camera behaviour and sends requests to a game remote. It is not a normal Roblox Studio LocalScript.
- Using third-party scripts or repeatedly invoking game remotes may violate a game's rules or Roblox's terms and can result in moderation.
- Use only where you have permission. Do not use it to disrupt other players or game services.
- No compatibility or safety guarantee is provided. Review the source before running it.

## Security review

The uploaded `Fart_Spam_V2.9.1.lua` was statically checked before this repository draft was prepared.

The scan found no apparent external HTTP requests, webhook URLs, dynamic code loading, credential collection, or file-writing APIs. The script does call the game's `Fart` remote and modifies character/camera state as part of its features.

This is a static review, not a guarantee that the script is harmless in every environment. The review applies only to the exact uploaded file, not to other copies or versions.

## Version notes

The uploaded filename is `V2.9.1`, but the GUI title and some source comments still identify the script as `V2.8`. Confirm and update the displayed version before making a public release.

## Credits

- Project author
- Claude
- Qwen
- ChatGPT
- Mr. Skibidi

---

This project is independently maintained. Roblox and the game it targets are not affiliated with this repository.
