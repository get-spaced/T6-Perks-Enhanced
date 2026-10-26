# T6 Perks Remastered

A Black Ops II Zombies mod for **Plutonium T6** that enhances existing perks with new abilities, improved effects, and quality-of-life features while preserving the original Zombies experience.

## Overview

**T6 Perks Remastered** expands the functionality of classic and DLC perks, giving players additional benefits and making previously overlooked perks more useful.

The goal is to modernize the original perk system without completely changing how Black Ops II Zombies plays.

## Perk Enhancements

### Speed Cola
*Improved weapon handling*

In addition to its original faster reload speed, Speed Cola now provides:

- Faster weapon switching.
- Faster aim-down-sights (ADS) transitions.
- Faster grenade throwing.

All additional effects are removed when Speed Cola is lost.

### Stamin-Up
*Improved mobility and survivability*

- Grants unlimited sprint while the perk is active.
- Optionally provides immunity to lava damage.
- Restores normal sprint behavior when the perk is lost.

Lava immunity can be enabled or disabled through a server DVAR.

### Mule Kick
*Improved third-weapon management*

- Adds a custom HUD indicator for the player's third weapon.
- Highlights the indicator when the third weapon is equipped.
- Automatically hides the indicator when the weapon is unequipped, the player is downed, or Mule Kick is lost.
- Supports customizable HUD positioning.

Also integrates with the modified Tombstone perk to support third-weapon restoration.

### PhD Flopper
*Enhanced explosive capabilities*

- Throwing a supported grenade with PhD Flopper generates five additional grenades.
- Supports Frag and Semtex grenades.
- Additional grenades receive randomized positions, velocities, and fuse times.
- Includes safeguards intended to prevent repeated grenade multiplication when grenades are thrown back.

This gives PhD Flopper an additional offensive ability beyond its original explosive protection.

### Deadshot Daiquiri
*Improved precision damage*

Deadshot now provides additional headshot damage:

- **Sniper rifles:** 2× headshot damage multiplier.
- **Other supported weapons:** 1.5× headshot damage multiplier.

The additional damage applies while Deadshot Daiquiri is active.

### Tombstone Soda
*Reworked perk recovery*

Tombstone provides an alternative perk recovery mechanic when the player is revived.

- Saves the player's owned perks when entering last stand.
- Restores approximately half of the saved perks after a successful revive.
- Randomly selects which perks are restored.
- Supports restoration of the player's third weapon, including its ammunition, when Mule Kick is restored.
- Clears saved recovery data when the player is not successfully revived.

This replaces the traditional tombstone pickup mechanic with an immediate revive-based recovery system.

### Vulture Aid
*Improved perk-machine awareness*

- Adds optional waypoint indicators for supported perk machines.
- Displays perk-specific icons to help identify machines.
- Shows waypoints based on the player's distance from each machine.
- Automatically hides waypoints when they are outside the configured visibility range.
- Removes the custom waypoints when Vulture Aid is lost.

The waypoint system can be enabled or disabled through a server DVAR.

## Additional Features

- Increased perk purchase limit.
- Optional automatic bank refilling on supported maps.
- Per-player perk monitoring and state management.
- Customizable HUD positioning.
- Server-configurable features.
- Automatic removal of supported bonus effects when their associated perk is lost.
- Map-specific functionality where applicable.

## Configuration

Several features can be controlled using server DVARs.

| DVAR | Default | Description |
|---|---|---|
| `stam_ignores_lava` | `0` | Enables lava immunity while Stamin-Up is active |
| `refill_player_banks` | `1` | Automatically refills supported player banks |
| `use_perk_waypoints` | `1` | Enables Vulture Aid perk-machine waypoints |

**Values:** `0` = Disabled, `1` = Enabled.

The Mule Kick HUD position can also be customized in GSC:

```c
level.mule_icon_x = -255;
level.mule_icon_y = -46;
```

## Installation

1. Install and configure Plutonium T6.
2. Add the mod's GSC file to the appropriate T6 Zombies scripts directory.
3. Make sure the script is loaded by your Zombies mod or server configuration.
4. Launch a supported Zombies map.

**Note:** Installation may differ depending on whether you're using a dedicated server, a local mod setup, or compiled GSC files.

## Compatibility

- **Game:** Call of Duty: Black Ops II
- **Platform:** Plutonium T6
- **Mode:** Zombies
- **Language:** GSC

Perk availability depends on the selected map and game mode.

Other modifications that replace the same Zombies functions may conflict with this mod. Some functionality requires further in-game testing, particularly custom Vulture Aid behavior and grenade throwback handling.

## Development

T6 Perks Remastered is focused on improving existing Zombies mechanics while maintaining the recognizable Black Ops II experience.

Future updates may include additional perk abilities, compatibility improvements, balancing adjustments, and more configuration options.

## Disclaimer

This is an unofficial community modification for Call of Duty: Black Ops II Zombies and is not affiliated with or endorsed by Activision, Treyarch, or Plutonium.
