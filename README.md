# Heavy Rifle Rebalance — Fix

A compatibility repair of the community mod **Heavy Rifle Rebalance** for
*The Forever Winter* (Nexus mod [#76](https://www.nexusmods.com/theforeverwinter/mods/76)),
so it works again on the current game build.

> **Status:** released as [**Nexus #123**](https://www.nexusmods.com/theforeverwinter/mods/123), confirmed working in-game on build **0.9.3.9.2** (24097213) via successful
> community tests. See [`WORKLOG.md`](WORKLOG.md) for the running log of findings and changes.

## What the mod does

Heavy Rifle Rebalance reworks the game's heavy rifles (the `HRF` class + the VKS `RFL29`):
adjusts their weapon/part stats, adds magazine and optic parts, and adds crafting recipes
for special ammo and scopes. It is a **hybrid mod**:

- **Cooked pak assets** (`152_` and `191_HeavyRifleRebalance_P`) — the weapon DataAssets,
  blueprints, meshes, part-unlock tables and tuning curves.
- **TFWWorkbench JSON DataTables** — runtime patches that register those weapons, parts,
  items and recipes into the game's core data tables.

> **In plain terms:** This mod overhauls the game's heavy rifles — tweaking their stats and
> adding new magazines, scopes, and crafting recipes for them. It comes in two pieces that work
> together: some packaged game files and some extra data files that plug the new gear into the game.

## The problem

The mod ships for game version **0.9.2**. On the current build (**0.9.3.9.2**, build 24097213)
it no longer works. This repo diagnoses why and ships a fixed build.

> **In plain terms:** The original mod was built for an older version of the game and stopped
> working after an update. This project figures out what broke and gives you a version that
> works on the current game.

## Dependencies (unchanged from upstream)

- Signature Bypass (2025)
- UE4SS `3.0.1-849`+
- TFWWorkbench `0.1.2`+

> **In plain terms:** This mod doesn't run on its own — you need these three helper tools
> installed first, or it won't load. They're the same ones the original mod required, so if you
> already had that working, you're already set.

## Layout

| Path | Contents |
|------|----------|
| `upstream/` | Pristine extracted originals (all-in-one + loose files). Reference only; cooked binaries are gitignored. |
| `docs/` | Diagnosis notes, datamine comparisons. |
| `tools/` | Repair/build scripts. |
| `dist/` | **Built fixed mod** — tracked; ships the repaired loose-files package (fixed `152` + `191` paks + TFWWorkbench JSON). |
| `WORKLOG.md` | Running log. |

> **In plain terms:** This table just explains the project's folders for anyone poking around
> the files. If you only want to play, the one folder that matters is `dist/` — that's the
> finished, ready-to-install mod.

## Install (players)

Grab [`dist/HeavyRifleRebalanceFix_Loosefiles/`](dist/HeavyRifleRebalanceFix_Loosefiles) and follow
[`docs/fix-notes.md`](docs/fix-notes.md) (install paths, dependencies, test checklist).

> **In plain terms:** To install it, grab the `HeavyRifleRebalanceFix_Loosefiles` folder and
> follow the step-by-step notes linked above — they tell you where to put the files, what else
> you need, and how to check it worked.

## Rebuilding the pak (dev setup)

The repaired mod is **prebuilt** in `dist/`, so for editing docs/JSON or reading the analysis you
need nothing extra — a plain clone is enough.

To re-run [`tools/build_fix.sh`](tools/build_fix.sh) (rebuild the `152` pak from scratch — e.g. after
a future patch re-breaks it), a fresh clone needs three things that are **gitignored** and must be
re-fetched:

1. **retoc** `v0.1.5` → `tools/retoc/retoc.exe` — download the Windows zip from
   [trumank/retoc releases](https://github.com/trumank/retoc/releases) and unzip it there.
2. **The original mod's cooked paks** → restore `upstream/**/152_*` and `191_*`
   (`.pak/.ucas/.utoc`) from the Nexus [#76](https://www.nexusmods.com/theforeverwinter/mods/76)
   archives (the vendored *text* is committed; the cooked packs are not). `build_fix.sh` reads them.
3. **Datamine toolchain** → the `forever-winter-datamine` repo (CUE4Parse decoder +
   `ForeverWinter-5.4.2.usmap`), plus the game installed, for decode-verification and the AES mount.

Also needs Python 3 (with `py7zr` to unpack the `.7z`s) and the game at the path set in
`build_fix.sh`.

> **In plain terms:** You can skip this whole section if you just want to play — the mod is
> already built and waiting in `dist/`. It only matters for people who want to rebuild the mod
> from scratch, who need a few extra tools and files that aren't bundled here.

## Credit

Original mod **Heavy Rifle Rebalance** by *Meganiikko* (Nexus #76). This repository is a community
**compatibility fix** and redistributes a repaired build for players on the current game version.
Redistribution here is on that basis; it remains subject to the original author's permission.

> **In plain terms:** The original mod was made by Meganiikko; this is a community-made fix that
> repackages it to run on the current game. It's shared on the understanding that it still
> respects the original creator's permissions.
