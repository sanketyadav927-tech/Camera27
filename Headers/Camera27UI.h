//
//  Camera27UI.h
//  Camera27
//
//  Master overlay manager and container for Camera27 interface.
//

#import <UIKit/UIKit.h>
#import "CameraPrivateHeaders.h"
#import "Camera27Controls.h"
#import "Camera27Zoom.h"
#import "Camera27Modes.h"

NS_ASSUME_NONNULL_BEGIN

@interface Camera27UI : NSObject <Camera27ZoomViewDelegate, Camera27ModeSwitcherDelegate, Camera27TopBarDelegate>

@property (nonatomic, weak, nullable) CAMViewfinderViewController *viewfinderController;
@property (nonatomic, strong, nullable) UIView *overlayContainerView;
@property (nonatomic, strong, nullable) UIVisualEffectView *bottomGlassPanel;
@property (nonatomic, strong, nullable) Camera27TopBar *topBar;
@property (nonatomic, strong, nullable) Camera27ZoomView *zoomView;
@property (nonatomic, strong, nullable) Camera27ModeSwitcher *modeSwitcher;
@property (nonatomic, strong, nullable) Camera27ShutterButton *shutterButton;
@property (nonatomic, strong, nullable) Camera27FlipButton *flipButton;
@property (nonatomic, strong, nullable) Camera27ImageWell *galleryWell;
@property (nonatomic, strong, nullable) UIButton *filterButton;
@property (nonatomic, strong, nullable) UIButton *moreButton;
@property (nonatomic, strong, nullable) UILabel *badge27;

+ (instancetype)sharedInstance;

- (void)setupInViewController:(CAMViewfinderViewController *)viewController;
- (void)hideLegacyStockUI;
- (void)teardown;
- (void)updateForCurrentMode:(CAMMode)mode animated:(BOOL)animated;

// Action Handlers
- (void)handleShutterPressed;
- (void)handleFlipPressed;
- (void)handleGalleryPressed;
- (void)handleFilterPressed;
- (void)handleMorePressed;

@end

NS_ASSUME_NONNULL_END
