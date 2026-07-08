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

### Next
- [ ] Decode mod paks 152 & 191 (stage next to base game via junction).
- [ ] Datamine current HRF01–05 / RFL29 assets + weapon/part/item DataTable row structs.
- [ ] Determine current TFWWorkbench version and whether it loads on 24097213.
- [ ] Community/Nexus research: what exactly users report as "broken".
- [ ] Root-cause diagnosis → fix plan.
