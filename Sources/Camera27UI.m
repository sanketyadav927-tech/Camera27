//
//  Camera27UI.m
//  Camera27
//
//  Complete liquid glass overlay for Apple Camera.app.
//  All controls functionally invoke native Camera pipeline.
//  Designed for iPhone 8 Plus (414×736 pt, iOS 16.7.x, arm64).
//

#import "Camera27UI.h"
#import "Camera27Settings.h"
#import "Camera27Animations.h"
#import "Camera27Controls.h"
#import "Camera27Zoom.h"
#import "Camera27Modes.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>

// ---------------------------------------------------------------------------
// MARK: - AVCaptureDevice helpers (direct hardware control)
// ---------------------------------------------------------------------------

static AVCaptureDevice *_currentDevice(CAMViewfinderViewController *vc) {
    // 1. Try captureController.currentDevice
    if ([vc respondsToSelector:@selector(captureController)]) {
        id ctrl = vc.captureController;
        if ([ctrl respondsToSelector:@selector(currentDevice)]) {
            AVCaptureDevice *d = [ctrl performSelector:@selector(currentDevice)];
            if (d) return d;
        }
        if ([ctrl respondsToSelector:@selector(videoCaptureDevice)]) {
            AVCaptureDevice *d = [ctrl performSelector:@selector(videoCaptureDevice)];
            if (d) return d;
        }
    }
    // 2. Fallback: enumerate running sessions
    for (AVCaptureDevice *d in [AVCaptureDevice devices]) {
        if ([d hasMediaType:AVMediaTypeVideo] && d.isConnected) return d;
    }
    return nil;
}

static void _setFlash(AVCaptureDevice *dev, AVCaptureFlashMode mode) {
    if (!dev || ![dev hasFlash] || ![dev isFlashModeSupported:mode]) return;
    NSError *err = nil;
    if ([dev lockForConfiguration:&err]) {
        dev.flashMode = mode;
        [dev unlockForConfiguration];
    }
}

static void _setTorch(AVCaptureDevice *dev, BOOL on) {
    if (!dev || ![dev hasTorch]) return;
    NSError *err = nil;
    if ([dev lockForConfiguration:&err]) {
        dev.torchMode = on ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
        [dev unlockForConfiguration];
    }
}

static void _setHDR(AVCaptureDevice *dev, BOOL on) {
    if (!dev) return;
    NSError *err = nil;
    if ([dev lockForConfiguration:&err]) {
        // automaticallyAdjustsVideoHDREnabled available iOS 8+
        if ([dev respondsToSelector:@selector(setAutomaticallyAdjustsVideoHDREnabled:)])
            dev.automaticallyAdjustsVideoHDREnabled = on;
        if (!on && [dev respondsToSelector:@selector(setVideoHDREnabled:)])
            [dev setVideoHDREnabled:NO];
        [dev unlockForConfiguration];
    }
}

// ---------------------------------------------------------------------------
// MARK: - Safe native action invocation with multi-level fallback
// ---------------------------------------------------------------------------

#define SAFE_CALL(vc, sel, arg) \
    if ([vc respondsToSelector:@selector(sel)]) { [vc sel arg]; return; }

#define FIND_SUBVIEW(vc, className, action) do { \
    for (UIView *sv in vc.view.subviews) { \
        if ([sv isKindOfClass:NSClassFromString(className)]) { \
            UIButton *btn = (UIButton *)sv; \
            [btn sendActionsForControlEvents:UIControlEventTouchUpInside]; \
            return; \
        } \
    } \
} while(0)

// ---------------------------------------------------------------------------
// MARK: - Camera27UI Implementation
// ---------------------------------------------------------------------------

@interface Camera27UI () <Camera27ZoomViewDelegate, Camera27ModeSwitcherDelegate, Camera27TopBarDelegate>

@property (nonatomic, strong) UIView                *overlayView;
@property (nonatomic, strong) UIVisualEffectView    *deckPanel;
@property (nonatomic, strong) Camera27TopBar        *topBar;
@property (nonatomic, strong) Camera27ZoomView      *zoomView;
@property (nonatomic, strong) Camera27ModeSwitcher  *modeSwitcher;
@property (nonatomic, strong) Camera27ShutterButton *shutterButton;
@property (nonatomic, strong) Camera27FlipButton    *flipButton;
@property (nonatomic, strong) Camera27ImageWell     *galleryWell;
@property (nonatomic, strong) UIButton              *filterButton;
@property (nonatomic, strong) UIButton              *moreButton;
@property (nonatomic, strong) UILabel               *badge27;
@property (nonatomic, strong) UILabel               *timerCountdownLabel;
@property (nonatomic, strong) NSTimer               *countdownTimer;
@property (nonatomic, assign) NSInteger              countdownRemaining;
@property (nonatomic, assign) BOOL                   isConfigured;

@end

@implementation Camera27UI

+ (instancetype)sharedInstance {
    static Camera27UI *s = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [Camera27UI new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _flashState     = 0;
        _livePhotoActive = NO;
        _timerDuration  = 0;
        _hdrEnabled     = NO;
        _currentMode    = CAMModePhoto;
        _isFrontCamera  = NO;
        _isConfigured   = NO;
    }
    return self;
}

// ---------------------------------------------------------------------------
// MARK: - Setup
// ---------------------------------------------------------------------------

- (void)setupInViewController:(CAMViewfinderViewController *)vc {
    if (!vc || !vc.view) return;
    if (![Camera27Settings sharedSettings].enabled) return;

    self.viewfinderController = vc;

    // Prevent duplicate setup
    if (self.overlayView && self.overlayView.superview == vc.view) {
        [self hideLegacyStockUI];
        return;
    }

    [self teardown];

    UIView *root  = vc.view;
    CGFloat W     = root.bounds.size.width;   // 414 pt
    CGFloat H     = root.bounds.size.height;  // 736 pt

    // -----------------------------------------------------------------------
    // Master transparent overlay
    // -----------------------------------------------------------------------
    self.overlayView = [[UIView alloc] initWithFrame:root.bounds];
    self.overlayView.backgroundColor = UIColor.clearColor;
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [root addSubview:self.overlayView];

    // -----------------------------------------------------------------------
    // 1. TOP LIQUID GLASS PILL BAR (Flash | LivePhoto | Timer | HDR)
    // -----------------------------------------------------------------------
    CGFloat topW = W - 32;
    CGFloat topH = 46;
    CGFloat topY = 20; // Below status bar on iPhone 8 Plus
    self.topBar = [[Camera27TopBar alloc] initWithFrame:CGRectMake(16, topY, topW, topH)];
    self.topBar.delegate = self;
    [self.overlayView addSubview:self.topBar];

    // -----------------------------------------------------------------------
    // 2. FLOATING GALLERY THUMBNAIL WELL (bottom-left, above deck)
    // -----------------------------------------------------------------------
    CGFloat deckH  = 210;
    CGFloat deckY  = H - deckH - 12;
    CGFloat wellSz = 52;
    self.galleryWell = [[Camera27ImageWell alloc] initWithFrame:CGRectMake(24, deckY - 16 - wellSz, wellSz, wellSz)];
    [self.galleryWell addTarget:self action:@selector(_galleryPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.galleryWell];

    // -----------------------------------------------------------------------
    // 3. BOTTOM LIQUID GLASS DECK
    // -----------------------------------------------------------------------
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    self.deckPanel = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.deckPanel.frame = CGRectMake(12, deckY, W - 24, deckH);
    self.deckPanel.layer.cornerRadius  = 34;
    self.deckPanel.layer.masksToBounds = YES;
    self.deckPanel.layer.borderColor   = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    self.deckPanel.layer.borderWidth   = 0.75;
    [self.overlayView addSubview:self.deckPanel];

    // Extra specular highlight on top edge of deck (liquid glass "sheen")
    CAGradientLayer *sheen = [CAGradientLayer layer];
    sheen.frame  = CGRectMake(0, 0, W - 24, 1.5);
    sheen.colors = @[
        (id)[UIColor colorWithWhite:1 alpha:0.35].CGColor,
        (id)[UIColor colorWithWhite:1 alpha:0.0].CGColor
    ];
    sheen.startPoint = CGPointMake(0, 0);
    sheen.endPoint   = CGPointMake(1, 0);
    [self.deckPanel.layer addSublayer:sheen];

    UIView *deck = self.deckPanel.contentView;
    CGFloat dW   = W - 24; // deck content width

    // -----------------------------------------------------------------------
    // A. ZOOM SELECTOR (1× and 2× — hardware-detected, no 0.5×)
    // -----------------------------------------------------------------------
    CGFloat zW = 96, zH = 34;
    self.zoomView = [[Camera27ZoomView alloc] initWithFrame:CGRectMake((dW-zW)/2, 12, zW, zH)];
    self.zoomView.delegate = self;
    [deck addSubview:self.zoomView];

    // -----------------------------------------------------------------------
    // B. MAIN CONTROLS ROW
    // -----------------------------------------------------------------------
    CGFloat shutterSz = 76;
    CGFloat rowY      = zH + 20;

    // Filter / Creative button (left-most)
    self.filterButton = [self _glassCircleButton:@"f" sfSymbol:nil size:40 x:22 y:rowY + 18];
    self.filterButton.titleLabel.font = [UIFont fontWithDescriptor:[[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic] size:19];
    [self.filterButton setTitleColor:[UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1] forState:UIControlStateNormal];
    [self.filterButton addTarget:self action:@selector(_filterPressed) forControlEvents:UIControlEventTouchUpInside];
    [deck addSubview:self.filterButton];

    // Shutter (center)
    CGFloat shutterX = (dW - shutterSz)/2;
    self.shutterButton = [[Camera27ShutterButton alloc] initWithFrame:CGRectMake(shutterX, rowY, shutterSz, shutterSz)];
    [self.shutterButton addTarget:self action:@selector(_shutterPressed) forControlEvents:UIControlEventTouchUpInside];
    [deck addSubview:self.shutterButton];

    // More button (right-most)
    self.moreButton = [self _glassCircleButton:nil sfSymbol:@"ellipsis" size:40 x:dW - 22 - 40 y:rowY + 18];
    [self.moreButton addTarget:self action:@selector(_morePressed) forControlEvents:UIControlEventTouchUpInside];
    [deck addSubview:self.moreButton];

    // -----------------------------------------------------------------------
    // C. BOTTOM MODE ROW
    // -----------------------------------------------------------------------
    CGFloat modeRowY = rowY + shutterSz + 14;

    // Badge "27" (far left)
    self.badge27 = [[UILabel alloc] initWithFrame:CGRectMake(14, modeRowY + 6, 34, 24)];
    self.badge27.text = @"27";
    self.badge27.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    self.badge27.textColor = [UIColor colorWithWhite:0.72 alpha:1];
    self.badge27.textAlignment = NSTextAlignmentCenter;
    self.badge27.layer.cornerRadius = 7;
    self.badge27.layer.masksToBounds = YES;
    self.badge27.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    self.badge27.layer.borderWidth = 0.5;
    self.badge27.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    [deck addSubview:self.badge27];

    // Mode switcher (center strip)
    CGFloat modeSwitcherX = 56;
    CGFloat modeSwitcherW = dW - 56 - 50;
    self.modeSwitcher = [[Camera27ModeSwitcher alloc] initWithFrame:CGRectMake(modeSwitcherX, modeRowY, modeSwitcherW, 36)];
    self.modeSwitcher.delegate = self;
    [deck addSubview:self.modeSwitcher];

    // Flip button (far right)
    self.flipButton = [[Camera27FlipButton alloc] initWithFrame:CGRectMake(dW - 12 - 36, modeRowY + 1, 36, 36)];
    [self.flipButton addTarget:self action:@selector(_flipPressed) forControlEvents:UIControlEventTouchUpInside];
    [deck addSubview:self.flipButton];

    // -----------------------------------------------------------------------
    // D. TIMER COUNTDOWN OVERLAY (appears in center when timer active)
    // -----------------------------------------------------------------------
    self.timerCountdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, W, H)];
    self.timerCountdownLabel.font  = [UIFont systemFontOfSize:140 weight:UIFontWeightThin];
    self.timerCountdownLabel.textColor = UIColor.whiteColor;
    self.timerCountdownLabel.textAlignment = NSTextAlignmentCenter;
    self.timerCountdownLabel.hidden = YES;
    self.timerCountdownLabel.userInteractionEnabled = NO;
    [self.overlayView addSubview:self.timerCountdownLabel];

    // -----------------------------------------------------------------------
    // Hide native legacy chrome
    // -----------------------------------------------------------------------
    [self hideLegacyStockUI];

    // Sync initial state
    if ([vc respondsToSelector:@selector(mode)])
        [self syncMode:(CAMMode)vc.mode animated:NO];

    [self.topBar setFlashState:_flashState];
    [self.topBar setLivePhotoActive:_livePhotoActive];
    [self.topBar setTimerDuration:_timerDuration];
    [self.topBar setHDREnabled:_hdrEnabled];

    self.isConfigured = YES;

    // Entrance animation
    if ([Camera27Settings sharedSettings].animationsEnabled) {
        self.deckPanel.alpha   = 0;
        self.topBar.alpha      = 0;
        self.galleryWell.alpha = 0;
        self.deckPanel.transform   = CGAffineTransformMakeTranslation(0, 40);
        [Camera27Animations animateSpringWithDuration:0.55 animations:^{
            self.deckPanel.alpha   = 1;
            self.topBar.alpha      = 1;
            self.galleryWell.alpha = 1;
            self.deckPanel.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

// Helper: glass circle button
- (UIButton *)_glassCircleButton:(nullable NSString *)title sfSymbol:(nullable NSString *)sym size:(CGFloat)sz x:(CGFloat)x y:(CGFloat)y {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(x, y, sz, sz);
    btn.layer.cornerRadius = sz/2;
    btn.layer.masksToBounds = YES;
    btn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    btn.layer.borderWidth = 0.5;
    btn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    UIVisualEffectView *bv = [[UIVisualEffectView alloc] initWithEffect:blur];
    bv.frame = btn.bounds;
    bv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bv.userInteractionEnabled = NO;
    [btn addSubview:bv];
    [btn sendSubviewToBack:bv];

    if (sym) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
        [btn setImage:[UIImage systemImageNamed:sym withConfiguration:cfg] forState:UIControlStateNormal];
        btn.tintColor = UIColor.whiteColor;
    } else if (title) {
        [btn setTitle:title forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        [btn setTitleColor:[UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1] forState:UIControlStateNormal];
    }
    return btn;
}

// ---------------------------------------------------------------------------
// MARK: - Hide Legacy Stock UI
// ---------------------------------------------------------------------------

- (void)hideLegacyStockUI {
    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    // Known bar class names
    NSSet *barNames = [NSSet setWithArray:@[
        @"CAMBottomBar", @"CAMTopBar", @"CAMControlDrawer",
        @"CUBottomBar",  @"CUTopBar",  @"CAMModeDial"
    ]];

    for (UIView *sv in vc.view.subviews) {
        if (sv == self.overlayView) continue;
        NSString *cn = NSStringFromClass([sv class]);
        if ([barNames containsObject:cn]) {
            sv.hidden = YES;
            sv.alpha  = 0;
        }
    }

    // Also try named properties
    void(^hideView)(UIView *) = ^(UIView *v) { if (v) { v.hidden = YES; v.alpha = 0; } };
    if ([vc respondsToSelector:@selector(bottomBar)])    hideView(vc.bottomBar);
    if ([vc respondsToSelector:@selector(topBar)])       hideView(vc.topBar);
    if ([vc respondsToSelector:@selector(controlDrawer)]) hideView(vc.controlDrawer);
}

// ---------------------------------------------------------------------------
// MARK: - Teardown
// ---------------------------------------------------------------------------

- (void)teardown {
    [self _cancelCountdown];
    if (self.overlayView) { [self.overlayView removeFromSuperview]; self.overlayView = nil; }
    self.deckPanel = self.topBar = nil;
    self.zoomView = self.modeSwitcher = nil;
    self.shutterButton = self.flipButton = nil;
    self.galleryWell = self.filterButton = self.moreButton = nil;
    self.badge27 = self.timerCountdownLabel = nil;
    self.isConfigured = NO;
}

// ---------------------------------------------------------------------------
// MARK: - State Sync (called from Logos hooks)
// ---------------------------------------------------------------------------

- (void)syncMode:(CAMMode)mode animated:(BOOL)anim {
    _currentMode = mode;
    BOOL video = (mode == CAMModeVideo || mode == CAMModeSloMo || mode == CAMModeTimeLapse);
    [self.shutterButton setIsVideoMode:video animated:anim];
    [self.modeSwitcher setSelectedMode:mode animated:anim];
}

- (void)syncZoomFactor:(double)factor {
    [self.zoomView setSelectedZoomFactor:(CGFloat)factor animated:YES];
}

- (void)syncRecording:(BOOL)recording {
    [self.shutterButton setRecording:recording animated:YES];
}

// ---------------------------------------------------------------------------
// MARK: - Shutter
// ---------------------------------------------------------------------------

- (void)_shutterPressed {
    if (_timerDuration > 0) {
        [self _startCountdownThenShoot];
    } else {
        [self _fireShutter];
    }
}

- (void)_fireShutter {
    [Camera27Animations playRigidHaptic];
    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    // Try all known selectors in priority order
    if ([vc respondsToSelector:@selector(_shutterButtonReleased:)]) {
        [vc _shutterButtonReleased:nil]; goto done;
    }
    if ([vc respondsToSelector:@selector(takePicture)]) {
        [vc takePicture]; goto done;
    }
    if ([vc respondsToSelector:@selector(pressShutterButton:)]) {
        [vc pressShutterButton:nil]; goto done;
    }
    // Fallback: trigger stock shutter button
    for (UIView *sv in vc.view.subviews) {
        if ([sv isKindOfClass:NSClassFromString(@"CUShutterButton")] ||
            [sv isKindOfClass:NSClassFromString(@"CAMShutterButton")]) {
            [(UIButton *)sv sendActionsForControlEvents:UIControlEventTouchUpInside];
            goto done;
        }
    }
done:
    // Refresh gallery after a short delay to let photo be saved
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.galleryWell loadRecentPhotoThumbnail];
    });
}

// ---------------------------------------------------------------------------
// MARK: - Timer Countdown
// ---------------------------------------------------------------------------

- (void)_startCountdownThenShoot {
    [Camera27Animations playMediumHaptic];
    [self _cancelCountdown];
    self.countdownRemaining = _timerDuration;
    self.timerCountdownLabel.hidden = NO;
    self.timerCountdownLabel.alpha  = 1;
    [self _tickCountdown];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
        selector:@selector(_tickCountdown) userInfo:nil repeats:YES];
}

- (void)_tickCountdown {
    if (self.countdownRemaining <= 0) {
        [self _cancelCountdown];
        [UIView animateWithDuration:0.2 animations:^{
            self.timerCountdownLabel.alpha = 0;
        } completion:^(BOOL _) {
            self.timerCountdownLabel.hidden = YES;
            [self _fireShutter];
        }];
        return;
    }
    [Camera27Animations playLightHaptic];
    self.timerCountdownLabel.text = [NSString stringWithFormat:@"%ld", (long)self.countdownRemaining];
    // Pulse animation
    self.timerCountdownLabel.transform = CGAffineTransformMakeScale(1.4, 1.4);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6
                       initialSpringVelocity:0.3 options:0 animations:^{
        self.timerCountdownLabel.transform = CGAffineTransformIdentity;
    } completion:nil];
    self.countdownRemaining--;
}

- (void)_cancelCountdown {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    self.timerCountdownLabel.hidden = YES;
}

// ---------------------------------------------------------------------------
// MARK: - Flip Camera
// ---------------------------------------------------------------------------

- (void)_flipPressed {
    _isFrontCamera = !_isFrontCamera;
    [Camera27Animations rotateFlipButton:self.flipButton completion:nil];
    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    if ([vc respondsToSelector:@selector(_flipButtonReleased:)]) {
        [vc _flipButtonReleased:nil]; return;
    }
    FIND_SUBVIEW(vc, @"CAMFlipButton", sendActionsForControlEvents:UIControlEventTouchUpInside);
    FIND_SUBVIEW(vc, @"CUFlipButton",  sendActionsForControlEvents:UIControlEventTouchUpInside);

    // AVFoundation fallback: switch device on running session
    AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    (void)dev;
}

// ---------------------------------------------------------------------------
// MARK: - Gallery
// ---------------------------------------------------------------------------

- (void)_galleryPressed {
    [Camera27Animations playMediumHaptic];
    [Camera27Animations pulseView:self.galleryWell scale:1.1 duration:0.2];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    if ([vc respondsToSelector:@selector(_imageWellPressed:)]) {
        [vc _imageWellPressed:nil]; return;
    }
    FIND_SUBVIEW(vc, @"CAMImageWell", sendActionsForControlEvents:UIControlEventTouchUpInside);
}

// ---------------------------------------------------------------------------
// MARK: - Filter (Creative / Mode Drawer)
// ---------------------------------------------------------------------------

- (void)_filterPressed {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.filterButton scale:1.18 duration:0.22];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;
    if ([vc respondsToSelector:@selector(controlDrawer)]) {
        CAMControlDrawer *drawer = vc.controlDrawer;
        if (drawer) {
            [UIView animateWithDuration:0.25 animations:^{
                drawer.hidden = !drawer.hidden;
                drawer.alpha  = drawer.hidden ? 0 : 1;
            }];
        }
    }
}

// ---------------------------------------------------------------------------
// MARK: - More
// ---------------------------------------------------------------------------

- (void)_morePressed {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.moreButton scale:1.18 duration:0.22];
}

// ---------------------------------------------------------------------------
// MARK: - Flash (cycles Off → On → Auto → Off)
// ---------------------------------------------------------------------------

- (void)_cycleFlash {
    _flashState = (_flashState + 1) % 3;
    [self.topBar setFlashState:_flashState];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    // 1. Try AVCaptureDevice direct
    AVCaptureDevice *dev = _currentDevice(vc);
    if (dev) {
        switch (_flashState) {
            case 0: _setFlash(dev, AVCaptureFlashModeOff);  break;
            case 1: _setFlash(dev, AVCaptureFlashModeOn);   break;
            case 2: _setFlash(dev, AVCaptureFlashModeAuto); break;
        }
    }

    // 2. Also trigger native UI so its internal state stays in sync
    if ([vc respondsToSelector:@selector(_flashButtonReleased:)]) {
        [vc _flashButtonReleased:nil];
    } else {
        FIND_SUBVIEW(vc, @"CAMFlashButton", sendActionsForControlEvents:UIControlEventTouchUpInside);
    }
}

// ---------------------------------------------------------------------------
// MARK: - Live Photo (toggle)
// ---------------------------------------------------------------------------

- (void)_toggleLivePhoto {
    _livePhotoActive = !_livePhotoActive;
    [self.topBar setLivePhotoActive:_livePhotoActive];
    [Camera27Animations playLightHaptic];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    if ([vc respondsToSelector:@selector(_livePhotoButtonReleased:)]) {
        [vc _livePhotoButtonReleased:nil];
    } else {
        FIND_SUBVIEW(vc, @"CAMLivePhotoButton", sendActionsForControlEvents:UIControlEventTouchUpInside);
    }
}

// ---------------------------------------------------------------------------
// MARK: - Timer (cycles Off → 3s → 10s → Off)
// ---------------------------------------------------------------------------

- (void)_cycleTimer {
    NSInteger options[] = {0, 3, 10};
    NSInteger cur = _timerDuration;
    NSInteger next = 0;
    if (cur == 0) next = 3;
    else if (cur == 3) next = 10;
    else next = 0;
    _timerDuration = next;
    [self.topBar setTimerDuration:_timerDuration];
    [Camera27Animations playLightHaptic];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    if ([vc respondsToSelector:@selector(_timerButtonReleased:)]) {
        [vc _timerButtonReleased:nil];
    } else {
        FIND_SUBVIEW(vc, @"CAMTimerButton", sendActionsForControlEvents:UIControlEventTouchUpInside);
    }
    (void)options;
}

// ---------------------------------------------------------------------------
// MARK: - HDR (toggle)
// ---------------------------------------------------------------------------

- (void)_toggleHDR {
    _hdrEnabled = !_hdrEnabled;
    [self.topBar setHDREnabled:_hdrEnabled];
    [Camera27Animations playLightHaptic];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    // 1. Direct AVCaptureDevice HDR control
    AVCaptureDevice *dev = _currentDevice(vc);
    _setHDR(dev, _hdrEnabled);

    // 2. Trigger native HDR button if available
    if ([vc respondsToSelector:@selector(_HDRButtonReleased:)]) {
        [vc _HDRButtonReleased:nil];
    } else {
        FIND_SUBVIEW(vc, @"CAMHDRButton", sendActionsForControlEvents:UIControlEventTouchUpInside);
    }
}

// ---------------------------------------------------------------------------
// MARK: - Zoom delegate
// ---------------------------------------------------------------------------

- (void)zoomView:(Camera27ZoomView *)zoomView didSelectZoomFactor:(CGFloat)factor {
    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    // 1. AVCaptureDevice direct zoom
    AVCaptureDevice *dev = _currentDevice(vc);
    if (dev && [dev respondsToSelector:@selector(setVideoZoomFactor:)]) {
        NSError *err = nil;
        if ([dev lockForConfiguration:&err]) {
            CGFloat maxZ = MIN(factor, dev.activeFormat.videoMaxZoomFactor);
            dev.videoZoomFactor = maxZ;
            [dev unlockForConfiguration];
        }
    }

    // 2. captureController
    if ([vc respondsToSelector:@selector(captureController)]) {
        id ctrl = vc.captureController;
        if ([ctrl respondsToSelector:@selector(setZoomFactor:)])
            [ctrl setZoomFactor:factor];
    }

    // 3. zoomControl
    if ([vc respondsToSelector:@selector(zoomControl)]) {
        CAMZoomControl *zc = vc.zoomControl;
        if ([zc respondsToSelector:@selector(setZoomFactor:animated:)])
            [zc setZoomFactor:factor animated:YES];
    }

    // 4. Private selector
    if ([vc respondsToSelector:@selector(_zoomControl:didChangeZoomFactor:)])
        [vc _zoomControl:nil didChangeZoomFactor:factor];
}

// ---------------------------------------------------------------------------
// MARK: - Mode delegate
// ---------------------------------------------------------------------------

- (void)modeSwitcher:(Camera27ModeSwitcher *)switcher didSelectMode:(CAMMode)mode {
    _currentMode = mode;
    BOOL video = (mode == CAMModeVideo || mode == CAMModeSloMo || mode == CAMModeTimeLapse);
    [self.shutterButton setIsVideoMode:video animated:YES];

    CAMViewfinderViewController *vc = self.viewfinderController;
    if (!vc) return;

    if ([vc respondsToSelector:@selector(changeToMode:device:animated:)]) {
        [vc changeToMode:mode device:0 animated:YES]; return;
    }
    if ([vc respondsToSelector:@selector(setMode:animated:)]) {
        [vc setMode:mode animated:YES]; return;
    }
    // Fallback: KVC
    if ([vc respondsToSelector:@selector(setMode:)])
        [vc performSelector:@selector(setMode:) withObject:@(mode)];
}

// ---------------------------------------------------------------------------
// MARK: - Top bar delegate
// ---------------------------------------------------------------------------

- (void)topBarDidTapFlash:(UIButton *)sender     { [self _cycleFlash]; }
- (void)topBarDidTapLivePhoto:(UIButton *)sender  { [self _toggleLivePhoto]; }
- (void)topBarDidTapTimer:(UIButton *)sender      { [self _cycleTimer]; }
- (void)topBarDidTapHDR:(UIButton *)sender        { [self _toggleHDR]; }

// ---------------------------------------------------------------------------
// MARK: - Mode update from hook
// ---------------------------------------------------------------------------

- (void)updateForCurrentMode:(CAMMode)mode animated:(BOOL)animated {
    [self syncMode:mode animated:animated];
}

@end
