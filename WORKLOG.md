# Heavy Rifle Rebalance — Fix Worklog

Running tally of what we find and do. Newest entries at the bottom of each day.

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

### DIAGNOSIS (parallel workflow `hrr-diagnose`, 4 finders + synthesis) — see docs/diagnosis.md
**Root cause (confirmed):** the mod's cooked `BP_WPN_HRF05` blueprint throws
`ObjectSerializationError` on 0.9.3.9.2 → crash. Two July 2026 Nexus reports name exactly this
asset after "today's update"; worked on early 0.9.3 (Mar). Our structural check confirms: the mod's
`BP_WPN_HRF05` (307 KB) is a **stale subset** of the current base (327 KB) — base has the new
"ADS FRS Hack for RFL05", HRF05 camera-shakes, and a `BP_HK_Governor` ref (July HK rework); the mod
adds nothing base lacks. A 0.9.2-cooked BP whose base changed under it can't deserialize.

**Paks DO override correctly** — bare paths were a red herring. FPackageId 13/13 of the 152 pak's
chunks match base `/Game/...` path hashes (0/13 match bare). Rebalance numbers are live. IoStore
compat otherwise fine (same UE 5.4.2, TOC v6); only import/export-hash drift bites, and that's
exactly what hit the blueprint.

**JSON side:** mostly benign (Add overwrites now-vanilla rows but with matching defaults). One real
regression: re-Add of `PICSCP4/7` drops their lens mesh (`ItemDetailsData.lua:91-92`) → use
`Replace`. Version-risk: hardcoded `RecipyCraftTime` offset `0x68` may be stale. Deps frozen at
Jan 2026 (no 0.9.3.x tag).

**Recommended fix = Option C (hybrid):** drop the mod's `BP_WPN_HRF05` (crash source, stale subset;
HRF05 stats live in its DataAsset) → rebase the remaining pak assets onto the current build with
retoc → fix JSON (Add→Replace on vanilla rows, verify 0x68) → refresh deps → in-game test.
JSON-only is impossible (TFWWorkbench can't set CurveFloats / DA scalars).

### BUILD — fix built (user chose "build files, I test"; game not launched)
Tooling: **retoc v0.1.5** (trumank/retoc, sha256-verified) in `tools/retoc/` (gitignored).

**Fix = pak-only, minimal.** Rebuilt `152_HeavyRifleRebalance_P` with the crashing `BP_WPN_HRF05`
dropped; other 12 override assets rebased onto the current build. `191` mesh pak + TFWWorkbench
JSON left unchanged.

Method (see `tools/build_fix.sh`, reproducible):
1. Stage current game (hardlinks) + original mod renamed `zzz_` so it WINS the FPackageId collision.
2. `retoc to-legacy` the 12 keepers (mod version wins; imports resolve vs current base).
   - Gotcha: mod-won extracts land at BARE paths → **repath to real /Game paths** before to-zen
     (retoc derives FPackageId from file path). `to-legacy` preserves montage imports in the .uasset.
3. `retoc to-zen --version UE5_4` → new 152 (12 packages, no BP).

**Verified without launching:**
- `retoc verify` → verified. 12 kept chunk FPackageIds **byte-identical** to original; only removed
  id = `BP_WPN_HRF05` (`e1441b0413b25fd5`).
- Decoded in full game mount: damages HRF01 730 / HRF02 28000 / HRF03 2300 / HRF04 3800 /
  HRF05 36300 / RFL29 375; `FC_*_Damage` curves identical; montages/textures resolve.
- With fix mounted, `BP_WPN_HRF05` resolves to **current base** BP (has FRS hack + HK_Governor) →
  crash source eliminated.

Gotchas learned (documented): `to-zen` in isolation NULLS external refs → always verify decode in a
FULL mount (isolated-mount nulls are artifacts, not data loss). Scope-lens loss on `PICSCP4/7` is a
**TFWWorkbench framework** limitation (`ItemDetailsData:AddRow` hardcodes `ExtraMeshs={}`, and
`Replace` routes through it) — NOT fixable in mod JSON; cosmetic; documented.

**Delivered:** `dist/HeavyRifleRebalanceFix_Loosefiles/` (fixed 152 + original 191 + JSON + readme).
`docs/fix-notes.md` = what changed + install + test checklist + caveats.

### Next (user)
- [x] Install dist loose files + current deps; launch build 24097213; run docs/fix-notes.md checklist. — **done: successful in-game tests on 0.9.3.9.2 (2026-07-08).**
- [x] Report back if any residual crash (would mean another pak asset needs the same treatment). — **none reported.**
- [ ] (optional) confirm original-author permission before any public redistribution.

### 2026-07-08 — publish
- Per user request, the built fix package under `dist/` is now **tracked** (exception to the
  usual no-cooked-assets policy) so the repo ships the repaired mod directly. `.gitignore` updated
  with `!dist/**`; scratch (`work/`, `staging*/`, `decode-out/`, `tools/retoc/`) stays ignored.
- Pushed to `dataterminals/HeavyRifleRebalanceFix`.
- Note re: "kismet bytecode" question — yes, the mod shipped compiled Blueprint (Kismet) bytecode,
  but only inside `BP_WPN_HRF05` (13 Function exports incl. ExecuteUbergraph). The fix DROPS that
  blueprint, so the rebuilt 152 pak now contains ZERO bytecode — only data assets/curves/DT/material.

> **In plain terms:** This mod ("Heavy Rifle Rebalance") changes how the game's big rifles perform.
> It started crashing because one leftover file inside it — a gun "blueprint" (a recipe the game
> follows to build a weapon) — was made for an older version of the game and no longer fit the
> current one. The fix removes that one broken file (the gun still works fine, using the game's own
> up-to-date version) and rebuilds the rest to match today's game, so the rebalance works again with
> no crash.

---

## 2026-07-09 — `DT_CaliberToHeadshotMulti` re-dumped (Session-1 TODO closed)

The Session-1 caveat — "`DT_CaliberToHeadshotMulti` dumped empty in isolation → **TODO re-dump**" —
is resolved. Re-decoded via the `forever-winter-datamine` CUE4Parse decoder in a **full game + mod
mount** (base `STRUCT_CaliberToHeadshotMulti` present, so rows actually parse this time):

- Base-only mount = vanilla; base + `zzz_`-renamed 152 pak mount = mod wins the FPackageId override.
- The mod changes **exactly two** of the 20 caliber rows, both `1.5 → 5.0`× headshot multiplier:
  - `Item.Ammo.127` — 12.7×55 subsonic (VKS **Vykhlop** RFL29)
  - `Item.Ammo.54R` — 7.62×54R (**SVD**)
- All 18 other rows are byte-identical to vanilla (e.g. `20mm` 12.0; `50cal`/`.308`/`.357` 3.0; `12g` 0.25).

Matches the original author's "massively increased headshot damage" note for the Vykhlop and SVD.
It's **caliber-wide**: any weapon firing 12.7-sub or 7.62×54R gets the 5.0× headshot, not just those two guns.

> **In plain terms:** We double-checked one more of the mod's changes and confirmed what it does:
> it makes headshots hit much harder — more than three times as hard — but only for two kinds of
> ammo (the rounds used by the VKS "Vykhlop" and the SVD rifles). Any gun that fires those rounds
> gets the boost, not just those two rifles.

---

## 2026-07-09 — in-game tests green + released on Nexus

- **Successful in-game tests on build 0.9.3.9.2 (24097213)** (tests run 2026-07-08): the fixed
  loose-files package (fixed `152` + original `191` + TFWWorkbench JSON) with current deps loads
  clean — no `ObjectSerializationError`, HRF05 runs on the game's own current base blueprint, and the
  heavy-rifle rebalance numbers apply. The static-analysis diagnosis held up; no residual crash reported.
- **Published to NexusMods** — [Nexus #123](https://www.nexusmods.com/theforeverwinter/mods/123). Repo status flipped WIP → released (README status line + the diagnosis
  "still unverified" launch caveat updated to match).

> **In plain terms:** The repaired mod was actually played on the current version of the game and it
> worked — no crash, and the rifle changes took effect. It's now published on Nexus (mod #123), so
> you can download and use it.

---

## 2026-07-10 — Crash report triaged → NOT us (stale third-party `BP_AI_Euruska_MeatMan`)

A community member reported a **startup crash** while running the fix + a "5-second hub upgrades"
mod, and suspected the fix (the `ObjectSerializationError` *looks* like the old HRF05 break — same
error class, different asset):

```
LowLevelFatalError [File:G:\FW-staging\...\AsyncLoading2.cpp] [Line: 1814]
ObjectSerializationError: /Game/FW/AI/Characters/Euruska/MeatMan/BP_AI_Euruska_MeatMan
  (0x7551B1DC4D4EECD5) - ...Default__BP_AI_Euruska_MeatMan_C: Bad export index 1066192076/32.
```

**Verdict: not the Heavy Rifle Rebalance fix.** The crashing asset is the Euruska **"Meatman" AI
boss blueprint** — an enemy, not a weapon. Three independent proofs:

1. **Cryptographic — our mod ships zero MeatMan.** The crash log prints the package's runtime
   FPackageId `0x7551B1DC4D4EECD5`. `CityHash64` of the lowercased UTF-16LE path
   `/Game/FW/AI/Characters/Euruska/MeatMan/BP_AI_Euruska_MeatMan` reproduces it **exactly**. That id
   (LE chunk id `d5ec4e4ddcb15175`) is in **neither** shipped pak — `retoc list` of `152` (12 pkgs)
   + `191` (18 pkgs) = 30 packages, none is MeatMan. Cross-check: the 5 `DA_WPN_HRF0x_v2` path
   hashes land exactly in `152`, and the dropped `BP_WPN_HRF05` (`e1441b0413b25fd5`) is correctly
   absent. (`scratchpad/meatman_check.py`, reuses the AllWeaponsUnlockableFix CityHash64 port.)
2. **Base health.** Vanilla `BP_AI_Euruska_MeatMan` deserializes **clean** on 0.9.3.9.2 (CUE4Parse
   full mount, `ok=1 fail=0`, 32 exports) → the base asset isn't broken; the crash requires a
   **stale cooked override** of it loaded from some *other* pak.
3. **JSON side ships no cooked assets** (weapon/item/recipe text rows only).

**Actual cause (well-sourced):** a known TFW stale-cooked-asset crash, documented on **unrelated**
mod pages (Map Mode Selector [#61 posts](https://www.nexusmods.com/theforeverwinter/mods/61?tab=posts))
with the same string + the dev's `G:\FW-staging` build path in the log. `Bad export index
1066192076/32` = a serialized reference reading a garbage index into a 32-export table — the UE5
signature of a mod-shipped cooked asset / Blueprint-loader gone stale across a hotfix. The reporter's
"5-second hub upgrades" is an **innards-cost UE4SS JSON mod** (Cheaper Innards Upgrades [#51]-class;
edits `TimeToUpgrade` ticks + costs, no pak, no AI) → also can't cause it. Most likely: **leftover
paks / BP-loader files from the old HRR *all-in-one*** (bundled CheatManager/DayNightSelector
Blueprint mods) or another stale pak mod in the load order. Reporter's own crash predates the fix
("same crash before and after") → the fix was never the cause.

**Remedy relayed:** full clean reinstall of the whole stack vs 0.9.3.9.2 — Signature Bypass (redo
every update) + UE4SS + TFWWorkbench + **all** pak mods, deleting leftovers first; if it persists,
add non-HRF paks back one at a time to find the stale MeatMan, and post the full crash log + complete
mod list. Fixed `152`/`191` are proven clean; no repo change needed.

> **In plain terms:** A player's game crashed on startup and thought this mod broke it. It didn't.
> The crash is about an *enemy* character (the "Meatman"), but this mod only changes guns — and we
> checked every file in it: that enemy isn't in there at all. The real cause is a *different,
> out-of-date mod file* left over from an earlier game update. To fix it: delete all your mods and
> reinstall the current versions from scratch; if it still crashes, add them back one at a time until
> the crash comes back — whichever mod you added last is the bad one.

---

## 2026-07-10 — Vykhlop (RFL29) damage not applying → added flattened `FC_RFL29_Damage` (v1.1)

A [Nexus #123](https://www.nexusmods.com/theforeverwinter/mods/123) comment: *"the mod does not
change the AT-43 and the Vykhlop, at least for me."* Datamined the damage pipeline.

**Root cause (Vykhlop — confirmed):** a heavy rifle's real per-shot damage comes from its
`FC_*_Damage` **curve**, not the DA `WeaponDamage` scalar. Proof: vanilla `FC_HRF01_Damage` ramps
300→500; the mod flattens it to **780/780** and that's what HRF01 deals (its DA says 730 — cosmetic).
The mod ships `FC_HRF01–04_Damage` but **never shipped `FC_RFL29_Damage`** (exists in vanilla, ramps
175→350). So the Vykhlop's DA change (175→375) was ignored and it kept vanilla damage. The four HRF
rifles work because their curve is overridden; the Vykhlop's never was.

Corrected a v1.0 diagnosis error along the way: **`WeaponPartTunableDataAsset` is NOT nulled** in the
mod's DAs — a full-mount decode shows HRF01 (works) and RFL29 both keep the tunable ref. "Nulled in
every DA" was an isolated-mount null artifact. The tunable isn't the lever; the FC curve is.

**Fix (v1.1):** extract the current base `FC_RFL29_Damage`, flatten both keyframes 175/350 → **375**
(mirroring FC_HRF01–04), add it to the 152 pak. `tools/build_fix.sh` updated (H: paths + an FC_RFL29
base-extract+patch step; sources the 12 keepers from `dist/` since the original mod pak is gitignored).

**Verified (static):** 152 now **13 packages** (`retoc verify` ok); FC_RFL29 FPackageId binds; isolated
decode `FC_RFL29_Damage` reads **[375, 375]**, all 12 keepers intact (FC_HRF01 still [780,780]; DAs
730 / 36300 / 375). Loosefiles zip regenerated. Awaiting in-game test.

**AT-43 (HRF05) — still open.** Unlike Vykhlop it has NO FC curve and NO tunable, so its damage should
be the DA scalar (36300 — which the fix DOES set and bind correctly). No damage curve exists for the
railgun; its damage lands in `BP_WPN_HRF05` / `BP_Projectile_HRF05` bytecode (not readable via property
decode). So either AT-43 actually works (reporter may have conflated it with Vykhlop) or its damage is
applied in the dropped-BP / projectile path. Needs the reporter's confirmation (measured damage vs the
stat card) and/or Kismet disassembly.

> **In plain terms:** A player said two guns — the AT-43 and the Vykhlop — weren't being changed by the
> mod. For the Vykhlop we found the cause: a gun's real damage comes from a hidden "damage curve" file,
> and the mod updated that curve for four of the rifles but skipped the Vykhlop's — so its damage stayed
> at the original number. This update adds the missing curve, so the Vykhlop now hits for its intended
> damage. The AT-43 works differently (it has no such curve) and is still being looked into.

### Next (user)
- [ ] In-game test on the current build: Vykhlop (RFL29) now does ~375/shot.
- [ ] Confirm with the reporter whether AT-43 is really unchanged (measured), or was conflated with the Vykhlop.
