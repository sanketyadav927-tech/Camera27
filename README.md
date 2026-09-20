# Camera27

Camera27 is a rootless, arm64 Camera.app UI replacement for iPhone 8 Plus on iOS 16.7.16 with Dopamine and ElleKit. It leaves Apple's capture pipeline and preview intact while presenting a dark glass control surface with a shutter, gallery, flip, flash, Live Photo, timer, 1x/2x selector, and mode strip.

## Runtime-first integration

There are no compiled CameraUI private class declarations or hard-coded private method calls. At launch, the tweak searches the live Camera.app hierarchy for the actual shutter, camera-switch, and gallery controls. It activates only when all three are found, then hides their verified control chrome before attaching Camera27. This avoids the old overlay-plus-stock-controls failure mode.

Each custom action relays to the discovered native `UIControl`, preserving Camera.app's capture, recording, camera-switch, flash, Live Photo, timer, and photo-library behavior. Mode changes are only relayed to a live native mode control whose label or accessibility metadata matches. Zoom is offered as `1x` and `2x` only; `2x` is disabled unless AVFoundation finds a telephoto device. Camera27 never displays `0.5x`.

The first successful attachment writes a concise controller/control report with the `[Camera27]` prefix. Capture it on the target device when adapting to a Camera.app revision:

```sh
log stream --level debug --predicate 'eventMessage CONTAINS "Camera27"'
```

If a stock control does not expose recognizable metadata on a specific iOS build, Camera27 deliberately leaves the stock UI intact and reports the hierarchy. Do not add class names or selectors from guesswork; use that report to make a narrowly verified matcher.

## Build

Pushes to `main` run `.github/workflows/build.yml` on Ubuntu. The workflow installs Theos and SDKs, builds an arm64 rootless package, verifies its control archive and dylib path, and uploads `Camera27-rootless.deb`.

For a local Theos environment:

```sh
make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

The resulting package is under `packages/`.

## Install and recovery

Install the Actions artifact in Sileo, then force-close Camera. The master switch is in Settings > Camera27. If Camera fails to launch, disable the switch or boot Dopamine with tweaks disabled, uninstall `com.sanketyadav927.camera27`, and re-jailbreak.

## Scope

The injection filter contains only `com.apple.camera`. The project targets iOS 16.0+ arm64; the layout dynamically uses bounds and safe-area insets, with the iPhone 8 Plus portrait view as the design target.
