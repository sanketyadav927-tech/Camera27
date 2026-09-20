#import "Camera27UI.h"
#import "Camera27Runtime.h"
#import "Camera27Settings.h"
#import <Photos/Photos.h>

@interface Camera27Overlay : UIView
@property (nonatomic, weak) UIViewController *controller;
@property (nonatomic, strong) UIVisualEffectView *topBar;
@property (nonatomic, strong) UIVisualEffectView *deck;
@property (nonatomic, strong) UIVisualEffectView *zoom;
@property (nonatomic, strong) UIButton *shutter;
@property (nonatomic, strong) UIButton *gallery;
@property (nonatomic, strong) UIButton *flip;
@property (nonatomic, strong) UIButton *oneX;
@property (nonatomic, strong) UIButton *twoX;
@property (nonatomic, strong) NSArray<UIButton *> *modes;
@end

@implementation Camera27Overlay

- (instancetype)initWithController:(UIViewController *)controller {
    if ((self = [super initWithFrame:controller.view.bounds])) {
        _controller = controller; self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
        _topBar = [[UIVisualEffectView alloc] initWithEffect:[Camera27Settings sharedSettings].glassEnabled ? blur : nil]; _topBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.68]; _topBar.layer.cornerRadius = 23; _topBar.clipsToBounds = YES; [self addSubview:_topBar];
        for (NSInteger action = Camera27ActionFlash; action <= Camera27ActionTimer; action++) { UIButton *button = [self circularButton:@"circle" tag:action]; [button addTarget:self action:@selector(topAction:) forControlEvents:UIControlEventTouchUpInside]; [_topBar.contentView addSubview:button]; }
        _deck = [[UIVisualEffectView alloc] initWithEffect:[Camera27Settings sharedSettings].glassEnabled ? blur : nil]; _deck.backgroundColor = [UIColor colorWithWhite:0 alpha:0.68]; _deck.layer.cornerRadius = 28; _deck.clipsToBounds = YES; [self addSubview:_deck];
        _zoom = [[UIVisualEffectView alloc] initWithEffect:[Camera27Settings sharedSettings].glassEnabled ? blur : nil]; _zoom.backgroundColor = [UIColor colorWithWhite:0 alpha:0.68]; _zoom.layer.cornerRadius = 20; _zoom.clipsToBounds = YES; [self addSubview:_zoom];
        _oneX = [self textButton:@"1x" tag:1]; [_oneX addTarget:self action:@selector(zoomAction:) forControlEvents:UIControlEventTouchUpInside]; [_zoom.contentView addSubview:_oneX];
        _twoX = [self textButton:@"2x" tag:2]; [_twoX addTarget:self action:@selector(zoomAction:) forControlEvents:UIControlEventTouchUpInside]; [_zoom.contentView addSubview:_twoX];
        _shutter = [self circularButton:@"circle.inset.filled" tag:0]; _shutter.tintColor = UIColor.whiteColor; _shutter.backgroundColor = UIColor.whiteColor; _shutter.layer.borderColor = UIColor.blackColor.CGColor; _shutter.layer.borderWidth = 4; [_shutter addTarget:self action:@selector(shutterAction:) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_shutter];
        _gallery = [self circularButton:@"photo" tag:0]; [_gallery addTarget:self action:@selector(galleryAction:) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_gallery];
        _flip = [self circularButton:@"camera.rotate" tag:0]; [_flip addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside]; [self addSubview:_flip];
        NSArray *titles = @[@"VIDEO", @"PHOTO", @"PORTRAIT", @"PANO", @"SLO-MO", @"TIME-LAPSE"];
        NSMutableArray *modeButtons = [NSMutableArray array]; for (NSInteger index = 0; index < titles.count; index++) { UIButton *button = [self textButton:titles[index] tag:index]; [button addTarget:self action:@selector(modeAction:) forControlEvents:UIControlEventTouchUpInside]; [_deck.contentView addSubview:button]; [modeButtons addObject:button]; } _modes = modeButtons; [self selectMode:_modes[1]];
    }
    return self;
}

- (UIButton *)circularButton:(NSString *)symbol tag:(NSInteger)tag { UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; button.tag = tag; button.tintColor = UIColor.whiteColor; UIImage *image = [UIImage systemImageNamed:symbol]; [button setImage:image forState:UIControlStateNormal]; button.backgroundColor = [UIColor colorWithWhite:0 alpha:0.38]; button.layer.cornerRadius = 23; button.accessibilityTraits = UIAccessibilityTraitButton; return button; }
- (UIButton *)textButton:(NSString *)title tag:(NSInteger)tag { UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; button.tag = tag; button.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]; [button setTitle:title forState:UIControlStateNormal]; [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; return button; }
- (void)layoutSubviews { [super layoutSubviews]; UIEdgeInsets safe = self.safeAreaInsets; CGFloat width = self.bounds.size.width; CGFloat height = self.bounds.size.height; self.topBar.frame = CGRectMake((width - 154) / 2, safe.top + 12, 154, 46); for (NSInteger i = 0; i < 3; i++) self.topBar.contentView.subviews[i].frame = CGRectMake(5 + i * 50, 2, 42, 42); CGFloat deckHeight = 98; self.deck.frame = CGRectMake(12, height - safe.bottom - deckHeight - 12, width - 24, deckHeight); self.shutter.frame = CGRectMake((width - 76) / 2, CGRectGetMinY(self.deck.frame) - 88, 76, 76); self.shutter.layer.cornerRadius = 38; self.gallery.frame = CGRectMake(24, CGRectGetMinY(self.deck.frame) - 72, 48, 48); self.flip.frame = CGRectMake(width - 72, CGRectGetMinY(self.deck.frame) - 72, 48, 48); self.zoom.frame = CGRectMake((width - 112) / 2, CGRectGetMinY(self.shutter.frame) - 54, 112, 40); self.oneX.frame = CGRectMake(4, 2, 52, 36); self.twoX.frame = CGRectMake(56, 2, 52, 36); CGFloat modeWidth = MIN(70, (self.deck.bounds.size.width - 8) / self.modes.count); CGFloat start = (self.deck.bounds.size.width - modeWidth * self.modes.count) / 2; for (NSInteger i = 0; i < self.modes.count; i++) self.modes[i].frame = CGRectMake(start + i * modeWidth, 26, modeWidth, 42); }
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event { UIView *hit = [super hitTest:point withEvent:event]; return hit == self ? nil : hit; }
- (void)feedback { if ([Camera27Settings sharedSettings].hapticsEnabled) { UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight]; [generator impactOccurred]; } }
- (void)hideStock { Camera27HideVerifiedStockChrome(self.controller); }
- (void)topAction:(UIButton *)sender { [self feedback]; Camera27PerformAction(self.controller, (Camera27Action)sender.tag); [self hideStock]; }
- (void)shutterAction:(__unused UIButton *)sender { [self feedback]; Camera27PerformAction(self.controller, Camera27ActionShutter); [self hideStock]; }
- (void)galleryAction:(__unused UIButton *)sender { [self feedback]; Camera27PerformAction(self.controller, Camera27ActionGallery); }
- (void)flipAction:(__unused UIButton *)sender { [self feedback]; Camera27PerformAction(self.controller, Camera27ActionFlip); [self hideStock]; }
- (void)zoomAction:(UIButton *)sender { [self feedback]; if (sender.tag == 2 && !Camera27HasTelephotoCamera()) return; if (Camera27SetZoom(self.controller, sender.tag)) { self.oneX.backgroundColor = sender.tag == 1 ? [UIColor colorWithWhite:1 alpha:0.2] : UIColor.clearColor; self.twoX.backgroundColor = sender.tag == 2 ? [UIColor colorWithWhite:1 alpha:0.2] : UIColor.clearColor; } [self hideStock]; }
- (void)selectMode:(UIButton *)selected { for (UIButton *button in self.modes) { button.backgroundColor = UIColor.clearColor; button.layer.cornerRadius = 15; [button setTitleColor:[UIColor colorWithWhite:0.75 alpha:1] forState:UIControlStateNormal]; } selected.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16]; [selected setTitleColor:[UIColor colorWithRed:1 green:0.82 blue:0 alpha:1] forState:UIControlStateNormal]; }
- (void)modeAction:(UIButton *)sender { [self feedback]; if (Camera27PerformNamedMode(self.controller, sender.titleLabel.text ?: @"")) [self selectMode:sender]; [self hideStock]; }
@end

@interface Camera27UI ()
@property (nonatomic, weak) UIViewController *controller;
@property (nonatomic, strong) Camera27Overlay *overlay;
@end

@implementation Camera27UI
+ (instancetype)sharedInstance { static Camera27UI *instance; static dispatch_once_t once; dispatch_once(&once, ^{ instance = [self new]; }); return instance; }
- (void)attachToController:(UIViewController *)controller { if (!controller || !Camera27ControllerIsSupported(controller)) return; if (self.overlay.superview == controller.view) { Camera27HideVerifiedStockChrome(controller); return; } [self.overlay removeFromSuperview]; Camera27LogDiagnosticReport(controller); Camera27HideVerifiedStockChrome(controller); self.controller = controller; self.overlay = [[Camera27Overlay alloc] initWithController:controller]; [controller.view addSubview:self.overlay]; }
@end
