#!/usr/bin/env bash
# Rebuild the fixed 152_HeavyRifleRebalance_P pak.
#
# v1.0: the original mod's 12 override assets rebased onto the current build, with the crashing
#   BP_WPN_HRF05 dropped (the base BP changed under it -> ObjectSerializationError; HRF05's stats
#   live in DA_WPN_HRF05_v2, which stays).
#
# v1.1 (2026-07-10): ADD a flattened FC_RFL29_Damage override so the VKS Vykhlop's damage actually
#   changes. Root cause of the community "AT-43 / Vykhlop don't change" report: a heavy rifle's real
#   per-shot damage comes from its FC_*_Damage CURVE, not the DA WeaponDamage scalar (proven: vanilla
#   FC_HRF01 ramps 300->500, the mod flattens it to 780 and that's what HRF01 deals). The mod ships
#   FC_HRF01-04 but NEVER shipped FC_RFL29 (and no FC curve exists for the AT-43/HRF05 railgun), so
#   those two kept vanilla damage. FC_RFL29_Damage is extracted from the CURRENT base and flattened
#   to 375 (== the Vykhlop's intended damage / its DA WeaponDamage), mirroring FC_HRF01-04.
#   (AT-43/HRF05 is a separate open case: no FC curve, fires BP_Projectile_HRF05 - still under investigation.)
#
# Requires: retoc, the game installed, python3.
# Sources the 12 keepers from dist/ (the original mod's cooked paks are gitignored). Point SRC152 at
# the original mod's 152 pak instead if you have it - same result (dist == the rebased original).
set -euo pipefail

REPO="H:/Github Repositories/HeavyRifleRebalanceFix"
GAME_PAKS="H:/SteamLibrary/steamapps/common/The Forever Winter/Windows/ForeverWinter/Content/Paks"
AES="0x84B2244BE0AF90C22976D739FA0665569219F4CEA119CEA37C81F2D9ABEE4795"
RETOC="${RETOC:-H:/Github Repositories/UnkillablesRebalanceFix/tools/retoc/retoc.exe}"  # gitignored here; reuse sibling
PY="${PY:-python}"
SRC152="${SRC152:-$REPO/dist/HeavyRifleRebalanceFix_Loosefiles}"   # source of the 12 keeper packages

# 12 keepers (everything the 152 overrides EXCEPT the dropped BP_WPN_HRF05):
KEEPERS="DA_WPN_HRF01_v2 DA_WPN_HRF02_v2 DA_WPN_HRF03_v2 DA_WPN_HRF04_v2 DA_WPN_HRF05_v2 \
DA_WPN_RFL29_v2 FC_HRF01_Damage FC_HRF02_Damage FC_HRF03_Damage FC_HRF04_Damage \
DT_CaliberToHeadshotMulti MI_WPN_HRF03_UPP_01_RTC"

STAGE="$REPO/work/staging-full"; LEG="$REPO/work/legacy"; LEGB="$REPO/work/legacy-fc"
REP="$REPO/work/legacy-repath"; OUT="$REPO/work/out152"
DIST="$REPO/dist/HeavyRifleRebalanceFix_Loosefiles"

echo "[1/7] stage current game (hardlinks) + source 152 renamed zzz_ (wins the FPackageId collision)"
rm -rf "$STAGE"; mkdir -p "$STAGE"
for f in "$GAME_PAKS"/*; do [ -f "$f" ] && ln "$f" "$STAGE/$(basename "$f")"; done
for e in pak ucas utoc; do cp "$SRC152/152_HeavyRifleRebalance_P.$e" "$STAGE/zzz_HeavyRifleRebalance_P.$e"; done

echo "[2/7] to-legacy the 12 keepers (source 152 wins; imports resolve vs current base)"
rm -rf "$LEG"; mkdir -p "$LEG"
for k in $KEEPERS; do "$RETOC" -a "$AES" to-legacy --version UE5_4 -f "$k" "$STAGE" "$LEG" >/dev/null 2>&1; done

echo "[3/7] to-legacy FC_RFL29_Damage from CURRENT BASE (new in v1.1)"
rm -rf "$LEGB"; mkdir -p "$LEGB"
"$RETOC" -a "$AES" to-legacy --version UE5_4 -f FC_RFL29_Damage "$GAME_PAKS" "$LEGB" >/dev/null 2>&1

echo "[4/7] flatten FC_RFL29_Damage keyframes 175/350 -> 375 (self-verifying)"
FCUEXP=$(find "$LEGB" -name FC_RFL29_Damage.uexp | head -1)
"$PY" - "$FCUEXP" <<'PY'
import struct,sys
p=sys.argv[1]; b=bytearray(open(p,'rb').read())
for base in (175.0,350.0):
    n=b.count(struct.pack('<f',base))
    assert n==1, f"ABORT: expected 1x float32 {base} in FC_RFL29_Damage, found {n}"
    b=bytearray(b.replace(struct.pack('<f',base), struct.pack('<f',375.0)))
assert b.count(struct.pack('<f',375.0))==2, "ABORT: expected 2x 375 after patch"
open(p,'wb').write(b); print("  FC_RFL29_Damage: 175 & 350 -> 375 (flat)")
PY

echo "[5/7] repath bare extracts to real /Game paths (retoc derives FPackageId from path) + add FC_RFL29"
rm -rf "$REP"
"$PY" - "$LEG" "$LEGB" "$REP" <<'PY'
import os,sys,shutil
leg,legb,rep=sys.argv[1],sys.argv[2],sys.argv[3]
base="ForeverWinter/Content/"
m={"DA_WPN_HRF01_v2":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF01/",
 "DA_WPN_HRF02_v2":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF02/",
 "DA_WPN_HRF03_v2":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF03/",
 "DA_WPN_HRF04_v2":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF04/",
 "DA_WPN_HRF05_v2":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF05/",
 "DA_WPN_RFL29_v2":"FW/Weapons/Weapon_V2/RFL_Rifles/RFL29/",
 "FC_HRF01_Damage":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF01/HRF01_UpgradeTuning/",
 "FC_HRF02_Damage":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF02/HRF02_UpgradeTuning/",
 "FC_HRF03_Damage":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF03/HRF03_UpgradeTuning/",
 "FC_HRF04_Damage":"FW/Weapons/Weapon_V2/HRF_HeavyRifles/HRF04/HRF04_UpgradeTuning/",
 "DT_CaliberToHeadshotMulti":"FW/Weapons/Weapon_V2/",
 "MI_WPN_HRF03_UPP_01_RTC":"WPN_Weapons/HRF_HeavyRifles/HRF03/"}
def put(rel,srcdir,name):
    d=os.path.join(rep,*(base+rel).rstrip("/").split("/")); os.makedirs(d,exist_ok=True)
    got=0
    for ext in(".uasset",".uexp"):
        # search srcdir (bare or path-preserving) for the file
        src=os.path.join(srcdir,name+ext)
        if not os.path.exists(src):
            for root,_,files in os.walk(srcdir):
                if name+ext in files: src=os.path.join(root,name+ext); break
        if os.path.exists(src): shutil.copy2(src,os.path.join(d,name+ext)); got+=1
    return got
for name,rel in m.items(): put(rel,leg,name)
put("FW/Weapons/Weapon_V2/RFL_Rifles/RFL29/RFL29_UpgradeTuning/",legb,"FC_RFL29_Damage")
shutil.copy2(os.path.join(leg,"scriptobjects.bin"),os.path.join(rep,"scriptobjects.bin"))
print("  repathed 12 keepers + FC_RFL29_Damage = 13 packages")
PY

echo "[6/7] to-zen -> new 152 (13 packages) + verify"
rm -rf "$OUT"; mkdir -p "$OUT"
"$RETOC" to-zen --version UE5_4 "$REP" "$OUT/152_HeavyRifleRebalance_P.utoc" >/dev/null 2>&1
"$RETOC" verify "$OUT/152_HeavyRifleRebalance_P.utoc"

echo "[7/7] swap the rebuilt 152 into dist/ (191 meshes + TFWWorkbench JSON unchanged)"
for e in pak ucas utoc; do cp "$OUT/152_HeavyRifleRebalance_P.$e" "$DIST/152_HeavyRifleRebalance_P.$e"; done
echo "DONE -> $DIST  (152 now 13 packages incl. flattened FC_RFL29_Damage = 375)"
