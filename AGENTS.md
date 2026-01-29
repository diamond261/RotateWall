# AGENTS

This repo is a Theos-based jailbreak tweak for iPadOS. The main tweak lives in `Tweak/` and the Preferences bundle lives in `Prefs/`.

## Cursor/Copilot rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found in this repo.

## Build / Lint / Test

There are no automated lint or test commands configured in this repo. Build and packaging are handled by Theos.

Common commands (run from repo root):

```sh
make
```
Builds all subprojects (Tweak + Prefs).

```sh
make package
```
Builds and packages the tweak into a .deb.

```sh
make install
```
Installs to a connected device (Theos config must be set).

```sh
make clean && make
```
Clean rebuild.

Single-target builds:

```sh
make -C Tweak
```
Builds only the tweak.

```sh
make -C Prefs
```
Builds only the Preferences bundle.

Single test:
- No unit tests exist. Manual testing is required on-device.
- If you need to validate a specific behavior, rebuild the relevant target and install it.

Notes:
- Root Makefile sets `THEOS_PACKAGE_SCHEME = rootless` by default.
- Target platform is configured in the root `Makefile`.
- No formatter or lint config is present; do not introduce one unless asked.

Deployment and debugging:
- Install builds with `make install` and test on-device.
- Preference changes are intended to apply without respring unless explicitly triggered.
- Runtime images are written under `/var/mobile/Library/RotateWall` by the tweak.

## Project Layout

- `Tweak/` contains Logos hooks and tweak logic (`Tweak.xm`, `DoABarrelWall.h`).
- `Prefs/` contains Preferences bundle code and resources.
- `Prefs/Resources/` holds `Root.plist` and other preferences UI resources.
- `control` defines the package metadata.

## Code Style and Conventions

### General
- Language: Objective-C and Logos (`.m` and `.xm`).
- Use `#import`, not `#include`.
- Keep code ARC-friendly; Tweak is built with `-fobjc-arc`.
- Prefer early returns for guard conditions; avoid deep nesting.
- Use blank lines to separate logical blocks, matching existing files.
- Indentation matches existing files (tabs are common in this repo).

### Imports
- Put local headers first, then system/framework headers.
- Prefer module-style imports (e.g., `<UIKit/UIKit.h>`).
- Keep imports minimal; do not import unused frameworks.

### Naming
- Classes use PascalCase (`DBWRootListController`).
- Methods and variables use lowerCamelCase (`lockscreenEnabled`).
- Constants use `k` prefix for strings (`kPrefsIdentifier`).
- Macros are ALL_CAPS (`SYSTEM_VERSION_LESS_THAN`).
- Logos groups use clear names (`%group systemWallpaper`).

### Logos / Hooking
- Keep `%hook` blocks small and targeted.
- Always call `%orig` unless intentionally overriding behavior.
- Use `%group` and `%init` to scope hooks by runtime conditions.
- Avoid heavy work on the main thread; dispatch UI updates to main if needed.
- Prefer version guards via `SYSTEM_VERSION_LESS_THAN` when behavior differs.

### Preferences (Prefs bundle)
- Preferences are stored via `HBPreferences` with identifier `com.denial.doabarrelwallprefs`.
- For rootless paths in Prefs code, use `ROOT_PATH_NS(...)` (see `Prefs/DBWRootListController.m`).
- Use specifier-based UI patterns; rely on plist-driven specifiers.

### Formatting
- Brace style matches existing code: opening brace on same line, then a blank line.
- Keep line width readable; wrap long comments only when necessary.
- Prefer explicit type names over `id` when the type is known.
- Use `nil` for Objective-C objects, `NO/YES` for booleans.

### Types and Collections
- Prefer immutable types unless mutation is required (`NSArray` vs `NSMutableArray`).
- Use `NSUInteger` for counts and indexes.
- When storing images, use `NSCache` as in `Tweak/DoABarrelWall.h`.

### Error Handling and Safety
- Check for `nil` before use (e.g., image lookups).
- Guard against invalid array sizes before accessing indexes.
- When removing files, pass `error:nil` only if failure is non-critical.
- Avoid infinite loops when data can be empty; enforce minimum counts.

### Performance
- Cache images using `NSCache` and reuse where possible.
- Avoid repeated disk reads inside frequently called hooks.
- In hooks that run on scroll/appearance, exit early when no work is needed.

### Resource and Paths
- Wallpaper images live under `/var/mobile/Library/RotateWall` (runtime behavior).
- Preferences images use the libGcUniversal storage under the prefs identifier.
- Keep paths consistent with rootless scheme when writing from Prefs code.

## Behavior Expectations
- Tweak behavior depends on device orientation and lock/unlock events.
- Changes should be safe across iOS 12+ (use existing version checks).
- Ensure changes do not require respring unless explicitly intended.

## When Adding or Modifying Code
- Match existing tone and style of comments (casual, explanatory).
- Prefer small, localized changes; avoid refactors unless asked.
- Keep global variables organized in `Tweak/DoABarrelWall.h`.
- Any new preference keys should be registered in the tweak ctor.

## Files to Know
- `Tweak/Tweak.xm`: main hooks and wallpaper logic.
- `Tweak/DoABarrelWall.h`: globals and common includes.
- `Prefs/DBWRootListController.m`: settings UI and actions.
- `Makefile`, `Tweak/Makefile`, `Prefs/Makefile`: build configuration.
