# Diagnosis — why Heavy Rifle Rebalance breaks on 0.9.3.9.2

**Build in question:** 24097213 (Hot-Fix 0.9.3.9.2). **Mod version:** 0.9.2 (author *Meganiikko*,
uploaded by *warhamer116*). Method: decoded the mod's paks vs. the live game with CUE4Parse,
parsed the mod `.utoc`s for FPackageId, read the TFWWorkbench Lua, and corroborated with the
Nexus posts/bugs tab + UE modding references.

## Root cause (confirmed)

**The mod's cooked Blueprint `BP_WPN_HRF05` fails to deserialize on the current build → hard crash.**

- Two July 2026 reports on the [mod #76 posts tab](https://www.nexusmods.com/theforeverwinter/mods/76?tab=posts):
  `ObjectSerializationError: /Game/FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF05/BP_WPN_HRF05`
  right after "today's update" (Jul 3–4). It worked on *early* 0.9.3 (Mar 29 report) → an early-July
  hotfix broke it.
- `BP_WPN_HRF05` is one of the mod's own cooked override assets (in `152_HeavyRifleRebalance_P`).
- **Our own structural check confirms the mechanism:** the mod's `BP_WPN_HRF05` (307 KB) is a *stale
  subset* of the current base blueprint (327 KB). The base has functions/refs the mod lacks —
  `"ADS FRS Hack for RFL05"`, `CameraShake_*_WPN_HRF05`, a `BP_HK_Governor` reference (from the
  July 2026 Hunter-Killer rework) — while the mod adds **nothing** base lacks (`in MOD ∖ BASE = ∅`).
  A 0.9.2-cooked blueprint whose base class/graph changed under it can no longer deserialize.

This is the textbook UE5 IoStore cooked-override break: TFW stayed on UE 5.4.2, so it's an
*asset/layout* drift, not an engine-version mount refusal.

## The paks DO override correctly (bare paths were a red herring)

The `152` pak stores assets at bare filenames under mount `../../../`, but UE5 resolves overrides by
**FPackageId** (CityHash64 of the lowercased package FName, UTF-16LE) — not the directory index.
All **13/13** of the 152 pak's `ExportBundleData` chunk IDs equal the base `/Game/...` path hashes
(0/13 match the bare-path variants). The `191` mesh pak likewise hashes to `/Game/WPN_Weapons/...`
despite its `BagmanTest/Content/` mount (that's just the author's cook-project folder). So the
rebalance numbers are **live, not orphaned** — every override binds to the right base asset.

IoStore load-compat verdict: container-header version and script-object drift are non-issues
(same engine, TOC v6). The only realistic vector is public-export-hash / import mismatch — which is
exactly what bit `BP_WPN_HRF05`, while the value-level DataAssets deserialize cleanly.

## Secondary issues (JSON / TFWWorkbench side)

- **Mostly benign schema drift.** `HRF01–05` + `RFL29` now ship as vanilla `WeaponsDetailsData` rows,
  and the current row struct gained fields the mod omits (`ActivateableAbility, Durability, DropSound,
  GachaRow, LootSound, LootTime, Value, WaterValue`). TFWWorkbench `Add` overwrites with a *fresh*
  struct (proven via its `Replace` path `DataTable.lua:70-84`), re-blanking those fields — **harmless
  because all 6 vanilla rows already hold those exact defaults.** `WeaponPartStatsData` is an exact
  18/18 field match.
- **Real (cosmetic) regression:** re-`Add`ing `PICSCP4`/`PICSCP7` (now vanilla, carrying a lens
  sub-mesh in `ExtraMeshs`) forces `ExtraMeshs={}` (`ItemDetailsData.lua:91-92`) → scopes render
  without their lens. Fix by using `Replace` (copy-existing + patch) instead of `Add`.
- **Version-sensitive risk (unverified):** `RecipyCraftTime` is written via a hardcoded
  `Int64Property` at struct offset `0x68` (`main.lua:21-26`); the current `ManufactoringRecipies`
  struct gained `AccelerationTags`. If the layout shifted, `0x68` is stale → wrong-field write on
  recipe read. Needs a current property-offset check.
- **Frozen dependency stack:** ConstructionVendor (#77) all-in-one is v0.9.1.3 (Jan 2026); TFWWorkbench
  tops out at v0.2.1 (Jan 2026); no 0.9.3.x tag. A stale Signature Bypass / UE4SS can block all mod
  loading and must be refreshed to whatever the community ships for 0.9.3.x.

## What the rebalance actually does (for reference when rebuilding)

Damage curves are **flattened** (no upgrade scaling) and raised; `WeaponPartTunableDataAsset` is
nulled in every DA (disables upgrade-based scaling):

| Weapon | Damage (base → mod) | Mag | Other |
|---|---|---|---|
| HRF01 SCAR (.50) | 300 → **730** | — | slower cadence, heavy recoil/spread, long stabilize |
| HRF02 36M AntiTank (20mm) | 2000 → **28000** | 10 → **3** | slower fire, more recoil, heavier |
| HRF03 NTW-20 (.50BMG supp) | 1100 → **2300** | 5 → **10** | — |
| HRF04 GM6 (.50BMG) | 1100 → **3800** | 5 → **10** | — |
| HRF05 AT-43 RAIL (.50PST) | 10000 → **36300** | 4 → **1** | very slow move, DistanceToSphere 20000→500 |
| RFL29 VKS (12.7 sub) | 175 → **375** | 5 → **14** | tighter grouping |

FC curves (flat): HRF01 780, HRF02 27000, HRF03 2300, HRF04 3800. `DT_CaliberToHeadshotMulti` is
modified but its rows couldn't be read in isolation (needs the base `STRUCT_CaliberToHeadshotMulti`
mounted) — **TODO re-dump**. JSON side adds 16 part-stat rows (mags, HRF01 barrels +25/+100 dmg,
6x/8x scopes, suppressor receivers), 4 items (2 VKS mags, 2 scopes), 7 recipes (`.50PST` ammo + 6
scope crafts), and 2 crafting groups (Special ammo, Optics).

## Recommended fix (Option C — hybrid, minimal fragile surface)

1. **Drop the mod's `BP_WPN_HRF05` override** — it's the confirmed crash source and a stale subset of
   base; HRF05's stats live in `DA_WPN_HRF05_v2`. Let the game use its own current blueprint.
2. **Rebase the remaining pak assets onto 0.9.3.9.2** (retoc `to-legacy` with full game mounted →
   drop BP → `to-zen --version UE5_4`), refreshing imports so no residual drift. Watch the
   bare-path/FPackageId gotcha — the repacked packages must keep their real `/Game/...` names.
3. **Fix the JSON:** `Add` → `Replace` for rows that now exist in vanilla (fixes the scope-lens loss);
   verify the `0x68` RecipyCraftTime offset against a current struct dump; drop the dangling
   `50PST_Ammo` group reference.
4. **Refresh dependencies** to current 0.9.3.x community builds (UE4SS / Signature Bypass /
   TFWWorkbench) and re-test.

Alternatives considered: **A** full re-cook (more work, same future fragility); **B** JSON-only —
*rejected*, because TFWWorkbench edits DataTables only and **cannot** express the `FC_*_Damage`
CurveFloats or the `DA_WPN` combat scalars, so it structurally can't deliver the headline damage
numbers. A pak is unavoidable; keep it minimal.

## Still unverified (honest caveats)

- Not yet confirmed by launching build 24097213 — rests on community reports + static analysis.
- The exact base-asset delta that broke `BP_WPN_HRF05` wasn't disassembled; a re-cook should rebase
  against the *true live* cook (our datamine filelist may be a hair behind live).
- `DT_CaliberToHeadshotMulti`'s actual changes are undetermined (dumped empty in isolation).
- Whether nulling `WeaponPartTunableDataAsset` + flattening FC curves is intentional vs. a re-cook
  side effect (the numbers line up, so likely intentional).
- Any future hotfix touching these base assets will re-break the pak side — inherent to pak mods.
