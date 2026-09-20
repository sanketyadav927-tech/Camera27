//
//  Camera27Zoom.m
//  Camera27
//
//  Custom Zoom Control tailored for iPhone 8 Plus (1× Wide, 2× Telephoto).
//  Explicitly excludes 0.5× Ultra Wide (not present on iPhone 8 Plus).
//

#import "Camera27Zoom.h"
#import "Camera27Animations.h"
#import "Camera27Settings.h"
#import <AVFoundation/AVFoundation.h>

@interface Camera27ZoomView ()

@property (nonatomic, strong) UIView *pillBackground;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIButton *oneXButton;
@property (nonatomic, strong) UIButton *twoXButton;
@property (nonatomic, assign) BOOL hasTelephotoCamera;

@end

@implementation Camera27ZoomView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentZoomFactor = 1.0;
        _hasTelephotoCamera = YES; // iPhone 8 Plus default
        [self updateAvailableLenses];
        [self setupUI];
    }
    return self;
}

- (void)updateAvailableLenses {
    // Dynamically detect hardware cameras: Wide (1x) and Telephoto (2x)
    if (@available(iOS 10.0, *)) {
        NSArray *deviceTypes = @[
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            AVCaptureDeviceTypeBuiltInTelephotoCamera
        ];
        AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession
            discoverySessionWithDeviceTypes:deviceTypes
                                  mediaType:AVMediaTypeVideo
                                   position:AVCaptureDevicePositionBack];
        
        BOOL foundTelephoto = NO;
        for (AVCaptureDevice *device in session.devices) {
            if ([device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInTelephotoCamera]) {
                foundTelephoto = YES;
                break;
            }
        }
        _hasTelephotoCamera = foundTelephoto;
    }
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];

    // Background pill
    self.pillBackground = [[UIView alloc] initWithFrame:self.bounds];
    self.pillBackground.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.pillBackground.layer.masksToBounds = YES;
    
    if ([Camera27Settings sharedSettings].glassUIEnabled) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = self.pillBackground.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurView.userInteractionEnabled = NO;
        [self.pillBackground addSubview:blurView];
    } else {
        self.pillBackground.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    }
    
    self.pillBackground.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
    self.pillBackground.layer.borderWidth = 0.5;
    [self addSubview:self.pillBackground];

    CGFloat itemWidth = self.bounds.size.width / 2.0;
    CGFloat height = self.bounds.size.height;

    // Selection bubble indicator
    CGFloat indicatorPadding = 3.0;
    CGFloat indicatorSize = height - (indicatorPadding * 2.0);
    self.selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(
        (itemWidth - indicatorSize) / 2.0,
        indicatorPadding,
        indicatorSize,
        indicatorSize
    )];
    self.selectionIndicator.layer.cornerRadius = indicatorSize / 2.0;
    self.selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    self.selectionIndicator.userInteractionEnabled = NO;
    [self.pillBackground addSubview:self.selectionIndicator];

    // 1x Button
    self.oneXButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.oneXButton.frame = CGRectMake(0, 0, itemWidth, height);
    [self.oneXButton setTitle:@"1×" forState:UIControlStateNormal];
    self.oneXButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    [self.oneXButton setTitleColor:[UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0] forState:UIControlStateNormal];
    [self.oneXButton addTarget:self action:@selector(handleOneXTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.oneXButton];

    // 2x Button (Only if telephoto hardware is present)
    if (self.hasTelephotoCamera) {
        self.twoXButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.twoXButton.frame = CGRectMake(itemWidth, 0, itemWidth, height);
        [self.twoXButton setTitle:@"2×" forState:UIControlStateNormal];
        self.twoXButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        [self.twoXButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
        [self.twoXButton addTarget:self action:@selector(handleTwoXTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.twoXButton];
    } else {
        // Fallback for single camera / front camera
        self.oneXButton.frame = self.bounds;
        self.selectionIndicator.frame = CGRectMake(
            (self.bounds.size.width - indicatorSize) / 2.0,
            indicatorPadding,
            indicatorSize,
            indicatorSize
        );
    }
}

- (void)handleOneXTapped {
    [self setSelectedZoomFactor:1.0 animated:YES];
    if ([self.delegate respondsToSelector:@selector(zoomView:didSelectZoomFactor:)]) {
        [self.delegate zoomView:self didSelectZoomFactor:1.0];
    }
}

- (void)handleTwoXTapped {
    [self setSelectedZoomFactor:2.0 animated:YES];
    if ([self.delegate respondsToSelector:@selector(zoomView:didSelectZoomFactor:)]) {
        [self.delegate zoomView:self didSelectZoomFactor:2.0];
    }
}

- (void)setSelectedZoomFactor:(CGFloat)factor animated:(BOOL)animated {
    _currentZoomFactor = factor;
    [Camera27Animations playLightHaptic];

    CGFloat itemWidth = self.bounds.size.width / 2.0;
    CGFloat indicatorPadding = 3.0;
    CGFloat indicatorSize = self.bounds.size.height - (indicatorPadding * 2.0);

    CGRect targetFrame;
    if (factor >= 2.0 && self.hasTelephotoCamera) {
        targetFrame = CGRectMake(itemWidth + (itemWidth - indicatorSize) / 2.0, indicatorPadding, indicatorSize, indicatorSize);
    } else {
        targetFrame = CGRectMake((itemWidth - indicatorSize) / 2.0, indicatorPadding, indicatorSize, indicatorSize);
    }

    void (^updateVisuals)(void) = ^{
        self.selectionIndicator.frame = targetFrame;
        if (factor >= 2.0) {
            [self.oneXButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
            self.oneXButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
            [self.twoXButton setTitleColor:[UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0] forState:UIControlStateNormal];
            self.twoXButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
        } else {
            [self.oneXButton setTitleColor:[UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0] forState:UIControlStateNormal];
            self.oneXButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
            [self.twoXButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
            self.twoXButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        }
    };

    if (animated) {
        [Camera27Animations animateSpringWithDuration:0.35 animations:updateVisuals completion:nil];
    } else {
        updateVisuals();
    }
}

@end
