# Fix notes — what changed and how to test

Target build: **0.9.3.9.2** (24097213). Original mod: **Heavy Rifle Rebalance 0.9.2** (Nexus #76).

## The change (one thing)

The crash was the mod's cooked **`BP_WPN_HRF05`** blueprint failing to deserialize on the current
build (`ObjectSerializationError`). Its base blueprint changed in a July 2026 hotfix, so the
0.9.2-cooked override no longer loads.

The fix rebuilds the small **`152_HeavyRifleRebalance_P`** pak with that one asset **removed**, and
rebases the remaining 12 override assets onto the current build. Everything else is unchanged.

| Piece | Action | Why |
|---|---|---|
| `152` pak → `BP_WPN_HRF05` | **removed** | crash source; a stale 0.9.2 subset of the current base blueprint (which now has the "ADS FRS Hack", HRF05 camera-shakes, HK_Governor refs). Removing it lets the game use its own current blueprint. |
| `152` pak → other 12 assets | **rebased, kept** | `DA_WPN_HRF01–05_v2`, `DA_WPN_RFL29_v2`, `FC_HRF01–04_Damage`, `DT_CaliberToHeadshotMulti`, `MI_WPN_HRF03_UPP_01_RTC` — re-cooked onto the current build so imports are current; the rebalance values are unchanged. |
| `191` pak (meshes/textures) | **unchanged** | works fine already; low-risk. |
| TFWWorkbench JSON | **unchanged** | schema drift is benign (see below). |

HRF05 keeps its rebalanced stats (damage 36300, etc.) because those live in `DA_WPN_HRF05_v2`
(kept), not the blueprint.

### How it was verified (without launching the game)
- `retoc verify` on the rebuilt container → **verified**.
- The 12 kept chunks' **FPackageIds are byte-identical** to the original, and the only removed id is
  `BP_WPN_HRF05` — so overrides still bind to the base packages.
- Decoded in a full game mount: HRF01=730, HRF02=28000, HRF03=2300, HRF04=3800, HRF05=36300,
  RFL29=375; `FC_*_Damage` curves identical to the mod; montages/textures resolve.
- `BP_WPN_HRF05` now resolves to the **current base** blueprint (contains the FRS hack + HK_Governor).

## Install (loose files — dependencies installed separately)

Contents of `dist/HeavyRifleRebalanceFix_Loosefiles/` go where the original mod's loose files went:

- `152_…` and `191_…` (`.pak/.ucas/.utoc`) → `…\The Forever Winter\Windows\ForeverWinter\Content\Paks\Mods\`
- `TFWWorkbench\DataTable\…` → the TFWWorkbench data dir
  (post-v0.1.2 that is `…\Binaries\Win64\ue4ss\Mods\TFWWorkbench\DataTable\`).

Dependencies (unchanged, install/refresh to a **current 0.9.3.x** build):
Signature Bypass, UE4SS 3.0.1-849+, TFWWorkbench 0.1.2+ (from ConstructionVendor, Nexus #77).
After a game hotfix the community-standard step is a clean reinstall of UE4SS + Signature Bypass +
TFWWorkbench + pak mods (remove, don't just toggle).

## Test checklist (build 24097213)

1. **Baseline (optional):** original mod → expect the `…/HRF05/BP_WPN_HRF05` `ObjectSerializationError`
   crash. Fixed mod → no crash.
2. Reaches main menu and loads a mission without crashing (clears the crash).
3. `…\Binaries\Win64\UE4SS.log`: TFWWorkbench initializes, `ConfigureDataTables` resolves all tables
   (no "DataTable/RowStruct not found"). `Property '…' not found, skipping` lines are expected/benign.
4. Heavy-rifle damage: HRF01 ~730, HRF02 ~28000, HRF03 ~2300, HRF04 ~3800, HRF05 ~36300 (mag 1),
   RFL29 ~375 (mag 14); damage is flat (no ramp with upgrades).
5. Crafting: "Special ammo" + "Optics" groups appear; scope + `.50PST` recipes craft without a crash.
6. `…\Saved\Crashes\` empty; no `ObjectSerializationError` for any `BP_WPN_*` / `DA_WPN_*`.

## Known minor issues / caveats (not crash-causing)

- **Scope lens mesh:** re-registering `PICSCP4`/`PICSCP7` (now vanilla) through TFWWorkbench strips
  their lens sub-mesh — the framework's `ItemDetailsData:AddRow` hardcodes `ExtraMeshs = {}`
  (`ItemDetailsData.lua:91`), and `Replace` routes through the same path, so this can't be fixed in
  the mod's JSON. Cosmetic (scope renders without lens glass). Fix belongs in TFWWorkbench, or drop
  the two redundant scope entries from the Item JSON if the cosmetic bothers you.
- **`RecipyCraftTime` offset:** TFWWorkbench writes recipe craft-time via a hardcoded struct offset
  `0x68` (`main.lua:24`); the current recipe struct gained a field. If stale, reading a recipe could
  misbehave — verify against the current TFWWorkbench release.
- **Rebuild after future patches:** any hotfix that changes these base assets can re-break the pak.
  Re-run `tools/build_fix.sh` to re-cook onto the new build.
- **Attribution:** original mod by *Meganiikko*. This is a community compatibility fix; confirm the
  author's permission before any public redistribution.
