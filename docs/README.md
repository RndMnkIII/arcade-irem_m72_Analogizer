![Irem M92](./irem_m72-logo.png)

[![Active Development](https://img.shields.io/badge/Maintenance%20Level-Actively%20Developed-brightgreen.svg)](#status-of-features)
[![Build](https://github.com/opengateware/arcade-irem_m72/actions/workflows/build.yml/badge.svg)](https://github.com/opengateware/arcade-irem_m72/actions/workflows/build.yml)
[![release](https://img.shields.io/github/release/opengateware/arcade-irem_m72.svg)](https://github.com/opengateware/arcade-irem_m72/releases)
[![license](https://img.shields.io/github/license/opengateware/arcade-irem_m72.svg?label=License&color=yellow)](#legal-notices)
[![issues](https://img.shields.io/github/issues/opengateware/arcade-irem_m72.svg?label=Issues&color=red)](https://github.com/opengateware/arcade-irem_m72/issues)
[![stars](https://img.shields.io/github/stars/opengateware/arcade-irem_m72.svg?label=Project%20Stars)](https://github.com/opengateware/arcade-irem_m72/stargazers)
[![discord](https://img.shields.io/discord/676418475635507210.svg?logo=discord&logoColor=white&label=Discord&color=5865F2)](https://chat.raetro.org)
[![Twitter Follow](https://img.shields.io/twitter/follow/marcusjordan?style=social)](https://twitter.com/marcusjordan)

# Irem M72 Compatible Gateware IP Core

> This Implementation of a compatible Irem M72 arcade hardware in HDL is the work of [Martin Donlon].

## Overview

Launched by Irem in 1987, the M72 was a 16-bit arcade system that pioneered the company's arcade hardware development and set new standards for side-scrolling action games.

The M72 hardware system was notable for introducing Irem's arcade technology advancements, featuring impressive sprite handling and scrolling capabilities that delivered smooth gameplay experiences. It debuted with R-Type, which became one of Irem's most celebrated titles and established the company as a major player in the arcade shooting genre. The platform supported a diverse range of games that showcased its capabilities, from horizontal shooters to action platformers.

Notable Games:

- R-Type: Iconic horizontal-scrolling shoot 'em up featuring the innovative "Force" device that revolutionized shooter gameplay mechanics.
- X-Multiply: Horizontal shooter where players control a microscopic ship injected into a human body to battle alien parasites.
- Ninja Spirit: Side-scrolling action game featuring a ninja who can create shadow clones to fight alongside him.
- Dragon Breed: Horizontal shooter where the player controls a warrior riding a dragon whose tail serves as both a shield and weapon.
- Hammerin' Harry: Side-scrolling action platformer featuring a construction worker battling enemies with his trusty hammer.
- Air Duel: Vertical-scrolling shooter with selectable fighter jet or helicopter that switches between air and ground enemies.
- Image Fight: Vertical shooter with detailed mechanical designs and challenging gameplay.
- Legend of Hero Tonma: Platformer featuring a young wizard battling through various fantasy environments.

## Technical specifications

- **Main CPU:** NEC V30 @ 8 MHz
- **Sound CPU:** Zilog Z80 @ 3.579545 MHz
- **Sound Chip:** Yamaha YM2151 @ 3.579545 MHz
- **Sound Chip:** Custom DAC for PCM samples
- **Resolution:** 384×256 @ 55.01 Hz
- **Colors:** 512 colors on screen
- **Orientation:** Horizontal/Vertical
- **Players:** Up to 2 players (solo or alternating)
- **Control:** 8-way joystick
- **Buttons:** 2

## Compatible Platforms

- Analogue Pocket

## Compatible Games

> **Notice Regarding ROMs:** This repository does not contain any ROMs or game files, nor will any links or pre-assembled ROMs be provided by OpenGateware in any form. Users must ensure they have the legal authority to use these titles in their jurisdiction. By using this core, you agree to supply your own ROMs. We do not condone or support the unauthorized use or distribution of copyrighted or any other intellectual property-protected materials.

| **Game**                                         | Status |
| :----------------------------------------------- | :----: |
| Air Duel (Japan, M72 hardware)                   |   ✅   |
| Air Duel (World, M72 hardware)                   |   ✅   |
| Daiku no Gensan (Japan, M84 hardware)            |   ✅   |
| Dragon Breed (Japan, M72 hardware)               |   ✅   |
| Gallop - Armed Police Unit (Japan, M72 hardware) |   ✅   |
| Hammerin' Harry (US, M84 hardware)               |   ✅   |
| Image Fight (Japan)                              |   ✅   |
| Image Fight (World)                              |   ✅   |
| Legend of Hero Tonma (Japan)                     |   ✅   |
| Mr. HELI no Daibouken (Japan)                    |   ✅   |
| Ninja Spirit (Japan)                             |   ✅   |
| R-Type (Japan)                                   |   ✅   |
| R-Type (World)                                   |   ✅   |
| R-Type II (Japan)                                |   ✅   |
| R-Type II (World)                                |   ✅   |
| X Multiply (Japan, M72 hardware)                 |   ✅   |

### ROM Instructions

<details>
  <summary>Click to expand</summary>

1. Download and Install [ORCA](https://github.com/opengateware/tools-orca/releases/latest) (Open ROM Conversion Assistant)
2. Download the [ROM Recipes](https://github.com/opengateware/arcade-irem_m72/releases/latest) and extract to your computer.
3. Copy the required MAME `.zip` file(s) into the `roms` folder.
4. Inside the `tools` folder execute the script related to your system.
   1. **Windows:** right click `make_roms.ps1` and select `Run with Powershell`.
   2. **Linux and MacOS:** run script `make_roms.sh`.
5. After the conversion is completed, copy the `Assets` folder to the Root of your SD Card.
6. **Optional:** an `.md5` file is included to verify if the hash of the ROMs are valid. (eg: `md5sum -c checklist.md5`)

> **Note:** Make sure your `.rom` files are in the `Assets/irem_m72/common` directory.

</details>

## Status of Features

> **WARNING**: This repository is in active development. There are no guarantees about stability. Breaking changes might occur until a stable `1.0` release is made and announced.

- [ ] NVRAM/HiScore Save

## Credits and acknowledgment

- [Martin Donlon]
- [Jose Tejada]
- [Gyorgy Szombathelyi]

## Support

Please consider showing your support for this and future projects by contributing to the developers. While it isn't necessary, it's greatly appreciated.

- OpenGateware: [Marcus Andrade](https://ko-fi.com/boogermann)

## Powered by Open-Source Software

This project borrowed and use code from several other projects. A great thanks to their efforts!

| Modules        | Copyright/Developer    |
| :------------- | :--------------------- |
| [Irem M72 RTL] | 2022 (c) Martin Donlon |
| [V30]          | 2021 (c) Robert Peip   |
| [JT51]         | 2017 (c) Jose Tejada   |

## License

This work is licensed under multiple licenses.

- All original source code is licensed under [GNU General Public License v3.0 or later] unless implicit indicated.
- All documentation is licensed under [Creative Commons Attribution Share Alike 4.0 International] Public License.
- Some configuration and data files are licensed under [Creative Commons Zero v1.0 Universal].

Open Gateware and any contributors reserve all others rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel or otherwise.

Individual files may contain the following SPDX license tags as a shorthand for the above copyright and warranty notices:

```text
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-License-Identifier: CC0-1.0
```

This eases machine processing of licensing information based on the SPDX License Identifiers that are available at <https://spdx.org/licenses/>.

## Legal Notices

The Open Gateware authors and contributors or any of its maintainers are in no way associated with or endorsed by IREM SOFTWARE ENGINEERING INC® or any other company not implicit indicated.
All other brands or product names are the property of their respective holders.

[Irem M72 RTL]: https://github.com/MiSTer-devel/Arcade-IremM72_MiSTer/tree/main/rtl
[JT51]: https://github.com/jotego/jt51
[V30]: https://github.com/RobertPeip
[Martin Donlon]: https://github.com/wickerwaka
[Gyorgy Szombathelyi]: https://github.com/gyurco
[Jose Tejada]: https://github.com/jotego
[GNU General Public License v3.0 or later]: https://spdx.org/licenses/GPL-3.0-or-later.html
[Creative Commons Attribution Share Alike 4.0 International]: https://spdx.org/licenses/CC-BY-SA-4.0.html
[Creative Commons Zero v1.0 Universal]: https://spdx.org/licenses/CC0-1.0.html
