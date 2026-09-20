//
//  Camera27Zoom.m
//  Camera27
//
//  Zoom selector for iPhone 8 Plus: 1× Wide + 2× Telephoto ONLY.
//  0.5× Ultra Wide is explicitly absent on this hardware.
//

#import "Camera27Zoom.h"
#import "Camera27Animations.h"
#import "Camera27Settings.h"
#import <AVFoundation/AVFoundation.h>

@interface Camera27ZoomView ()
@property (nonatomic, strong) UIView *capsule;
@property (nonatomic, strong) UIView *selectionBubble;
@property (nonatomic, strong) UIButton *btn1x;
@property (nonatomic, strong) UIButton *btn2x;
@property (nonatomic, assign) BOOL hasTelephoto;
@end

@implementation Camera27ZoomView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentZoomFactor = 1.0;
        [self _detectLenses];
        [self _build];
    }
    return self;
}

- (void)_detectLenses {
    // Runtime AVFoundation lens detection — never hardcode ultrawide on iPhone 8 Plus
    _hasTelephoto = NO;
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *s = [AVCaptureDeviceDiscoverySession
            discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTelephotoCamera]
                                  mediaType:AVMediaTypeVideo
                                   position:AVCaptureDevicePositionBack];
        _hasTelephoto = (s.devices.count > 0);
    }
}

- (void)_build {
    self.backgroundColor = UIColor.clearColor;

    // Liquid glass capsule
    self.capsule = [[UIView alloc] initWithFrame:self.bounds];
    self.capsule.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.capsule.layer.masksToBounds = YES;
    self.capsule.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
    self.capsule.layer.borderWidth = 0.75;
    [self addSubview:self.capsule];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    UIVisualEffectView *blurV = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurV.frame = self.capsule.bounds;
    blurV.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurV.userInteractionEnabled = NO;
    [self.capsule addSubview:blurV];

    // Selection bubble
    CGFloat pad = 3, h = self.bounds.size.height, bSize = h - pad * 2;
    CGFloat halfW = self.bounds.size.width / (_hasTelephoto ? 2.0 : 1.0);
    self.selectionBubble = [[UIView alloc] initWithFrame:CGRectMake((halfW - bSize)/2, pad, bSize, bSize)];
    self.selectionBubble.layer.cornerRadius = bSize / 2;
    self.selectionBubble.backgroundColor = [UIColor colorWithWhite:1 alpha:0.22];
    self.selectionBubble.userInteractionEnabled = NO;
    [self.capsule addSubview:self.selectionBubble];

    // 1× button
    self.btn1x = [self _makeZoomButton:@"1×" frame:CGRectMake(0, 0, halfW, h)];
    [self.btn1x addTarget:self action:@selector(_tap1x) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.btn1x];

    if (_hasTelephoto) {
        self.btn2x = [self _makeZoomButton:@"2×" frame:CGRectMake(halfW, 0, halfW, h)];
        [self.btn2x addTarget:self action:@selector(_tap2x) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn2x];
    }

    [self _applySelection:1.0 animated:NO];
}

- (UIButton *)_makeZoomButton:(NSString *)title frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    [btn setTitleColor:[UIColor colorWithWhite:0.8 alpha:1] forState:UIControlStateNormal];
    return btn;
}

- (void)_tap1x {
    [self setSelectedZoomFactor:1.0 animated:YES];
    if ([self.delegate respondsToSelector:@selector(zoomView:didSelectZoomFactor:)])
        [self.delegate zoomView:self didSelectZoomFactor:1.0];
}

- (void)_tap2x {
    [self setSelectedZoomFactor:2.0 animated:YES];
    if ([self.delegate respondsToSelector:@selector(zoomView:didSelectZoomFactor:)])
        [self.delegate zoomView:self didSelectZoomFactor:2.0];
}

- (void)setSelectedZoomFactor:(CGFloat)factor animated:(BOOL)animated {
    _currentZoomFactor = factor;
    void(^upd)(void) = ^{ [self _applySelection:factor animated:NO]; };
    animated ? [Camera27Animations animateSpringWithDuration:0.32 animations:upd completion:nil] : upd();
}

- (void)_applySelection:(CGFloat)factor animated:(BOOL)__unused a {
    [Camera27Animations playLightHaptic];
    CGFloat halfW = self.bounds.size.width / (_hasTelephoto ? 2.0 : 1.0);
    CGFloat pad = 3, bSize = self.bounds.size.height - pad * 2;
    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    UIColor *dim  = [UIColor colorWithWhite:0.72 alpha:1];

    if (factor >= 2.0 && _hasTelephoto) {
        self.selectionBubble.frame = CGRectMake(halfW + (halfW - bSize)/2, pad, bSize, bSize);
        [self.btn1x setTitleColor:dim  forState:UIControlStateNormal];
        self.btn1x.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [self.btn2x setTitleColor:gold forState:UIControlStateNormal];
        self.btn2x.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    } else {
        self.selectionBubble.frame = CGRectMake((halfW - bSize)/2, pad, bSize, bSize);
        [self.btn1x setTitleColor:gold forState:UIControlStateNormal];
        self.btn1x.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        if (self.btn2x) {
            [self.btn2x setTitleColor:dim forState:UIControlStateNormal];
            self.btn2x.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        }
    }
}

@end
