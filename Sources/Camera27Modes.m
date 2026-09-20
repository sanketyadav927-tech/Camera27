//
//  Camera27Modes.m
//  Camera27
//
//  Liquid glass mode selector with scrolling pill strip.
//

#import "Camera27Modes.h"
#import "Camera27Animations.h"
#import "Camera27Settings.h"

typedef struct { NSString *title; CAMMode mode; } ModeEntry;

@interface Camera27ModeSwitcher ()
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) NSArray<UIButton *> *buttons;
@property (nonatomic, strong) UIView *activeDot;
@end

static ModeEntry kModes[] = {
    { @"TIME-LAPSE", CAMModeTimeLapse },
    { @"SLO-MO",     CAMModeSloMo    },
    { @"VIDEO",      CAMModeVideo    },
    { @"PHOTO",      CAMModePhoto    },
    { @"PORTRAIT",   CAMModePortrait },
    { @"PANO",       CAMModePano     }
};
static const NSInteger kModeCount = 6;

@implementation Camera27ModeSwitcher

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentMode = CAMModePhoto;
        [self _build];
    }
    return self;
}

- (void)_build {
    self.backgroundColor = UIColor.clearColor;

    self.scroll = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scroll.showsHorizontalScrollIndicator = NO;
    self.scroll.alwaysBounceHorizontal = YES;
    [self addSubview:self.scroll];

    CGFloat h = self.bounds.size.height;
    CGFloat x = 16;
    NSMutableArray<UIButton *> *btns = [NSMutableArray array];

    for (NSInteger i = 0; i < kModeCount; i++) {
        NSString *title = kModes[i].title;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        // UILabel has no letterSpacing property; use NSAttributedString with NSKernAttributeName
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
            NSFontAttributeName:           [UIFont systemFontOfSize:12.5 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.65 alpha:1],
            NSKernAttributeName:           @(0.5)
        }];
        [btn setAttributedTitle:attrTitle forState:UIControlStateNormal];

        CGSize sz = [title sizeWithAttributes:@{NSFontAttributeName: btn.titleLabel.font, NSKernAttributeName: @(0.5)}];

        CGFloat w = sz.width + 18;
        btn.frame = CGRectMake(x, 0, w, h);
        [btn addTarget:self action:@selector(_modeTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:btn];
        [btns addObject:btn];
        x += w + 8;
    }

    self.scroll.contentSize = CGSizeMake(x + 16, h);
    self.buttons = [btns copy];

    // Active indicator dot under selected mode
    self.activeDot = [[UIView alloc] initWithFrame:CGRectMake(0, h - 3, 3, 3)];
    self.activeDot.layer.cornerRadius = 1.5;
    self.activeDot.backgroundColor = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    [self.scroll addSubview:self.activeDot];

    [self setSelectedMode:CAMModePhoto animated:NO];
}

- (void)_modeTap:(UIButton *)sender {
    CAMMode mode = kModes[sender.tag].mode;
    [self setSelectedMode:mode animated:YES];
    if ([self.delegate respondsToSelector:@selector(modeSwitcher:didSelectMode:)])
        [self.delegate modeSwitcher:self didSelectMode:mode];
}

- (void)setSelectedMode:(CAMMode)mode animated:(BOOL)animated {
    _currentMode = mode;
    NSInteger idx = -1;
    for (NSInteger i = 0; i < kModeCount; i++) {
        if (kModes[i].mode == mode) { idx = i; break; }
    }
    if (idx < 0 || idx >= (NSInteger)self.buttons.count) return;

    [Camera27Animations playLightHaptic];

    UIColor *gold = [UIColor colorWithRed:0.95 green:0.78 blue:0.28 alpha:1];
    UIColor *dim  = [UIColor colorWithWhite:0.62 alpha:1];

        void(^upd)(void) = ^{
        for (NSInteger i = 0; i < (NSInteger)self.buttons.count; i++) {
            UIButton *b = self.buttons[i];
            BOOL sel = (i == idx);
            UIColor *color  = sel ? gold : dim;
            UIFontWeight wt = sel ? UIFontWeightBold : UIFontWeightMedium;
            NSString *str   = kModes[i].title;
            NSAttributedString *attr = [[NSAttributedString alloc] initWithString:str attributes:@{
                NSFontAttributeName:           [UIFont systemFontOfSize:12.5 weight:wt],
                NSForegroundColorAttributeName: color,
                NSKernAttributeName:           @(0.5)
            }];
            [b setAttributedTitle:attr forState:UIControlStateNormal];
        }
        UIButton *selBtn = self.buttons[idx];
        // Move dot to center of selected button
        CGPoint c = self.activeDot.center;
        c.x = selBtn.center.x;
        self.activeDot.center = c;
        // Scroll to show selected item
        CGFloat off = selBtn.center.x - self.bounds.size.width / 2.0;
        CGFloat maxOff = self.scroll.contentSize.width - self.bounds.size.width;
        off = MAX(0, MIN(off, maxOff));
        [self.scroll setContentOffset:CGPointMake(off, 0) animated:animated];
    };

    animated ? [Camera27Animations animateSpringWithDuration:0.3 animations:upd completion:nil] : upd();
}

@end
