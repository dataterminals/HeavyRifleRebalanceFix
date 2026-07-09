Heavy Rifle Rebalance - Compatibility Fix (loose files)
Fixed for The Forever Winter build 0.9.3.9.2 (24097213).
Original mod by Meganiikko (Nexus #76). This is a community compatibility fix.

WHAT WAS FIXED
  The mod crashed on the current build with an ObjectSerializationError on
  BP_WPN_HRF05 (the cooked blueprint was built for 0.9.2 and a later hotfix
  changed the base blueprint under it). This build rebuilds the 152 pak with
  that stale blueprint removed and the other 12 override assets re-cooked onto
  the current build. HRF05 now uses the game's own current blueprint; its
  rebalanced stats are unaffected (they live in DA_WPN_HRF05_v2). The 191 mesh
  pak and the TFWWorkbench data tables are unchanged.

REQUIRES (install/refresh to a current 0.9.3.x build):
  - Signature Bypass (2025 version)
  - UE4SS 3.0.1-849 or newer
  - TFWWorkbench 0.1.2 or newer
    (all three are in the ConstructionVendor all-in-one, Nexus #77)

INSTALL
  Copy the pak files (152_* and 191_*) to:
    ...\The Forever Winter\Windows\ForeverWinter\Content\Paks\Mods\
  Copy the TFWWorkbench\DataTable\ folder into your TFWWorkbench data directory:
    ...\Binaries\Win64\ue4ss\Mods\TFWWorkbench\DataTable\
  Install the dependencies manually (see above).
  After any game hotfix, do a clean reinstall of the dependencies + pak mods.

NOTE
  Minor cosmetic: the 6x/8x craftable scopes may render without their lens glass
  (a TFWWorkbench limitation, not a crash). See docs/fix-notes.md.
