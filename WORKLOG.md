# Heavy Rifle Rebalance — Fix Worklog

Running tally of what we find and do. Newest entries at the bottom of each day.
Concise by design — enough to hand off, not a novel.

---

## 2026-07-08 — Session 1: recon & repo setup

**Goal:** repair the "Heavy Rifle Rebalance" mod (Nexus mod #76, The Forever Winter)
so it works on the current game build. Community relies on it; it stopped working
on recent versions.

### Environment
- Game build (live, this machine): **24097213 = Hot-Fix 0.9.3.9.2**.
- Mod ships for game **0.9.2** (from Nexus filename `...-76-0-9-2-...`).
- Datamine toolchain available: `D:\Github Repositories\forever-winter-datamine`
  (CUE4Parse decoder + `ForeverWinter-5.4.2.usmap`). Decoder mounts a Paks dir
  recursively, so mod paks can be decoded by staging them next to the base game.
- Extractor: `py7zr` (Python 3.12) — `7z.exe` not installed; WinRAR present as fallback.

### What the mod actually is (hybrid mod)
Two delivery mechanisms working together:

1. **Pak mods** (cooked UE5 IoStore assets) in `Content/Paks/Mods/`:
   - `152_HeavyRifleRebalance_P` (.pak/.ucas/.utoc) — small (~138 KB ucas).
   - `191_HeavyRifleRebalance_P` (.pak/.ucas/.utoc) — large (~5.9 MB ucas): the real
     content (weapon DataAssets, blueprints, meshes, part-unlock tables, curves).

2. **TFWWorkbench JSON DataTables** (runtime patches applied by the TFWWorkbench
   framework) in `Content/Paks/Mods/TFWWorkbench/DataTable/`:
   - `WeaponsDetailsData/005_..._WeaponDetailsData.json` — adds/overrides 6 weapon rows:
     - `RFL29` VKS Vykhlop (12.7 subsonic), `HRF01` SCAR (.50 Beowulf),
       `HRF02` 36M AntiTank (20mm), `HRF03` NTW-20 (.50BMG supp),
       `HRF04` GM6 (.50BMG), `HRF05` AT-43 RAIL (.50PST railgun).
     - Each references game paths `DA_WPN_<id>_v2`, `BP_WPN_<id>`, `DT_<id>_WeaponPartUnlocks`.
   - `WeaponPartStatsData/...` — stat rows for parts (mags, barrels, scopes, receivers).
   - `Item/...` — new items (VKS mags `WPN_RFL29_MAG_130_01/02`, scopes `PICSCP4/7`).
   - `CraftingRecipe/...` + `CraftingGroup/...` — ammo (`.50PST`) + optics crafting.

### Dependencies (per readme.txt)
- Signature Bypass (2025 build) — `bitfix/sig.lua` patches an AOB to `0xC3` (ret).
- UE4SS `3.0.1-849` or newer (bundled `UE4SS.dll`, 15.4 MB).
- TFWWorkbench `0.1.2` or newer (bundled: `dlls/main.dll` 219 KB + Lua scripts).
- All-in-one bundles these + several unrelated QoL mods (CheatManager, DayNightSelector…).
- NOTE: `mods.txt` lists TFWWorkbench (enabled); `mods.json` does **not** — a UE4SS
  new/old mod-list format mismatch to keep in mind.

### Repo layout
- `upstream/all-in-one/` and `upstream/loose-files/` — pristine extracted originals (vendored, do not edit).
- `WORKLOG.md` (this file), `README.md`, `docs/`, `dist/` (built fix), `tools/`.

### Leading hypotheses for the break (to confirm)
1. **Pak asset drift** — 152/191 cooked vs 0.9.2 global name/import map; base game
   re-cook shifts IoStore references → mod's `DA_WPN_HRF*_v2` fail to load / CTD. (most likely)
2. **DataTable schema drift** — game's weapon/part/item row structs gained/renamed/removed
   fields in 0.9.3.9.2 → TFWWorkbench "Add" rows apply partially or fail.
3. **Framework/version drift** — bundled TFWWorkbench or UE4SS too old for the new build.
4. **Reference drift** — renamed weapons/parts/ammo tags/RareLoot IDs → dangling refs.

### Decode findings (mod paks vs current game)
Decoded with the CUE4Parse toolchain (staged mod paks beside base via junction; also an
isolated `global + mod` mount to read the mod's own assets collision-free).

- **Mod pak contents** (49 added entries):
  - `152` pak (mount `../../../`, bare paths) = **override assets**: `DA_WPN_HRF01–05_v2`,
    `DA_WPN_RFL29_v2`, `FC_HRF01–04_Damage` (damage curves), `DT_CaliberToHeadshotMulti`,
    `BP_WPN_HRF05`, `MI_WPN_HRF03_UPP_01_RTC`.
  - `191` pak (mount `../../../BagmanTest/Content/`) = **new meshes/textures** for added
    mags/scopes (author's cook project is "BagmanTest").
- **All 13 override assets still exist in the current game** with identical names/paths, and
  **both mod and base assets deserialize cleanly** under the current usmap → *no* raw
  struct-parse failure in these DataAssets. Rebalance diffs are real: `DA_WPN_HRF01–05_v2`,
  `RFL29`, all 4 `FC_*_Damage` curves, `DT_CaliberToHeadshotMulti`, `MI` all DIFFER from base.
- **Bare-path caveat:** the 152 pak stores overrides at bare paths (mount `../../../` +
  `DA_WPN_HRF01_v2.uasset`), a *different* virtual path than base
  (`/Game/FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF01/...`). Whether these actually override
  base at runtime depends on cooked FPackageId, not the directory index — **OPEN QUESTION**.

### Schema drift found (likely a core cause)
- TFWWorkbench category → real game DataTable (from its Lua):
  `WeaponsDetailsData` → `/Game/Blueprints/Data/WeaponsDetailsData`;
  `WeaponPartStatsData` → `/Game/FW/Weapons/Customizer/WeaponPartStatsData`;
  `InventoryItemDetails` → `/Game/Blueprints/Data/ItemDetailsData`;
  recipes/groups → `DT_ManufactoringRecipies` / `DT_ManufactoringGroups`.
- **HRF01–05 + RFL29 are ALREADY rows in the current `WeaponsDetailsData` (56 rows total)** —
  these heavy rifles now ship in vanilla. The mod's `"Action":"Add"` therefore *overwrites
  live vanilla rows* with 0.9.2-era data.
- **Current `WeaponsDetailsData` row struct has fields the mod's JSON omits:**
  `ActivateableAbility, Durability, DropSound, GachaRow, LootSound, LootTime, Value, WaterValue`.
  The mod-era rows predate these → an Add/overwrite likely blanks them (e.g. `Durability`/`Value`
  reset), a strong candidate for the breakage.

### Raw material captured (gitignored `decode-out/`)
- `dump/base/` — 13 current-game override-target assets.
- `dump/mod/` + `dump/mod2/` — the mod's versions of those assets (collision-free).
- `dump/dt/` — current game `WeaponsDetailsData`, `WeaponPartStatsData`, `ItemDetailsData`,
  `DT_ManufactoringRecipies`, `DT_ManufactoringGroups`.

### Next
- [ ] Workflow: community/Nexus research (what "broken" means; TFWWorkbench current version)
      + rebalance content diff + framework schema-fit + IoStore override verdict → root cause.
- [ ] Decide fix strategy (re-cook paks via retoc vs. push rebalance fully into JSON vs. hybrid).
- [ ] Build + empirically verify on build 24097213.
