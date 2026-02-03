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
- For isolated verification, use `make -C Tweak install` or `make -C Prefs install` and reproduce the scenario on-device.

Notes:
- Root Makefile sets `THEOS_PACKAGE_SCHEME = rootless` by default.
- Target platform is configured in the root `Makefile`.
- No formatter or lint config is present; do not introduce one unless asked.
- If you add a new preference key, update the default registration in the tweak ctor.

Deployment and debugging:
- Install builds with `make install` and test on-device.
- Preference changes are intended to apply without respring unless explicitly triggered.
- Runtime images are written under `/var/mobile/Library/RotateWall` by the tweak.

## Project Layout

- `Tweak/` contains Logos hooks and tweak logic (`Tweak.xm`, `RotateWall.h`).
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
- Prefer concise method bodies over large helper classes; keep logic close to hooks.

### Imports
- Put local headers first, then system/framework headers.
- Prefer module-style imports (e.g., `<UIKit/UIKit.h>`).
- Keep imports minimal; do not import unused frameworks.
- Avoid importing private headers unless the existing code already uses them.

### Naming
- Classes use PascalCase (`DBWRootListController`).
- Methods and variables use lowerCamelCase (`lockscreenEnabled`).
- Constants use `k` prefix for strings (`kPrefsIdentifier`).
- Macros are ALL_CAPS (`SYSTEM_VERSION_LESS_THAN`).
- Logos groups use clear names (`%group systemWallpaper`).
- Preference keys are lowerCamelCase and stored in HBPreferences.

### Logos / Hooking
- Keep `%hook` blocks small and targeted.
- Always call `%orig` unless intentionally overriding behavior.
- Use `%group` and `%init` to scope hooks by runtime conditions.
- Avoid heavy work on the main thread; dispatch UI updates to main if needed.
- Prefer version guards via `SYSTEM_VERSION_LESS_THAN` when behavior differs.
- Guard hooks with preference flags to avoid unnecessary work when disabled.

### Preferences (Prefs bundle)
- Preferences are stored via `HBPreferences` with identifier `com.denial.doabarrelwallprefs`.
- For rootless paths in Prefs code, use `ROOT_PATH_NS(...)` (see `Prefs/DBWRootListController.m`).
- Use specifier-based UI patterns; rely on plist-driven specifiers.
- Keep UI actions in the controller and avoid business logic in specifier plist.

### Formatting
- Brace style matches existing code: opening brace on same line, then a blank line.
- Keep line width readable; wrap long comments only when necessary.
- Prefer explicit type names over `id` when the type is known.
- Use `nil` for Objective-C objects, `NO/YES` for booleans.
- Use `static` for file-local helpers/constants.

### Types and Collections
- Prefer immutable types unless mutation is required (`NSArray` vs `NSMutableArray`).
- Use `NSUInteger` for counts and indexes.
- When storing images, use `NSCache` as in `Tweak/RotateWall.h`.
- Use `NSArray<UIImage *> *` style generics where it clarifies the API.

### Error Handling and Safety
- Check for `nil` before use (e.g., image lookups).
- Guard against invalid array sizes before accessing indexes.
- When removing files, pass `error:nil` only if failure is non-critical.
- Avoid infinite loops when data can be empty; enforce minimum counts.
- Treat file I/O failures as non-fatal unless they block user-facing behavior.

### Performance
- Cache images using `NSCache` and reuse where possible.
- Avoid repeated disk reads inside frequently called hooks.
- In hooks that run on scroll/appearance, exit early when no work is needed.
- Avoid synchronous file I/O on the main thread.

### Resource and Paths
- Wallpaper images live under `/var/mobile/Library/RotateWall` (runtime behavior).
- Preferences images are referenced by full file paths stored in prefs.
- Keep paths consistent with rootless scheme when writing from Prefs code.
- Do not hardcode non-rootless paths in Prefs.

## Behavior Expectations
- Tweak behavior depends on device orientation and lock/unlock events.
- Changes should be safe across iOS 12+ (use existing version checks).
- Ensure changes do not require respring unless explicitly intended.
- Preference toggles should take effect without rebooting SpringBoard.

## When Adding or Modifying Code
- Match existing tone and style of comments (casual, explanatory).
- Prefer small, localized changes; avoid refactors unless asked.
- Keep global variables organized in `Tweak/RotateWall.h`.
- Any new preference keys should be registered in the tweak ctor.
- Avoid introducing new third-party dependencies.

## Files to Know
- `Tweak/Tweak.xm`: main hooks and wallpaper logic.
- `Tweak/RotateWall.h`: globals and common includes.
- `Prefs/DBWRootListController.m`: settings UI and actions.
- `Makefile`, `Tweak/Makefile`, `Prefs/Makefile`: build configuration.
