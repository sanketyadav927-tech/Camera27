//
//  Camera27Controls.m
//  Camera27
//
//  All control widgets with functional native invocation.
//

#import "Camera27Controls.h"
#import "Camera27Animations.h"
#import "Camera27Settings.h"
#import <Photos/Photos.h>
#import <objc/runtime.h>

// ---------------------------------------------------------------------------
// MARK: - Liquid Glass helper
// ---------------------------------------------------------------------------

static UIVisualEffectView *C27MakeLiquidGlass(CGRect frame, CGFloat cornerRadius) {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:blur];
    v.frame = frame;
    v.layer.cornerRadius = cornerRadius;
    v.layer.masksToBounds = YES;
    // Subtle glow border
    v.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    v.layer.borderWidth  = 0.75;
    return v;
}

// ---------------------------------------------------------------------------
// MARK: - Camera27ShutterButton
// ---------------------------------------------------------------------------

@interface Camera27ShutterButton ()
@property (nonatomic, strong) UIView *outerRing;
@property (nonatomic, strong) UIView *innerCore;
@property (nonatomic, strong) CALayer *glowLayer;
@end

@implementation Camera27ShutterButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { _recording = NO; _isVideoMode = NO; [self _build]; }
    return self;
}

- (void)_build {
    self.backgroundColor = UIColor.clearColor;
    CGFloat sz = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat ox = (self.bounds.size.width - sz)/2, oy = (self.bounds.size.height - sz)/2;

    // Outer ring
    self.outerRing = [[UIView alloc] initWithFrame:CGRectMake(ox, oy, sz, sz)];
    self.outerRing.layer.cornerRadius  = sz / 2;
    self.outerRing.layer.borderWidth   = 3.5;
    self.outerRing.layer.borderColor   = UIColor.whiteColor.CGColor;
    self.outerRing.backgroundColor     = UIColor.clearColor;
    self.outerRing.userInteractionEnabled = NO;
    [self addSubview:self.outerRing];

    // Liquid glass glow on outer ring
    self.glowLayer = [CALayer layer];
    self.glowLayer.frame = self.outerRing.bounds;
    self.glowLayer.cornerRadius = sz / 2;
    self.glowLayer.shadowColor  = UIColor.whiteColor.CGColor;
    self.glowLayer.shadowOffset = CGSizeZero;
    self.glowLayer.shadowRadius = 8;
    self.glowLayer.shadowOpacity = 0.35;
    [self.outerRing.layer addSublayer:self.glowLayer];

    // Inner core
    CGFloat inSz = sz - 14;
    self.innerCore = [[UIView alloc] initWithFrame:CGRectMake((sz-inSz)/2, (sz-inSz)/2, inSz, inSz)];
    self.innerCore.layer.cornerRadius = inSz / 2;
    self.innerCore.backgroundColor    = UIColor.whiteColor;
    self.innerCore.userInteractionEnabled = NO;
    [self.outerRing addSubview:self.innerCore];

    [self addTarget:self action:@selector(_down) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(_up)   forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
}

- (void)_down {
    [Camera27Animations playRigidHaptic];
    [Camera27Animations animateSpringWithDuration:0.18 animations:^{
        self.innerCore.transform = CGAffineTransformMakeScale(0.86, 0.86);
        self.outerRing.transform = CGAffineTransformMakeScale(1.07, 1.07);
    } completion:nil];
}

- (void)_up {
    [Camera27Animations animateSpringWithDuration:0.26 animations:^{
        self.innerCore.transform = CGAffineTransformIdentity;
        self.outerRing.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setIsVideoMode:(BOOL)v animated:(BOOL)anim {
    _isVideoMode = v;
    void(^upd)(void) = ^{ self.innerCore.backgroundColor = v ? UIColor.systemRedColor : UIColor.whiteColor; };
    anim ? [UIView animateWithDuration:0.22 animations:upd] : upd();
}

- (void)setRecording:(BOOL)rec animated:(BOOL)anim {
    _recording = rec;
    CGFloat sz = self.outerRing.bounds.size.width;
    void(^upd)(void) = ^{
        if (rec) {
            CGFloat sq = sz * 0.40;
            self.innerCore.frame = CGRectMake((sz-sq)/2,(sz-sq)/2, sq, sq);
            self.innerCore.layer.cornerRadius = 6;
            self.innerCore.backgroundColor = UIColor.systemRedColor;
        } else {
            CGFloat inSz = sz - 14;
            self.innerCore.frame = CGRectMake((sz-inSz)/2,(sz-inSz)/2, inSz, inSz);
            self.innerCore.layer.cornerRadius = inSz/2;
            self.innerCore.backgroundColor = self.isVideoMode ? UIColor.systemRedColor : UIColor.whiteColor;
        }
    };
    anim ? [Camera27Animations animateSpringWithDuration:0.32 animations:upd completion:nil] : upd();
}

@end

// ---------------------------------------------------------------------------
// MARK: - Camera27FlipButton
// ---------------------------------------------------------------------------

@implementation Camera27FlipButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self _build]; }
    return self;
}

- (void)_build {
    CGFloat r = MIN(self.bounds.size.width, self.bounds.size.height)/2;
    UIVisualEffectView *glass = C27MakeLiquidGlass(self.bounds, r);
    [self addSubview:glass];
    [self sendSubviewToBack:glass];

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
    UIImage *icon = [UIImage systemImageNamed:@"camera.rotate.fill" withConfiguration:cfg]
                 ?: [UIImage systemImageNamed:@"arrow.triangle.2.circlepath" withConfiguration:cfg];
    [self setImage:icon forState:UIControlStateNormal];
    self.tintColor = UIColor.whiteColor;
}

@end

// ---------------------------------------------------------------------------
// MARK: - Camera27ImageWell
// ---------------------------------------------------------------------------

@interface Camera27ImageWell ()
@property (nonatomic, strong, readwrite) UIImageView *thumbnailImageView;
@end

@implementation Camera27ImageWell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self _build]; [self loadRecentPhotoThumbnail]; }
    return self;
}

- (void)_build {
    self.layer.cornerRadius  = 10;
    self.layer.masksToBounds = YES;
    self.layer.borderColor   = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    self.layer.borderWidth   = 1.5;
    self.backgroundColor     = [UIColor colorWithWhite:0.08 alpha:1];

    self.thumbnailImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    self.thumbnailImageView.userInteractionEnabled = NO;
    [self addSubview:self.thumbnailImageView];
}

- (void)setThumbnailImage:(UIImage *_Nullable)image animated:(BOOL)anim {
    if (anim) {
        [UIView transitionWithView:self.thumbnailImageView duration:0.22
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ self.thumbnailImageView.image = image; } completion:nil];
    } else {
        self.thumbnailImageView.image = image;
    }
}

- (void)loadRecentPhotoThumbnail {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) return;

    PHFetchOptions *opts = [PHFetchOptions new];
    opts.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    opts.fetchLimit = 1;

    PHFetchResult<PHAsset *> *r = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:opts];
    if (!r.firstObject) return;

    PHImageRequestOptions *iOpts = [PHImageRequestOptions new];
    iOpts.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    iOpts.resizeMode   = PHImageRequestOptionsResizeModeExact;
    iOpts.networkAccessAllowed = NO;
    CGFloat scale = UIScreen.mainScreen.scale;
    CGSize target = CGSizeMake(self.bounds.size.width * scale * 2, self.bounds.size.height * scale * 2);

    [[PHImageManager defaultManager] requestImageForAsset:r.firstObject targetSize:target
        contentMode:PHImageContentModeAspectFill options:iOpts
        resultHandler:^(UIImage *img, NSDictionary *info) {
            if (img) dispatch_async(dispatch_get_main_queue(), ^{ [self setThumbnailImage:img animated:YES]; });
        }];
}

@end

// ---------------------------------------------------------------------------
// MARK: - Camera27TopBar
// ---------------------------------------------------------------------------

@interface Camera27TopBar () {
    NSInteger _c27FlashState;
    BOOL      _c27LiveActive;
    NSInteger _c27TimerSec;
    BOOL      _c27HdrOn;
}
@property (nonatomic, strong, readwrite) UIButton *flashButton;
@property (nonatomic, strong, readwrite) UIButton *livePhotoButton;
@property (nonatomic, strong, readwrite) UIButton *timerButton;
@property (nonatomic, strong, readwrite) UIButton *hdrButton;
@property (nonatomic, strong, readwrite) UILabel  *statusBadge;
@property (nonatomic, strong) UIVisualEffectView  *glass;
@end

@implementation Camera27TopBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self _build]; }
    return self;
}

- (void)_build {
    self.backgroundColor = UIColor.clearColor;
    CGFloat r = self.bounds.size.height / 2.0;

    self.glass = C27MakeLiquidGlass(self.bounds, r);
    [self addSubview:self.glass];

    CGFloat h = self.bounds.size.height;
    CGFloat bW = h + 4;
    CGFloat x = 8;

    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];

    // Flash button
    self.flashButton = [self _topBtn:[UIImage systemImageNamed:@"bolt.slash.fill"]
                               frame:CGRectMake(x, 0, bW, h) tint:UIColor.whiteColor];
    [self.flashButton addTarget:self action:@selector(_flashTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.flashButton];
    x += bW + 4;

    // Live Photo button
    self.livePhotoButton = [self _topBtn:[UIImage systemImageNamed:@"livephoto"]
                                   frame:CGRectMake(x, 0, bW, h) tint:UIColor.whiteColor];
    [self.livePhotoButton addTarget:self action:@selector(_liveTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.livePhotoButton];
    x += bW + 4;

    // Timer button
    self.timerButton = [self _topBtn:[UIImage systemImageNamed:@"timer"]
                               frame:CGRectMake(x, 0, bW, h) tint:UIColor.whiteColor];
    [self.timerButton addTarget:self action:@selector(_timerTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.timerButton];
    x += bW + 4;

    // HDR button
    self.hdrButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hdrButton.frame = CGRectMake(x, 0, bW + 8, h);
    [self.hdrButton setTitle:@"HDR" forState:UIControlStateNormal];
    self.hdrButton.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.hdrButton setTitleColor:[UIColor colorWithWhite:0.75 alpha:1] forState:UIControlStateNormal];
    [self.hdrButton addTarget:self action:@selector(_hdrTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.hdrButton];

    // Badge label right-aligned
    self.statusBadge = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - 90, 0, 82, h)];
    self.statusBadge.text = @"Camera27";
    self.statusBadge.font = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold];
    self.statusBadge.textColor = [UIColor colorWithWhite:0.75 alpha:0.8];
    self.statusBadge.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.statusBadge];

    (void)gold; // used in state updates below
}

- (UIButton *)_topBtn:(UIImage *)img frame:(CGRect)frame tint:(UIColor *)tint {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
    [btn setImage:[img imageByApplyingSymbolConfiguration:cfg] forState:UIControlStateNormal];
    btn.tintColor = tint;
    return btn;
}

// ------ State cycling tap handlers ------
- (void)_flashTap {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.flashButton scale:1.18 duration:0.22];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapFlash:)])
        [self.delegate topBarDidTapFlash:self.flashButton];
}
- (void)_liveTap {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.livePhotoButton scale:1.18 duration:0.22];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapLivePhoto:)])
        [self.delegate topBarDidTapLivePhoto:self.livePhotoButton];
}
- (void)_timerTap {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.timerButton scale:1.18 duration:0.22];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapTimer:)])
        [self.delegate topBarDidTapTimer:self.timerButton];
}
- (void)_hdrTap {
    [Camera27Animations playLightHaptic];
    [Camera27Animations pulseView:self.hdrButton scale:1.18 duration:0.22];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapHDR:)])
        [self.delegate topBarDidTapHDR:self.hdrButton];
}

// ------ Visual state updates ------
- (void)setFlashState:(NSInteger)state {
    _c27FlashState = state;
    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
    NSString *iconName;
    UIColor *tint;
    if (state == 1)      { iconName = @"bolt.fill";       tint = gold; }
    else if (state == 2) { iconName = @"bolt.badge.a.fill"; tint = gold; }
    else                 { iconName = @"bolt.slash.fill";  tint = UIColor.whiteColor; }
    [self.flashButton setImage:[[UIImage systemImageNamed:iconName] imageByApplyingSymbolConfiguration:cfg] forState:UIControlStateNormal];
    self.flashButton.tintColor = tint;
}

- (void)setLivePhotoActive:(BOOL)active {
    _c27LiveActive = active;
    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    self.livePhotoButton.tintColor = active ? gold : UIColor.whiteColor;
    if (active) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
        [self.livePhotoButton setImage:[[UIImage systemImageNamed:@"livephoto"] imageByApplyingSymbolConfiguration:cfg] forState:UIControlStateNormal];
    }
}

- (void)setTimerDuration:(NSInteger)seconds {
    _c27TimerSec = seconds;
    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    self.timerButton.tintColor = seconds > 0 ? gold : UIColor.whiteColor;
    NSString *badge = seconds > 0 ? [NSString stringWithFormat:@"%lds", (long)seconds] : nil;
    // Show timer duration as overlay label
    UILabel *lbl = [self viewWithTag:9991];
    if (!lbl && badge) {
        lbl = [[UILabel alloc] initWithFrame:CGRectMake(self.timerButton.frame.origin.x + self.timerButton.bounds.size.width - 14,
                                                         self.timerButton.frame.size.height - 13, 14, 13)];
        lbl.tag = 9991;
        lbl.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = gold;
        [self addSubview:lbl];
    }
    lbl.text = badge;
    lbl.hidden = (badge == nil);
}

- (void)setHDREnabled:(BOOL)enabled {
    _c27HdrOn = enabled;
    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    [self.hdrButton setTitleColor:enabled ? gold : [UIColor colorWithWhite:0.75 alpha:1] forState:UIControlStateNormal];
}

@end
