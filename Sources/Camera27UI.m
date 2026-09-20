//
//  Camera27UI.m
//  Camera27
//
//  Master overlay manager and container for Camera27 interface.
//  Designed for iPhone 8 Plus (414 x 736 pt, iOS 16.7.16).
//

#import "Camera27UI.h"
#import "Camera27Settings.h"
#import "Camera27Animations.h"
#import <objc/runtime.h>

@interface Camera27UI ()
@property (nonatomic, assign) BOOL isConfigured;
@end

@implementation Camera27UI

+ (instancetype)sharedInstance {
    static Camera27UI *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Camera27UI alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isConfigured = NO;
    }
    return self;
}

- (void)setupInViewController:(CAMViewfinderViewController *)viewController {
    if (!viewController || !viewController.view) return;
    if (![Camera27Settings sharedSettings].enabled) return;

    self.viewfinderController = viewController;

    // Prevent duplicate overlays
    if (self.overlayContainerView && self.overlayContainerView.superview == viewController.view) {
        [self hideLegacyStockUI];
        return;
    }

    [self teardown];

    CGRect screenBounds = viewController.view.bounds;
    CGFloat screenWidth = screenBounds.size.width;
    CGFloat screenHeight = screenBounds.size.height;

    // Master overlay container
    self.overlayContainerView = [[UIView alloc] initWithFrame:screenBounds];
    self.overlayContainerView.backgroundColor = [UIColor clearColor];
    self.overlayContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayContainerView.userInteractionEnabled = YES;

    // 1. Top Glass Pill Bar
    CGFloat topBarWidth = screenWidth - 32.0;
    CGFloat topBarHeight = 44.0;
    CGFloat topBarY = 28.0; // Respect status bar area on iPhone 8 Plus
    self.topBar = [[Camera27TopBar alloc] initWithFrame:CGRectMake(16.0, topBarY, topBarWidth, topBarHeight)];
    self.topBar.delegate = self;
    [self.overlayContainerView addSubview:self.topBar];

    // 2. Bottom Glass Deck Panel
    CGFloat deckWidth = screenWidth - 32.0;
    CGFloat deckHeight = 186.0;
    CGFloat deckY = screenHeight - deckHeight - 20.0; // Floating above bottom edge
    
    self.bottomGlassPanel = [[UIVisualEffectView alloc] init];
    self.bottomGlassPanel.frame = CGRectMake(16.0, deckY, deckWidth, deckHeight);
    self.bottomGlassPanel.layer.cornerRadius = 28.0;
    self.bottomGlassPanel.layer.masksToBounds = YES;
    self.bottomGlassPanel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    self.bottomGlassPanel.layer.borderWidth = 0.5;

    if ([Camera27Settings sharedSettings].glassUIEnabled) {
        self.bottomGlassPanel.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    } else {
        self.bottomGlassPanel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    }
    [self.overlayContainerView addSubview:self.bottomGlassPanel];

    UIView *deckContent = self.bottomGlassPanel.contentView;

    // A. Zoom Selector (1× and 2× only for iPhone 8 Plus)
    CGFloat zoomWidth = 88.0;
    CGFloat zoomHeight = 32.0;
    CGFloat zoomX = (deckWidth - zoomWidth) / 2.0;
    self.zoomView = [[Camera27ZoomView alloc] initWithFrame:CGRectMake(zoomX, 10.0, zoomWidth, zoomHeight)];
    self.zoomView.delegate = self;
    [deckContent addSubview:self.zoomView];

    // B. Shutter Button (Center)
    CGFloat shutterSize = 70.0;
    CGFloat shutterX = (deckWidth - shutterSize) / 2.0;
    CGFloat shutterY = 52.0;
    self.shutterButton = [[Camera27ShutterButton alloc] initWithFrame:CGRectMake(shutterX, shutterY, shutterSize, shutterSize)];
    [self.shutterButton addTarget:self action:@selector(handleShutterPressed) forControlEvents:UIControlEventTouchUpInside];
    [deckContent addSubview:self.shutterButton];

    // C. Filter / Creative Button ("f") on Left
    self.filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.filterButton.frame = CGRectMake(32.0, shutterY + 15.0, 40.0, 40.0);
    self.filterButton.layer.cornerRadius = 20.0;
    self.filterButton.layer.borderWidth = 0.5;
    self.filterButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    self.filterButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
    [self.filterButton setTitle:@"f" forState:UIControlStateNormal];
    self.filterButton.titleLabel.font = [UIFont italicSystemFontOfSize:18.0];
    [self.filterButton setTitleColor:[UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0] forState:UIControlStateNormal];
    [self.filterButton addTarget:self action:@selector(handleFilterPressed) forControlEvents:UIControlEventTouchUpInside];
    [deckContent addSubview:self.filterButton];

    // D. More Options Button ("...") on Right
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.moreButton.frame = CGRectMake(deckWidth - 32.0 - 40.0, shutterY + 15.0, 40.0, 40.0);
    self.moreButton.layer.cornerRadius = 20.0;
    self.moreButton.layer.borderWidth = 0.5;
    self.moreButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    self.moreButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
    UIImageSymbolConfiguration *moreCfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold];
    [self.moreButton setImage:[UIImage systemImageNamed:@"ellipsis" withConfiguration:moreCfg] forState:UIControlStateNormal];
    self.moreButton.tintColor = [UIColor whiteColor];
    [self.moreButton addTarget:self action:@selector(handleMorePressed) forControlEvents:UIControlEventTouchUpInside];
    [deckContent addSubview:self.moreButton];

    // E. Badge "27" (Bottom Left)
    self.badge27 = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 140.0, 32.0, 32.0)];
    self.badge27.layer.cornerRadius = 16.0;
    self.badge27.layer.masksToBounds = YES;
    self.badge27.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    self.badge27.layer.borderWidth = 0.5;
    self.badge27.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.6];
    self.badge27.text = @"27";
    self.badge27.textColor = [UIColor whiteColor];
    self.badge27.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    self.badge27.textAlignment = NSTextAlignmentCenter;
    [deckContent addSubview:self.badge27];

    // F. Mode Switcher (Bottom Center)
    CGFloat modeWidth = deckWidth - 110.0;
    self.modeSwitcher = [[Camera27ModeSwitcher alloc] initWithFrame:CGRectMake(54.0, 138.0, modeWidth, 36.0)];
    self.modeSwitcher.delegate = self;
    [deckContent addSubview:self.modeSwitcher];

    // G. Camera Flip Button (Bottom Right)
    self.flipButton = [[Camera27FlipButton alloc] initWithFrame:CGRectMake(deckWidth - 16.0 - 34.0, 139.0, 34.0, 34.0)];
    [self.flipButton addTarget:self action:@selector(handleFlipPressed) forControlEvents:UIControlEventTouchUpInside];
    [deckContent addSubview:self.flipButton];

    // 3. Floating Photo Library Thumbnail Well
    // Positioned gracefully above the deck on the bottom left
    self.galleryWell = [[Camera27ImageWell alloc] initWithFrame:CGRectMake(20.0, deckY - 58.0, 48.0, 48.0)];
    [self.galleryWell addTarget:self action:@selector(handleGalleryPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayContainerView addSubview:self.galleryWell];

    // Attach overlay to native Camera view controller
    [viewController.view addSubview:self.overlayContainerView];

    // Hide native legacy chrome
    [self hideLegacyStockUI];

    // Sync initial mode
    if ([viewController respondsToSelector:@selector(mode)]) {
        [self updateForCurrentMode:(CAMMode)[viewController mode] animated:NO];
    }

    self.isConfigured = YES;
}

- (void)hideLegacyStockUI {
    if (!self.viewfinderController) return;

    CAMViewfinderViewController *vc = self.viewfinderController;

    // Gracefully hide bottom bar
    if ([vc respondsToSelector:@selector(bottomBar)]) {
        UIView *bottomBar = vc.bottomBar;
        if (bottomBar) {
            bottomBar.alpha = 0.0;
            bottomBar.hidden = YES;
        }
    }

    // Gracefully hide top bar
    if ([vc respondsToSelector:@selector(topBar)]) {
        UIView *topBar = vc.topBar;
        if (topBar) {
            topBar.alpha = 0.0;
            topBar.hidden = YES;
        }
    }

    // Gracefully hide drawer
    if ([vc respondsToSelector:@selector(controlDrawer)]) {
        UIView *drawer = vc.controlDrawer;
        if (drawer) {
            drawer.alpha = 0.0;
            drawer.hidden = YES;
        }
    }

    // Search subviews defensively for any residual legacy bars
    for (UIView *subview in vc.view.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className isEqualToString:@"CAMBottomBar"] ||
            [className isEqualToString:@"CAMTopBar"] ||
            [className isEqualToString:@"CAMControlDrawer"]) {
            subview.alpha = 0.0;
            subview.hidden = YES;
        }
    }
}

- (void)teardown {
    if (self.overlayContainerView) {
        [self.overlayContainerView removeFromSuperview];
        self.overlayContainerView = nil;
    }
    self.isConfigured = NO;
}

- (void)updateForCurrentMode:(CAMMode)mode animated:(BOOL)animated {
    BOOL isVideo = (mode == CAMModeVideo || mode == CAMModeSloMo || mode == CAMModeTimeLapse);
    [self.shutterButton setIsVideoMode:isVideo animated:animated];
    [self.modeSwitcher setSelectedMode:mode animated:animated];
}

#pragma mark - Action Handlers (Defensive Native Invocation)

- (void)handleShutterPressed {
    [Camera27Animations playRigidHaptic];

    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    // 1. Direct native method invocation if present
    if ([vc respondsToSelector:@selector(takePicture)]) {
        [vc takePicture];
        [self.galleryWell loadRecentPhotoThumbnail];
        return;
    }

    if ([vc respondsToSelector:@selector(pressShutterButton:)]) {
        [vc pressShutterButton:nil];
        [self.galleryWell loadRecentPhotoThumbnail];
        return;
    }

    if ([vc respondsToSelector:@selector(_shutterButtonReleased:)]) {
        [vc _shutterButtonReleased:nil];
        [self.galleryWell loadRecentPhotoThumbnail];
        return;
    }

    // 2. Fallback: trigger stock shutter button control events
    UIButton *stockShutter = nil;
    if ([vc respondsToSelector:@selector(shutterButton)]) {
        stockShutter = (UIButton *)vc.shutterButton;
    }

    if (!stockShutter) {
        // Recursive subview scan for stock shutter button
        for (UIView *subview in vc.view.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"CUShutterButton")] ||
                [subview isKindOfClass:NSClassFromString(@"CAMShutterButton")]) {
                stockShutter = (UIButton *)subview;
                break;
            }
        }
    }

    if (stockShutter) {
        [stockShutter sendActionsForControlEvents:UIControlEventTouchUpInside];
        [self.galleryWell loadRecentPhotoThumbnail];
    }
}

- (void)handleFlipPressed {
    [Camera27Animations rotateFlipButton:self.flipButton completion:nil];

    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    // 1. Direct method invocation
    if ([vc respondsToSelector:@selector(_flipButtonReleased:)]) {
        [vc _flipButtonReleased:nil];
        return;
    }

    // 2. Fallback: trigger stock flip button
    UIButton *stockFlip = nil;
    if ([vc respondsToSelector:@selector(flipButton)]) {
        stockFlip = (UIButton *)vc.flipButton;
    }

    if (!stockFlip) {
        for (UIView *subview in vc.view.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"CAMFlipButton")]) {
                stockFlip = (UIButton *)subview;
                break;
            }
        }
    }

    if (stockFlip) {
        [stockFlip sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)handleGalleryPressed {
    [Camera27Animations playMediumHaptic];

    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    // 1. Direct method invocation
    if ([vc respondsToSelector:@selector(_imageWellPressed:)]) {
        [vc _imageWellPressed:nil];
        return;
    }

    // 2. Fallback: trigger stock image well
    UIButton *stockWell = nil;
    if ([vc respondsToSelector:@selector(imageWell)]) {
        stockWell = (UIButton *)vc.imageWell;
    }

    if (!stockWell) {
        for (UIView *subview in vc.view.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"CAMImageWell")]) {
                stockWell = (UIButton *)subview;
                break;
            }
        }
    }

    if (stockWell) {
        [stockWell sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)handleFilterPressed {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.filterButton scale:1.15 duration:0.25];
    
    // Toggle native creative control drawer or filter mode
    if ([self.viewfinderController respondsToSelector:@selector(controlDrawer)]) {
        UIView *drawer = self.viewfinderController.controlDrawer;
        if (drawer) {
            drawer.hidden = NO;
            drawer.alpha = (drawer.alpha > 0.0) ? 0.0 : 1.0;
        }
    }
}

- (void)handleMorePressed {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.moreButton scale:1.15 duration:0.25];
}

#pragma mark - Camera27ZoomViewDelegate

- (void)zoomView:(Camera27ZoomView *)zoomView didSelectZoomFactor:(CGFloat)zoomFactor {
    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    // 1. Use captureController if available
    if ([vc respondsToSelector:@selector(captureController)]) {
        CAMCaptureController *ctrl = vc.captureController;
        if ([ctrl respondsToSelector:@selector(setZoomFactor:)]) {
            [ctrl setZoomFactor:zoomFactor];
            return;
        }
    }

    // 2. Use zoomControl if available
    if ([vc respondsToSelector:@selector(zoomControl)]) {
        CAMZoomControl *zoomControl = vc.zoomControl;
        if ([zoomControl respondsToSelector:@selector(setZoomFactor:animated:)]) {
            [zoomControl setZoomFactor:zoomFactor animated:YES];
            return;
        }
    }

    // 3. Fallback method invocation
    if ([vc respondsToSelector:@selector(_zoomControl:didChangeZoomFactor:)]) {
        [vc _zoomControl:nil didChangeZoomFactor:zoomFactor];
    }
}

#pragma mark - Camera27ModeSwitcherDelegate

- (void)modeSwitcher:(Camera27ModeSwitcher *)modeSwitcher didSelectMode:(CAMMode)mode {
    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    [self updateForCurrentMode:mode animated:YES];

    // 1. Direct mode change
    if ([vc respondsToSelector:@selector(changeToMode:device:animated:)]) {
        [vc changeToMode:mode device:0 animated:YES];
        return;
    }

    if ([vc respondsToSelector:@selector(setMode:animated:)]) {
        [vc setMode:mode animated:YES];
        return;
    }

    if ([vc respondsToSelector:@selector(setMode:)]) {
        [vc setMode:mode];
        return;
    }
}

#pragma mark - Camera27TopBarDelegate

- (void)topBarDidTapFlash:(UIButton *)sender {
    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    if ([vc respondsToSelector:@selector(_flashButtonReleased:)]) {
        [vc _flashButtonReleased:sender];
        return;
    }

    if ([vc respondsToSelector:@selector(flashButton)]) {
        UIButton *stockFlash = (UIButton *)vc.flashButton;
        if (stockFlash) {
            [stockFlash sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)topBarDidTapLivePhoto:(UIButton *)sender {
    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    if ([vc respondsToSelector:@selector(_livePhotoButtonReleased:)]) {
        [vc _livePhotoButtonReleased:sender];
        return;
    }

    if ([vc respondsToSelector:@selector(livePhotoButton)]) {
        UIButton *stockLive = (UIButton *)vc.livePhotoButton;
        if (stockLive) {
            [stockLive sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)topBarDidTapTimer:(UIButton *)sender {
    if (!self.viewfinderController) return;
    CAMViewfinderViewController *vc = self.viewfinderController;

    if ([vc respondsToSelector:@selector(_timerButtonReleased:)]) {
        [vc _timerButtonReleased:sender];
        return;
    }

    if ([vc respondsToSelector:@selector(timerButton)]) {
        UIButton *stockTimer = (UIButton *)vc.timerButton;
        if (stockTimer) {
            [stockTimer sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

@end
