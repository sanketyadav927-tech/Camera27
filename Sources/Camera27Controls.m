//
//  Camera27Controls.m
//  Camera27
//
//  Modern glassmorphic controls: Shutter, Flip, Gallery, and Top Nav Pill.
//

#import "Camera27Controls.h"
#import "Camera27Animations.h"
#import "Camera27Settings.h"
#import <Photos/Photos.h>

#pragma mark - Camera27ShutterButton

@interface Camera27ShutterButton ()
@property (nonatomic, strong) UIView *outerRing;
@property (nonatomic, strong) UIView *innerCore;
@end

@implementation Camera27ShutterButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _recording = NO;
        _isVideoMode = NO;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];

    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    CGRect centeredBounds = CGRectMake((self.bounds.size.width - size) / 2.0, (self.bounds.size.height - size) / 2.0, size, size);

    // Outer concentric ring
    self.outerRing = [[UIView alloc] initWithFrame:centeredBounds];
    self.outerRing.layer.cornerRadius = size / 2.0;
    self.outerRing.layer.borderWidth = 3.5;
    self.outerRing.layer.borderColor = [UIColor whiteColor].CGColor;
    self.outerRing.userInteractionEnabled = NO;
    [self addSubview:self.outerRing];

    // Inner core
    CGFloat innerSize = size - 14.0;
    self.innerCore = [[UIView alloc] initWithFrame:CGRectMake((size - innerSize) / 2.0, (size - innerSize) / 2.0, innerSize, innerSize)];
    self.innerCore.layer.cornerRadius = innerSize / 2.0;
    self.innerCore.backgroundColor = [UIColor whiteColor];
    self.innerCore.userInteractionEnabled = NO;
    [self.outerRing addSubview:self.innerCore];

    [self addTarget:self action:@selector(handleTouchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(handleTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
}

- (void)handleTouchDown {
    [Camera27Animations playRigidHaptic];
    [Camera27Animations animateSpringWithDuration:0.2 animations:^{
        self.innerCore.transform = CGAffineTransformMakeScale(0.88, 0.88);
        self.outerRing.transform = CGAffineTransformMakeScale(1.06, 1.06);
    } completion:nil];
}

- (void)handleTouchUp {
    [Camera27Animations animateSpringWithDuration:0.25 animations:^{
        self.innerCore.transform = CGAffineTransformIdentity;
        self.outerRing.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setIsVideoMode:(BOOL)isVideoMode animated:(BOOL)animated {
    _isVideoMode = isVideoMode;
    void (^updateColor)(void) = ^{
        if (self.isVideoMode) {
            self.innerCore.backgroundColor = [UIColor systemRedColor];
        } else {
            self.innerCore.backgroundColor = [UIColor whiteColor];
        }
    };

    if (animated) {
        [UIView animateWithDuration:0.25 animations:updateColor];
    } else {
        updateColor();
    }
}

- (void)setRecording:(BOOL)recording animated:(BOOL)animated {
    _recording = recording;
    CGFloat size = self.outerRing.bounds.size.width;

    void (^updateRecordingState)(void) = ^{
        if (self.recording) {
            CGFloat squareSize = size * 0.42;
            self.innerCore.frame = CGRectMake((size - squareSize) / 2.0, (size - squareSize) / 2.0, squareSize, squareSize);
            self.innerCore.layer.cornerRadius = 6.0;
            self.innerCore.backgroundColor = [UIColor systemRedColor];
        } else {
            CGFloat innerSize = size - 14.0;
            self.innerCore.frame = CGRectMake((size - innerSize) / 2.0, (size - innerSize) / 2.0, innerSize, innerSize);
            self.innerCore.layer.cornerRadius = innerSize / 2.0;
            self.innerCore.backgroundColor = self.isVideoMode ? [UIColor systemRedColor] : [UIColor whiteColor];
        }
    };

    if (animated) {
        [Camera27Animations animateSpringWithDuration:0.35 animations:updateRecordingState completion:nil];
    } else {
        updateRecordingState();
    }
}

@end

#pragma mark - Camera27FlipButton

@implementation Camera27FlipButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    self.layer.borderWidth = 0.5;

    if ([Camera27Settings sharedSettings].glassUIEnabled) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = self.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurView.userInteractionEnabled = NO;
        [self addSubview:blurView];
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    }

    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
    UIImage *icon = [UIImage systemImageNamed:@"camera.rotate" withConfiguration:config];
    if (!icon) {
        icon = [UIImage systemImageNamed:@"arrow.triangle.2.circlepath" withConfiguration:config];
    }
    [self setImage:icon forState:UIControlStateNormal];
    self.tintColor = [UIColor whiteColor];
}

@end

#pragma mark - Camera27ImageWell

@interface Camera27ImageWell ()
@property (nonatomic, strong, readwrite) UIImageView *thumbnailImageView;
@end

@implementation Camera27ImageWell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self loadRecentPhotoThumbnail];
    }
    return self;
}

- (void)setupUI {
    self.layer.cornerRadius = 10.0;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.4].CGColor;
    self.layer.borderWidth = 1.0;
    self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];

    self.thumbnailImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    self.thumbnailImageView.userInteractionEnabled = NO;
    [self addSubview:self.thumbnailImageView];
}

- (void)setThumbnailImage:(nullable UIImage *)image animated:(BOOL)animated {
    if (animated) {
        [UIView transitionWithView:self.thumbnailImageView
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            self.thumbnailImageView.image = image;
        } completion:nil];
    } else {
        self.thumbnailImageView.image = image;
    }
}

- (void)loadRecentPhotoThumbnail {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    fetchOptions.fetchLimit = 1;

    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    if (result.count > 0) {
        PHAsset *asset = result.firstObject;
        CGSize targetSize = CGSizeMake(self.bounds.size.width * 2.0, self.bounds.size.height * 2.0);
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.networkAccessAllowed = NO;

        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:targetSize
                                                  contentMode:PHImageContentModeAspectFill
                                                      options:options
                                                resultHandler:^(UIImage * _Nullable resultImage, NSDictionary * _Nullable info) {
            if (resultImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setThumbnailImage:resultImage animated:YES];
                });
            }
        }];
    }
}

@end

#pragma mark - Camera27TopBar

@interface Camera27TopBar ()
@property (nonatomic, strong, readwrite) UIButton *flashButton;
@property (nonatomic, strong, readwrite) UIButton *livePhotoButton;
@property (nonatomic, strong, readwrite) UIButton *timerButton;
@property (nonatomic, strong, readwrite) UILabel *statusBadgeLabel;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end

@implementation Camera27TopBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    self.layer.borderWidth = 0.5;

    if ([Camera27Settings sharedSettings].glassUIEnabled) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        self.blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        self.blurView.frame = self.bounds;
        self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.blurView.userInteractionEnabled = NO;
        [self addSubview:self.blurView];
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    }

    CGFloat height = self.bounds.size.height;
    CGFloat buttonWidth = height;

    // Flash Button (Left)
    self.flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashButton.frame = CGRectMake(6, 0, buttonWidth, height);
    [self.flashButton setImage:[UIImage systemImageNamed:@"bolt.slash.fill"] forState:UIControlStateNormal];
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton addTarget:self action:@selector(handleFlashTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.flashButton];

    // Live Photo Button
    self.livePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.livePhotoButton.frame = CGRectMake(6 + buttonWidth + 4, 0, buttonWidth, height);
    [self.livePhotoButton setImage:[UIImage systemImageNamed:@"livephoto"] forState:UIControlStateNormal];
    self.livePhotoButton.tintColor = [UIColor whiteColor];
    [self.livePhotoButton addTarget:self action:@selector(handleLivePhotoTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.livePhotoButton];

    // Timer Button
    self.timerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.timerButton.frame = CGRectMake(6 + (buttonWidth + 4) * 2, 0, buttonWidth, height);
    [self.timerButton setImage:[UIImage systemImageNamed:@"timer"] forState:UIControlStateNormal];
    self.timerButton.tintColor = [UIColor whiteColor];
    [self.timerButton addTarget:self action:@selector(handleTimerTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.timerButton];

    // Status Badge Label (Right aligned)
    CGFloat labelWidth = 84.0;
    self.statusBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - labelWidth - 12, 0, labelWidth, height)];
    self.statusBadgeLabel.text = @"Camera27";
    self.statusBadgeLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    self.statusBadgeLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightSemibold];
    self.statusBadgeLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.statusBadgeLabel];
}

- (void)handleFlashTap {
    [Camera27Animations playLightHaptic];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapFlash:)]) {
        [self.delegate topBarDidTapFlash:self.flashButton];
    }
}

- (void)handleLivePhotoTap {
    [Camera27Animations playLightHaptic];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapLivePhoto:)]) {
        [self.delegate topBarDidTapLivePhoto:self.livePhotoButton];
    }
}

- (void)handleTimerTap {
    [Camera27Animations playLightHaptic];
    if ([self.delegate respondsToSelector:@selector(topBarDidTapTimer:)]) {
        [self.delegate topBarDidTapTimer:self.timerButton];
    }
}

- (void)setFlashState:(NSInteger)state {
    // 0 = Off, 1 = On, 2 = Auto
    if (state == 1) {
        [self.flashButton setImage:[UIImage systemImageNamed:@"bolt.fill"] forState:UIControlStateNormal];
        self.flashButton.tintColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0];
    } else if (state == 2) {
        [self.flashButton setImage:[UIImage systemImageNamed:@"bolt.badge.a.fill"] forState:UIControlStateNormal];
        self.flashButton.tintColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0];
    } else {
        [self.flashButton setImage:[UIImage systemImageNamed:@"bolt.slash.fill"] forState:UIControlStateNormal];
        self.flashButton.tintColor = [UIColor whiteColor];
    }
}

- (void)setLivePhotoActive:(BOOL)active {
    if (active) {
        self.livePhotoButton.tintColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0];
    } else {
        self.livePhotoButton.tintColor = [UIColor whiteColor];
    }
}

- (void)setTimerDuration:(NSInteger)seconds {
    if (seconds > 0) {
        self.timerButton.tintColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0];
    } else {
        self.timerButton.tintColor = [UIColor whiteColor];
    }
}

@end
