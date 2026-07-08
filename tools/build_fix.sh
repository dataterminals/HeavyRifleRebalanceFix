#!/usr/bin/env bash
# Rebuild the fixed 152_HeavyRifleRebalance_P pak = the original mod's 12 override
# assets rebased onto the current game build, with the crashing BP_WPN_HRF05 dropped.
#
# WHY: on build 0.9.3.9.2 the mod's cooked BP_WPN_HRF05 throws ObjectSerializationError
# (the base blueprint changed under it). Dropping that one override makes the game use
# its own current BP_WPN_HRF05; the rebalance lives in DA_WPN_HRF05_v2, which stays.
#
# Requires: retoc (tools/retoc/retoc.exe), the game installed, python3.
# Re-run this after a future patch that re-breaks the pak (re-cook rebases onto the new build).
set -euo pipefail

REPO="D:/Github Repositories/HeavyRifleRebalanceFix"
GAME_PAKS="D:/SteamLibrary/steamapps/common/The Forever Winter/Windows/ForeverWinter/Content/Paks"
AES="0x84B2244BE0AF90C22976D739FA0665569219F4CEA119CEA37C81F2D9ABEE4795"
RETOC="$REPO/tools/retoc/retoc.exe"
PY="/c/Users/sylvi/AppData/Local/Programs/Python/Python312/python"
ORIG_MOD="$REPO/upstream/loose-files/HeavyRifleRebalance Loose files/HeavyRifleRebalance_Loosefiles"

# 12 keeper assets (everything the 152 pak overrides EXCEPT BP_WPN_HRF05):
KEEPERS="DA_WPN_HRF01_v2 DA_WPN_HRF02_v2 DA_WPN_HRF03_v2 DA_WPN_HRF04_v2 DA_WPN_HRF05_v2 \
DA_WPN_RFL29_v2 FC_HRF01_Damage FC_HRF02_Damage FC_HRF03_Damage FC_HRF04_Damage \
DT_CaliberToHeadshotMulti MI_WPN_HRF03_UPP_01_RTC"

STAGE="$REPO/work/staging-full"; LEG="$REPO/work/legacy"; REP="$REPO/work/legacy-repath"
OUT="$REPO/dist/HeavyRifleRebalanceFix_Loosefiles"

echo "[1/5] stage current game + original mod (mod named zzz_ so it WINS the FPackageId collision)"
rm -rf "$STAGE"; mkdir -p "$STAGE"
"$PY" - "$GAME_PAKS" "$STAGE" "$ORIG_MOD" <<'PY'
import os,sys,glob,shutil
gp,stage,mod=sys.argv[1],sys.argv[2],sys.argv[3]
for f in glob.glob(os.path.join(gp,"*")):
    if os.path.isfile(f): os.link(f, os.path.join(stage,os.path.basename(f)))
for f in glob.glob(os.path.join(mod,"152_*")):
    shutil.copy2(f, os.path.join(stage,"zzz_HeavyRifleRebalance_P"+os.path.splitext(f)[1]))
print("  staged", len(os.listdir(stage)), "files")
PY

echo "[2/5] to-legacy the 12 keepers (mod version wins; imports resolve against current base)"
rm -rf "$LEG"; mkdir -p "$LEG"
for k in $KEEPERS; do
  "$RETOC" -a "$AES" to-legacy --version UE5_4 -f "$k" "$STAGE" "$LEG" >/dev/null 2>&1
done

echo "[3/5] repath bare extracts to their real /Game paths (retoc computes FPackageId from path)"
rm -rf "$REP"
"$PY" - "$LEG" "$REP" <<'PY'
import os,sys,shutil
leg,rep=sys.argv[1],sys.argv[2]
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
for name,rel in m.items():
    d=os.path.join(rep,*(base+rel).rstrip("/").split("/")); os.makedirs(d,exist_ok=True)
    for ext in(".uasset",".uexp"):
        s=os.path.join(leg,name+ext)
        if os.path.exists(s): shutil.copy2(s,os.path.join(d,name+ext))
shutil.copy2(os.path.join(leg,"scriptobjects.bin"),os.path.join(rep,"scriptobjects.bin"))
print("  repathed",len(m),"assets")
PY

echo "[4/5] to-zen -> new 152 (rebased onto current build, 12 packages, no BP_WPN_HRF05)"
mkdir -p "$OUT"
"$RETOC" to-zen --version UE5_4 "$REP" "$OUT/152_HeavyRifleRebalance_P.utoc" >/dev/null 2>&1
"$RETOC" verify "$OUT/152_HeavyRifleRebalance_P.utoc"

echo "[5/5] copy through the unchanged pieces (191 meshes + TFWWorkbench JSON)"
cp "$ORIG_MOD/191_HeavyRifleRebalance_P".{pak,ucas,utoc} "$OUT/"
mkdir -p "$OUT/TFWWorkbench"; cp -r "$ORIG_MOD/TFWWorkbench/DataTable" "$OUT/TFWWorkbench/"
echo "DONE -> $OUT"
