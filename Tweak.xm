//
//  Tweak.xm
//  Camera27
//
//  Logos hooks for Camera.app on iOS 16 (arm64, Rootless/Dopamine).
//  Uses ElleKit injection into com.apple.camera.
//
//  All hooks use respondsToSelector / isKindOfClass guards before casting.
//  Macro %orig always called to preserve native capture pipeline.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Headers/Camera27UI.h"
#import "Headers/Camera27Settings.h"
#import "Headers/CameraPrivateHeaders.h"

// ---------------------------------------------------------------------------
// MARK: - CAMViewfinderViewController
// ---------------------------------------------------------------------------

%hook CAMViewfinderViewController

- (void)viewDidLoad {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance] setupInViewController:self];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    [[Camera27UI sharedInstance] setupInViewController:self];
    [[Camera27UI sharedInstance] hideLegacyStockUI];
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    [[Camera27UI sharedInstance] hideLegacyStockUI];
}

// Sync mode changes initiated by the native pipeline
- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance] syncMode:(CAMMode)mode animated:animated];
    });
}

- (void)setMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance] syncMode:(CAMMode)mode animated:animated];
    });
}

%end

// ---------------------------------------------------------------------------
// MARK: - Suppress native bar layout to prevent UI reappearing
// ---------------------------------------------------------------------------

%hook CAMBottomBar

- (void)layoutSubviews {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    self.hidden = YES;
    self.alpha  = 0;
}

%end

%hook CAMTopBar

- (void)layoutSubviews {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    self.hidden = YES;
    self.alpha  = 0;
}

%end

// Also suppress any UIViewControllerWrapperView / container that might show legacy bars
%hook CAMControlDrawer

- (void)layoutSubviews {
    %orig;
    // Don't suppress the drawer itself — Camera27UI manually toggles it
}

%end

// ---------------------------------------------------------------------------
// MARK: - CUShutterButton visual hook (suppress native shutter ring)
// ---------------------------------------------------------------------------

%hook CUShutterButton

- (void)layoutSubviews {
    %orig;
    if (![Camera27Settings sharedSettings].enabled) return;
    self.hidden = YES;
    self.alpha  = 0;
}

%end

// ---------------------------------------------------------------------------
// MARK: - Ctor
// ---------------------------------------------------------------------------

%ctor {
    // Only inject into Camera.app
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.apple.camera"]) return;

    NSLog(@"[Camera27] Loaded into %@", bundleID);
    %init;
    [Camera27Settings sharedSettings];  // prime singleton
}
