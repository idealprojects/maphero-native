# MapHero SDK 1.1.2 — broken `MHPointFeature` class rename (handoff for the SDK build machine)

**Audience:** Claude (or any developer) working in the repo that **builds the MapHero xcframework** (the MapLibre iOS fork with the MLN→MH rename pipeline). This document was produced on the app-workspace machine, where the bug was diagnosed by inspecting the shipped 1.1.2 binary.

## TL;DR

The 1.1.2 `MapHero.dynamic.xcframework` build exports two classes under mangled names. The rename step that converts upstream MapLibre `MLN*` symbols to `MH*` produced doubled names for exactly one class pair:

| Upstream MapLibre | Expected in MapHero | Actually shipped in 1.1.2 |
|---|---|---|
| `MLNPointFeature` | `MHPointFeature` | `MHPointFeatureClusterFeature` |
| `MLNPointFeatureCluster` | `MHPointFeatureCluster` | `MHPointFeatureClusterFeatureCluster` |

MapHero **1.1.1 was correct** (apps compiled against `MHPointFeature`). The apps (doroob/dosafe via the `core` and `main` packages) use `MHPointFeature` in 24 call sites and now fail to compile against 1.1.2 with:

```
error: cannot find type 'MHPointFeature' in scope
```

**Task on this machine:** find and fix the bad rename rule, rebuild the xcframework, and release it (suggested: 1.1.3). Do NOT rename the app code to the mangled names — the shipped names are the bug.

## Evidence (from the shipped 1.1.2 artifact)

All of this was verified against the artifact SPM downloaded from
`https://github.com/idealprojects/maphero-ios/releases/download/1.1.2/MapHero.dynamic.xcframework.zip`
(checksum `aed93b847715b63d09d9393271d22ba2f04bf9466f438d701e57e64449afc526`).

1. `Headers/MHFeature.h` declares (line numbers from the 1.1.2 header):
   ```objc
   // line 171 — should be MHPointFeature
   @interface MHPointFeatureClusterFeature : MHPointAnnotation <MHFeature>

   // line 185 — should be MHPointFeatureCluster
   @interface MHPointFeatureClusterFeatureCluster : MHPointFeatureClusterFeature <MHCluster>
   ```
   Class shape is otherwise intact (superclass `MHPointAnnotation`, protocols `MHFeature`/`MHCluster` all correctly renamed).

2. Binary symbols match the headers (checked `ios-arm64_x86_64-simulator` slice):
   ```
   _OBJC_CLASS_$_MHPointFeatureClusterFeature
   _OBJC_CLASS_$_MHPointFeatureClusterFeatureCluster
   ```
   and there is **no** `_OBJC_CLASS_$_MHPointFeature` / `_OBJC_CLASS_$_MHPointFeatureCluster`.

3. The mangling also hit **doc comments and prose**, e.g. `MHShapeSource.h` says
   "instances, such as ``MHPointFeatureClusterFeature`` objects, …" where upstream MapLibre's text
   reads "such as `MLNPointFeature` objects". This proves a text-substitution defect (the rename
   pipeline rewrote these strings everywhere), not an intentional API change.

4. **Scope: only this class pair is affected.** All 86 exported ObjC classes were scanned for
   doubled-rename artifacts (`FeatureFeature`, `LayerLayer`, `SourceSource`, `PointPoint`,
   `AnnotationAnnotation`, `ClusterFeature`, …) — the two symbols above are the only hits.
   `MHPointAnnotation`, `MHPointCollectionFeature`, `MHEmptyFeature`, `MHPolygonFeature`,
   `MHShapeCollectionFeature`, etc. are all correct.

## Where the bug likely lives

The distribution repo (`idealprojects/maphero-ios`) is just a `Package.swift` manifest pointing a
`binaryTarget` at a release zip. Its 1.1.2 commit (`daa0d25`) says:

> "MapHero 1.1.2: point binaryTarget at the **1.0.4 iOS SDK build**"

So the defect is in the SDK build repo (this machine), in whatever step renames `MLN*` → `MH*`
(rename map / sed script / codemod), in the build that produced "1.0.4".

The doubling pattern is consistent with a substitution that maps the *point-feature* identifiers to
`MHPointFeatureCluster…`. For example a rule equivalent to `MLNPoint(Feature…) → MHPointFeatureCluster(Feature…)`
applied to these identifiers would yield exactly the shipped names:

- `MLNPointFeature` → `MHPointFeatureCluster` + `Feature` = `MHPointFeatureClusterFeature`
- `MLNPointFeatureCluster` → `MHPointFeatureCluster` + `FeatureCluster` = `MHPointFeatureClusterFeatureCluster`

Since `MLNPointAnnotation` renamed correctly, the pipeline probably uses an explicit per-symbol
mapping table (not a blanket prefix rule) and contains one wrong entry.

**Start by grepping the build repo for `PointFeatureCluster`** in the rename map/scripts — the bad
entry should be immediately visible. Expected correct mapping:

```
MLNPointFeature        -> MHPointFeature
MLNPointFeatureCluster -> MHPointFeatureCluster
```

(If the map is order-sensitive, make sure the longer name `MLNPointFeatureCluster` is replaced
before/independently of `MLNPointFeature` so one rule can't re-trigger on the other's output.)

## How to verify the fix before releasing

After rebuilding the xcframework, run against the built framework (any slice):

```bash
# 1. Correct classes present, mangled ones gone:
nm -gU MapHero.framework/MapHero | grep 'OBJC_CLASS' | grep -E 'PointFeature'
# want:    _OBJC_CLASS_$_MHPointFeature
#          _OBJC_CLASS_$_MHPointFeatureCluster
# must NOT contain: MHPointFeatureClusterFeature / MHPointFeatureClusterFeatureCluster

# 2. Headers clean (also catches doc comments):
grep -rn "MHPointFeatureClusterFeature" MapHero.framework/Headers/   # expect no output
grep -n "@interface MHPointFeature" MapHero.framework/Headers/MHFeature.h

# 3. General doubled-rename sweep over all exported classes:
nm -gU MapHero.framework/MapHero | grep 'OBJC_CLASS' | awk -F'OBJC_CLASS_[$]_' '{print $2}' \
  | grep -E "ClusterFeature|FeatureFeature|PointPoint|AnnotationAnnotation|LayerLayer|SourceSource|StyleStyle"
# expect no output
```

A minimal compile smoke test that mirrors real app usage:

```swift
import MapHero
let f = MHPointFeature()
f.coordinate = CLLocationCoordinate2D(latitude: 31.9, longitude: 35.2)
let src = MHShapeSource(identifier: "t", features: [f], options: nil)
let _ = src.shape as? MHPointFeature
```

## Release checklist

1. Fix rename rule → rebuild `MapHero.dynamic.xcframework.zip`.
2. `swift package compute-checksum MapHero.dynamic.xcframework.zip`
3. In `idealprojects/maphero-ios` (distribution repo): create GitHub release **1.1.3** with the zip
   attached, update `Package.swift` `binaryTarget` `url` (…/download/1.1.3/…) and `checksum`, tag `1.1.3`.
4. App side (other machine) picks it up automatically: `main/Package.swift` declares
   `.upToNextMajor(from: "1.1.1")`, so an SPM "Update Package Versions" resolves to 1.1.3.

## Current state of the app workspace (for reference)

- App code still uses the **correct** names (`MHPointFeature` in 24 places across `core`, `main`,
  `doroob`, `dosafe`) — nothing to change there once 1.1.3 ships.
- The workspace currently resolves MapHero **1.1.2** and therefore fails to build
  (`core/Sources/core/custom/UserLocationPluginController.swift` errors first). Interim option until
  1.1.3: pin `exact: "1.1.1"` in `main/Package.swift`.
