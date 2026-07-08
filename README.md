# Heavy Rifle Rebalance — Fix

A compatibility repair of the community mod **Heavy Rifle Rebalance** for
*The Forever Winter* (Nexus mod [#76](https://www.nexusmods.com/theforeverwinter/mods/76)),
so it works again on the current game build.

> **Status:** work in progress. See [`WORKLOG.md`](WORKLOG.md) for the running log of
> findings and changes.

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
| `dist/` | Built fixed mod (gitignored). |
| `WORKLOG.md` | Running log. |

## Credit

Original mod by its Nexus author. This repository is a community compatibility fix; the
original cooked assets are **not** redistributed here. Any rebuilt/redistributed mod is
subject to the original author's permission.
