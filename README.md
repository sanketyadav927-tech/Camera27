# Camera27

> **Modern iOS 27-Inspired Camera Replacement UI for iOS 16**  
> *Targeted for iPhone 8 Plus (iOS 16.0 – 16.7.16) on Rootless Dopamine Jailbreak with ElleKit.*

---

## Table of Contents
1. [Overview](#overview)
2. [Hardware Specifications & Target Details](#hardware-specifications--target-details)
3. [Features & UI Design](#features--ui-design)
4. [Architecture & Project Structure](#architecture--project-structure)
5. [Hooking Architecture & Explanations](#hooking-architecture--explanations)
6. [Preferences System](#preferences-system)
7. [Building on Windows via GitHub Actions](#building-on-windows-via-github-actions)
8. [Building Locally (macOS / Linux / WSL)](#building-locally-macos--linux--wsl)
9. [Installation Guide (Sileo / Filza / CLI)](#installation-guide-sileo--filza--cli)
10. [Troubleshooting & Debugging](#troubleshooting--debugging)

---

## 1. Overview

**Camera27** is an open-source, rootless jailbreak tweak that transforms Apple's stock `Camera.app` on **iOS 16** into a sleek, futuristic, iOS 27-inspired glassmorphic interface.

Unlike standalone toy camera apps, **Camera27 directly hooks Apple's native `CameraUI.framework`** and AVFoundation capture pipeline inside `com.apple.camera`. It hides the stock legacy chrome while preserving native autofocus, autoexposure, zero shutter lag, HDR processing, optical lens switching, and photo library integration.

---

## 2. Hardware Specifications & Target Details

| Parameter | Specification |
|---|---|
| **Target Device** | iPhone 8 Plus (A11 Bionic, `arm64`) |
| **Supported OS** | iOS 16.0 – 16.7.16 |
| **Jailbreak** | Dopamine 2.x / palera1n (Rootless) |
| **Hooking Engine** | ElleKit / CydiaSubstrate |
| **Rear Wide Lens** | 12 MP, ƒ/1.8 (1× Optical) |
| **Rear Telephoto Lens** | 12 MP, ƒ/2.8 (2× Optical) |
| **Ultra Wide Lens (0.5×)**| **NOT PRESENT ON HARDWARE** — 0.5× is strictly disabled |
| **Display Resolution** | 414 × 736 pt (1080 × 1920 px physical, 3× Retina) |

> [!IMPORTANT]
> The iPhone 8 Plus only has 1× and 2× optical cameras. Camera27 explicitly detects available hardware lenses and displays a clean **1×  2×** zoom selector, preventing nonexistent 0.5× lenses from appearing.

---

## 3. Features & UI Design

### Glassmorphic Bottom Control Deck
- **Modern Zoom Selector**: Capsule switch toggling between **1×** (Wide) and **2×** (Telephoto) with spring-animated selection bubble and haptics.
- **Concentric Shutter Button**: 70×70 pt precision control. The inner core pulses on touch-down and transforms into a rounded red square when recording video.
- **Creative Filter Button (`f`)**: Golden italic monogram allowing quick toggle of creative filters/lighting styles.
- **Action Drawer Button (`...`)**: Modern ellipsis button for fine-grained camera adjustments.
- **Camera27 Identity Badge (`27`)**: Custom frosted glass badge.
- **Horizontal Mode Dial**: Smooth scrolling strip supporting all native iPhone 8 Plus camera modes:
  - `PHOTO` (Native capture)
  - `PORTRAIT` (Dual-camera depth capture)
  - `VIDEO` (60fps 4K/1080p recording)
  - `SLO-MO` (240fps high frame rate)
  - `TIME-LAPSE` (Dynamic interval capture)
  - `PANO` (Panoramic stitching)
- **3D Rotating Camera Flip**: Circular button with 180° Y-axis perspective flip animation toggling between front FaceTime camera and rear dual cameras.
- **Real-Time Photo Library Well**: Displays the latest photo from your library using `PHAsset` / Photos framework with cross-dissolve updates.

### Top Floating Navigation Pill
- **Flash Control**: Cycles between Off, On, and Auto with dynamic gold indicator icons.
- **Live Photo Control**: Yellow burst indicator toggle for Live Photo capture.
- **Timer Control**: 3s, 10s, and Off toggle with countdown indication.
- **Status Indicator**: Minimalist Camera27 status label.

---

## 4. Architecture & Project Structure

```
Camera27/
├── Makefile                                    # Theos rootless configuration
├── control                                     # Debian package control (iphoneos-arm64)
├── Camera27.plist                              # Filter targeting com.apple.camera
├── Tweak.xm                                    # Core Logos hooks into CAMViewfinderViewController
├── Headers/
│   ├── CameraPrivateHeaders.h                  # Private CameraUI declarations for iOS 16
│   ├── Camera27UI.h                            # Master UI overlay container
│   ├── Camera27Controls.h                      # Shutter, Flip, Gallery Well, Top Bar
│   ├── Camera27Modes.h                         # Mode selector carousel
│   ├── Camera27Zoom.h                          # 1× and 2× zoom capsule
│   ├── Camera27Settings.h                      # Rootless preferences manager
│   └── Camera27Animations.h                   # Fluid animations and haptic engine
├── Sources/
│   ├── Camera27UI.m                            # Overlay layout and native fallback invocation
│   ├── Camera27Controls.m                      # Controls rendering and touch handling
│   ├── Camera27Modes.m                         # Mode strip calculation and centering
│   ├── Camera27Zoom.m                          # Hardware lens detection and zoom switching
│   ├── Camera27Settings.m                      # Plist loader and Darwin notification listener
│   └── Camera27Animations.m                   # Springs, pulses, and haptic generators
├── Resources/
│   ├── Info.plist                              # Tweak bundle metadata
│   └── Camera27Settings.bundle/
│       ├── Info.plist                          # Settings bundle info
│       └── Root.plist                          # Preference specifiers
├── layout/
│   └── Library/
│       └── PreferenceLoader/
│           └── Preferences/
│               └── Camera27.plist              # PreferenceLoader registration
├── .github/
│   └── workflows/
│       └── build.yml                           # Ubuntu CI workflow to produce .deb
└── README.md                                   # Comprehensive documentation
```

---

## 5. Hooking Architecture & Explanations

### Hook 1: `CAMViewfinderViewController`
`CAMViewfinderViewController` is the root view controller managing the viewfinder in iOS 16's `CameraUI.framework`.
- **`viewDidLoad` & `viewDidAppear:`**: 
  - Attaches `Camera27UI` overlay cleanly over the viewfinder view hierarchy.
  - Calls `hideLegacyStockUI` to set `alpha = 0` / `hidden = YES` on the stock `CAMBottomBar`, `CAMTopBar`, and `CAMControlDrawer`.
  - Leaves the native views in the view tree so tap-to-focus and AVFoundation pipelines remain intact.
- **`viewWillLayoutSubviews`**: Ensures legacy bars stay hidden whenever native Camera.app triggers internal subview layouts.
- **`changeToMode:device:animated:` & `setMode:animated:`**: Synchronizes Camera27's mode dial and shutter styling whenever a mode transition occurs.
- **`viewWillDisappear:`**: Destroys overlays to release memory and avoid retain cycles when Camera.app is suspended.

### Hook 2: `CUShutterButton`
`CUShutterButton` is the underlying control used by Apple for shutter events.
- **`setMode:animated:`**: Detects whether the active mode is Video or Photo to style the inner core red or white.
- **`setSpinning:`**: Tracks whether video recording is active and animates the inner shutter core between a circle and a rounded red square.

### Defensive Fallback Invocation Strategy
If Apple refactors an internal method name across sub-versions of iOS 16:
1. `Camera27UI` checks `respondsToSelector:` before calling any private method (`takePicture`, `_flipButtonReleased:`, etc.).
2. If the selector is missing or uncallable, it automatically traverses the view hierarchy to find the corresponding stock button (`CUShutterButton`, `CAMFlipButton`, `CAMImageWell`, `CAMFlashButton`) and executes:
   ```objc
   [stockButton sendActionsForControlEvents:UIControlEventTouchUpInside];
   ```
   This guarantees that stock events fire regardless of Apple's private method naming!

---

## 6. Preferences System

Settings can be customized directly in the native **Settings.app -> Camera27**:
- **Enable Camera27**: Master toggle switch.
- **Enable Glass UI**: Toggles `UIVisualEffectView` blur or dark solid background.
- **Smooth Animations**: Toggles spring animations and 3D rotations.
- **Haptic Feedback**: Toggles tactile feedback on buttons and mode dial.
- **Appearance Theme**: Dark Glass, Light Glass, or System appearance.

Preferences are stored in rootless storage:
`/var/jb/Library/Preferences/com.yourname.camera27.plist`

Changes take effect dynamically in real time via Darwin notification:
`com.yourname.camera27.prefschanged`

---

## 7. Building on Windows via GitHub Actions

Since you are developing on **Windows without a local Ubuntu setup**, an automated **GitHub Actions CI/CD pipeline** is included in `.github/workflows/build.yml`.

### Step-by-Step Build & Download:
1. Initialize a git repository and commit your files:
   ```powershell
   git init
   git add .
   git commit -m "Initial commit of Camera27"
   ```
2. Create a new GitHub repository and push your project:
   ```powershell
   git branch -M main
   git remote add origin https://github.com/<your-username>/Camera27.git
   git push -u origin main
   ```
3. Open GitHub in your web browser:
   - Go to your repository's **Actions** tab.
   - You will see the **Build Camera27 Rootless .deb** workflow running.
4. When the workflow completes (~2 minutes):
   - Click on the completed workflow run.
   - Scroll down to the **Artifacts** section.
   - Download **`Camera27-rootless`** (contains `Camera27-rootless.deb`).

---

## 8. Building Locally (macOS / Linux / WSL)

If you have a Linux machine, macOS, or WSL with Theos installed:

```bash
# 1. Set environment
export THEOS=~/theos
export THEOS_PACKAGE_SCHEME=rootless

# 2. Navigate to project
cd Camera27

# 3. Compile and build .deb package
make clean
make package FINALPACKAGE=1

# Output is located at:
# packages/com.yourname.camera27_1.0.0_iphoneos-arm64.deb
```

---

## 9. Installation Guide (Sileo / Filza / CLI)

### Method A: Direct Install via Sileo / Filza (Recommended)
1. AirDrop or transfer `Camera27-rootless.deb` to your iPhone 8 Plus.
2. Open the file with **Filza** or share it directly into **Sileo**.
3. In Sileo:
   - Tap **Get** or **Install**.
   - Tap **Confirm** to complete installation.
4. Restart Camera.app (or run `killall -9 Camera`).

### Method B: Install via SSH / Terminal
```bash
# Copy .deb to device
scp packages/*.deb root@<DEVICE_IP>:/var/jb/var/mobile/

# SSH into device
ssh root@<DEVICE_IP>

# Install debian package
dpkg -i /var/jb/var/mobile/com.yourname.camera27_1.0.0_iphoneos-arm64.deb

# Kill Camera process to reload tweak
killall -9 Camera
```

---

## 10. Troubleshooting & Debugging

- **Camera.app crashes on launch**:
  - Verify that ElleKit is updated to the latest version in Sileo.
  - Verify that the package was compiled with `THEOS_PACKAGE_SCHEME=rootless` and architecture `iphoneos-arm64`.
- **Legacy UI is still visible**:
  - Ensure **Enable Camera27** is toggled ON in Settings.
  - In Settings -> Camera27, toggle the master switch OFF and ON.
- **View Debug Logs**:
  - Connect your iPhone 8 Plus or use `oslog`:
    ```bash
    oslog | grep Camera27
    ```
- **Safe Mode**:
  - If you encounter an issue, boot into Dopamine without tweaks, open Sileo, uninstall Camera27, and re-jailbreak with tweaks enabled.

---

## License
MIT License. Crafted for the iOS jailbreak community.
