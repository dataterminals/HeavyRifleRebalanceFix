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

## The problem

The mod ships for game version **0.9.2**. On the current build (**0.9.3.9.2**, build 24097213)
it no longer works. This repo diagnoses why and ships a fixed build.

## Dependencies (unchanged from upstream)

- Signature Bypass (2025)
- UE4SS `3.0.1-849`+
- TFWWorkbench `0.1.2`+

## Layout

| Path | Contents |
|------|----------|
| `upstream/` | Pristine extracted originals (all-in-one + loose files). Reference only; cooked binaries are gitignored. |
| `docs/` | Diagnosis notes, datamine comparisons. |
| `tools/` | Repair/build scripts. |
| `dist/` | **Built fixed mod** — tracked; ships the repaired loose-files package (fixed `152` + `191` paks + TFWWorkbench JSON). |
| `WORKLOG.md` | Running log. |

## Install (players)

Grab [`dist/HeavyRifleRebalanceFix_Loosefiles/`](dist/HeavyRifleRebalanceFix_Loosefiles) and follow
[`docs/fix-notes.md`](docs/fix-notes.md) (install paths, dependencies, test checklist).

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

## Credit

Original mod **Heavy Rifle Rebalance** by *Meganiikko* (Nexus #76). This repository is a community
**compatibility fix** and redistributes a repaired build for players on the current game version.
Redistribution here is on that basis; it remains subject to the original author's permission.
