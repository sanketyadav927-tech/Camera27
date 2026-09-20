//
//  Tweak.xm
//  Camera27
//
//  Logos hooks for Apple Camera.app (com.apple.camera) on iOS 16 (iPhone 8 Plus, arm64)
//

#import <UIKit/UIKit.h>
#import "CameraPrivateHeaders.h"
#import "Camera27UI.h"
#import "Camera27Settings.h"

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

    // Small delay ensures native layout subviews are finished configuring
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance] setupInViewController:self];
    });
}

- (void)viewWillLayoutSubviews {
    %orig;

    if (![Camera27Settings sharedSettings].enabled) return;

    [[Camera27UI sharedInstance] hideLegacyStockUI];
}

- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig;

    if (![Camera27Settings sharedSettings].enabled) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance] updateForCurrentMode:(CAMMode)mode animated:animated];
    });
}

- (void)setMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;

    if (![Camera27Settings sharedSettings].enabled) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance] updateForCurrentMode:(CAMMode)mode animated:animated];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;

    if (![Camera27Settings sharedSettings].enabled) return;

    [[Camera27UI sharedInstance] teardown];
}

%end

#pragma mark - Shutter / Recording State Synchronization

%hook CUShutterButton

- (void)setMode:(NSInteger)mode animated:(BOOL)animated {
    %orig;

    if (![Camera27Settings sharedSettings].enabled) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isVideo = (mode == 1 || mode == 2 || mode == 5);
        [[Camera27UI sharedInstance].shutterButton setIsVideoMode:isVideo animated:animated];
    });
}

- (void)setSpinning:(BOOL)spinning {
    %orig;

    if (![Camera27Settings sharedSettings].enabled) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[Camera27UI sharedInstance].shutterButton setRecording:spinning animated:YES];
    });
}

%end

#pragma mark - Constructor

%ctor {
    @autoreleasepool {
        // Ensure settings are initialized
        [Camera27Settings sharedSettings];
    }
}
