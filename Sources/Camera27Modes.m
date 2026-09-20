//
//  Camera27Modes.m
//  Camera27
//
//  Horizontal Mode Switcher for iPhone 8 Plus Camera modes.
//

#import "Camera27Modes.h"
#import "Camera27Animations.h"
#import "Camera27Settings.h"

@interface Camera27ModeItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) CAMMode mode;
@end

@implementation Camera27ModeItem
@end

@interface Camera27ModeSwitcher () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *modeButtons;
@property (nonatomic, strong) NSArray<Camera27ModeItem *> *items;
@property (nonatomic, strong) UIView *activeIndicatorDot;

@end

@implementation Camera27ModeSwitcher

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentMode = CAMModePhoto;
        _modeButtons = [NSMutableArray array];
        [self setupModeItems];
        [self setupUI];
    }
    return self;
}

- (void)setupModeItems {
    NSMutableArray *items = [NSMutableArray array];

    Camera27ModeItem *timeLapse = [Camera27ModeItem new];
    timeLapse.title = @"TIME-LAPSE";
    timeLapse.mode = CAMModeTimeLapse;
    [items addObject:timeLapse];

    Camera27ModeItem *sloMo = [Camera27ModeItem new];
    sloMo.title = @"SLO-MO";
    sloMo.mode = CAMModeSloMo;
    [items addObject:sloMo];

    Camera27ModeItem *video = [Camera27ModeItem new];
    video.title = @"VIDEO";
    video.mode = CAMModeVideo;
    [items addObject:video];

    Camera27ModeItem *photo = [Camera27ModeItem new];
    photo.title = @"PHOTO";
    photo.mode = CAMModePhoto;
    [items addObject:photo];

    Camera27ModeItem *portrait = [Camera27ModeItem new];
    portrait.title = @"PORTRAIT";
    portrait.mode = CAMModePortrait;
    [items addObject:portrait];

    Camera27ModeItem *pano = [Camera27ModeItem new];
    pano.title = @"PANO";
    pano.mode = CAMModePano;
    [items addObject:pano];

    self.items = [items copy];
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];

    CGFloat padding = 20.0;
    CGFloat currentX = padding;
    CGFloat buttonHeight = self.bounds.size.height;

    for (NSInteger i = 0; i < self.items.count; i++) {
        Camera27ModeItem *item = self.items[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;

        [btn setTitle:item.title forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        [btn setTitleColor:[UIColor colorWithWhite:0.75 alpha:1.0] forState:UIControlStateNormal];

        CGSize size = [item.title sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold]}];
        CGFloat width = size.width + 16.0;
        btn.frame = CGRectMake(currentX, 0, width, buttonHeight);

        [btn addTarget:self action:@selector(handleModeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:btn];
        [self.modeButtons addObject:btn];

        currentX += width + 10.0;
    }

    self.scrollView.contentSize = CGSizeMake(currentX + padding, buttonHeight);

    // Active indicator dot below text
    self.activeIndicatorDot = [[UIView alloc] initWithFrame:CGRectMake(0, buttonHeight - 4.0, 4.0, 4.0)];
    self.activeIndicatorDot.layer.cornerRadius = 2.0;
    self.activeIndicatorDot.backgroundColor = [UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0];
    [self.scrollView addSubview:self.activeIndicatorDot];

    [self setSelectedMode:CAMModePhoto animated:NO];
}

- (void)handleModeButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < self.items.count) {
        Camera27ModeItem *item = self.items[index];
        [self setSelectedMode:item.mode animated:YES];
        if ([self.delegate respondsToSelector:@selector(modeSwitcher:didSelectMode:)]) {
            [self.delegate modeSwitcher:self didSelectMode:item.mode];
        }
    }
}

- (void)setSelectedMode:(CAMMode)mode animated:(BOOL)animated {
    _currentMode = mode;
    NSInteger targetIndex = -1;
    for (NSInteger i = 0; i < self.items.count; i++) {
        if (self.items[i].mode == mode) {
            targetIndex = i;
            break;
        }
    }

    if (targetIndex < 0 || targetIndex >= self.modeButtons.count) return;

    [Camera27Animations playLightHaptic];

    void (^updateVisuals)(void) = ^{
        for (NSInteger i = 0; i < self.modeButtons.count; i++) {
            UIButton *btn = self.modeButtons[i];
            if (i == targetIndex) {
                [btn setTitleColor:[UIColor colorWithRed:0.95 green:0.75 blue:0.25 alpha:1.0] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
                
                // Position indicator dot
                CGPoint center = self.activeIndicatorDot.center;
                center.x = btn.center.x;
                self.activeIndicatorDot.center = center;
                self.activeIndicatorDot.alpha = 1.0;

                // Center in scroll view
                CGFloat offsetX = btn.center.x - (self.bounds.size.width / 2.0);
                CGFloat maxOffset = self.scrollView.contentSize.width - self.bounds.size.width;
                if (offsetX < 0) offsetX = 0;
                if (offsetX > maxOffset) offsetX = maxOffset;
                [self.scrollView setContentOffset:CGPointMake(offsetX, 0) animated:animated];
            } else {
                [btn setTitleColor:[UIColor colorWithWhite:0.65 alpha:1.0] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
            }
        }
    };

    if (animated) {
        [Camera27Animations animateSpringWithDuration:0.3 animations:updateVisuals completion:nil];
    } else {
        updateVisuals();
    }
}

@end
