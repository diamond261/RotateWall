# RotateWall

RotateWall is a jailbreak tweak for iPadOS 16.1.1 that switches wallpapers based on device orientation.(based on DoABarrelWall)

## Features

- Portrait orientation uses Wallpaper A.
- Landscape orientation uses Wallpaper B.
- Separate images for Lock Screen and Home Screen.
- Optional fade transition.
- Settings pane with Photos picker.
- Rootless-friendly paths.

## Requirements

- iPadOS 16.1.1
- Jailbreak: palera1n or XinaA15
- Theos toolchain

## Build and Install

```sh
make package
make install
```

If you need a clean rebuild:

```sh
make clean && make
```

## Usage

1. Open Settings.
2. Tap RotateWall.
3. Select portrait and landscape images for Lock and Home.
4. Rotate the device to apply.

## Notes

- Images are stored under `/var/mobile/Library/RotateWall`.
- Preference changes are applied without respring.
- If wallpaper updates fail on your device, enable logging and share logs.

## License

See `LICENSE`.
