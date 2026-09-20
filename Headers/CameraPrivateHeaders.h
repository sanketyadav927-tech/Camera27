//
//  CameraPrivateHeaders.h
//  Camera27
//
//  Defensive interface definitions for iOS 16 CameraUI.framework
//  Targeting iPhone 8 Plus (iOS 16.0 - 16.7.16, arm64)
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

// Camera Modes (iOS 16 CameraUI)
typedef NS_ENUM(NSInteger, CAMMode) {
    CAMModePhoto       = 0,
    CAMModeVideo       = 1,
    CAMModeSloMo       = 2,
    CAMModePano        = 3,
    CAMModeSquare      = 4,
    CAMModeTimeLapse   = 5,
    CAMModePortrait    = 6
};

// Camera Device Positions
typedef NS_ENUM(NSInteger, CAMDevicePosition) {
    CAMDevicePositionBack  = 0,
    CAMDevicePositionFront = 1
};

// Forward declare private CameraUI classes
@class CAMViewfinderView;
@class CAMBottomBar;
@class CAMTopBar;
@class CAMControlDrawer;
@class CAMShutterButton;
@class CUShutterButton;
@class CAMFlipButton;
@class CAMImageWell;
@class CAMModeDial;
@class CAMModeSelector;
@class CAMZoomControl;
@class CAMCaptureController;
@class CAMFlashButton;
@class CAMLivePhotoButton;
@class CAMTimerButton;

@interface CUShutterButton : UIButton
@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, assign) NSInteger state;
@property (nonatomic, assign, getter=isSpinning) BOOL spinning;
- (void)setMode:(NSInteger)mode animated:(BOOL)animated;
@end

@interface CAMShutterButton : CUShutterButton
@end

@interface CAMFlipButton : UIButton
@end

@interface CAMImageWell : UIButton
@property (nonatomic, readonly, nullable) UIImageView *thumbnailImageView;
- (void)setThumbnailImage:(nullable UIImage *)image animated:(BOOL)animated;
- (nullable UIImage *)thumbnailImage;
@end

@interface CAMZoomControl : UIControl
@property (nonatomic, assign) double zoomFactor;
- (void)setZoomFactor:(double)factor animated:(BOOL)animated;
@end

@interface CAMCaptureController : NSObject
@property (nonatomic, assign) double zoomFactor;
- (void)setZoomFactor:(double)factor;
- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated;
@end

@interface CAMBottomBar : UIView
@property (nonatomic, strong, nullable) CUShutterButton *shutterButton;
@property (nonatomic, strong, nullable) CAMFlipButton *flipButton;
@property (nonatomic, strong, nullable) CAMImageWell *imageWell;
@property (nonatomic, strong, nullable) CAMModeDial *modeDial;
@end

@interface CAMTopBar : UIView
@property (nonatomic, strong, nullable) CAMFlashButton *flashButton;
@property (nonatomic, strong, nullable) CAMLivePhotoButton *livePhotoButton;
@property (nonatomic, strong, nullable) CAMTimerButton *timerButton;
@end

@interface CAMViewfinderView : UIView
@end

@interface CAMViewfinderViewController : UIViewController
@property (nonatomic, strong, nullable) CAMViewfinderView *viewfinderView;
@property (nonatomic, strong, nullable) CAMBottomBar *bottomBar;
@property (nonatomic, strong, nullable) CAMTopBar *topBar;
@property (nonatomic, strong, nullable) CAMControlDrawer *controlDrawer;
@property (nonatomic, strong, nullable) CUShutterButton *shutterButton;
@property (nonatomic, strong, nullable) CAMFlipButton *flipButton;
@property (nonatomic, strong, nullable) CAMImageWell *imageWell;
@property (nonatomic, strong, nullable) CAMZoomControl *zoomControl;
@property (nonatomic, strong, nullable) CAMFlashButton *flashButton;
@property (nonatomic, strong, nullable) CAMLivePhotoButton *livePhotoButton;
@property (nonatomic, strong, nullable) CAMTimerButton *timerButton;
@property (nonatomic, strong, nullable) CAMCaptureController *captureController;
@property (nonatomic, assign) NSInteger mode;

- (void)takePicture;
- (void)pressShutterButton:(nullable id)arg1;
- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated;
- (void)setMode:(NSInteger)mode animated:(BOOL)animated;
- (void)_flipButtonReleased:(nullable id)sender;
- (void)_shutterButtonReleased:(nullable id)sender;
- (void)_flashButtonReleased:(nullable id)sender;
- (void)_livePhotoButtonReleased:(nullable id)sender;
- (void)_timerButtonReleased:(nullable id)sender;
- (void)_imageWellPressed:(nullable id)sender;
- (void)_zoomControl:(nullable id)control didChangeZoomFactor:(double)factor;
@end

NS_ASSUME_NONNULL_END
