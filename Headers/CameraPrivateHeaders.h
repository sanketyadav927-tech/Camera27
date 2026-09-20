//
//  CameraPrivateHeaders.h
//  Camera27
//
//  Complete defensive interfaces for iOS 16 CameraUI.framework
//  Target: iPhone 8 Plus, iOS 16.0-16.7.x, arm64
//
//  ARCHITECTURE RULE:
//  Every class used in a typed pointer assignment MUST have a full
//  @interface declaration with its real superclass, never a bare @class.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

// ---------------------------------------------------------------------------
// MARK: - Enumerations
// ---------------------------------------------------------------------------

typedef NS_ENUM(NSInteger, CAMMode) {
    CAMModePhoto       = 0,
    CAMModeVideo       = 1,
    CAMModeSloMo       = 2,
    CAMModePano        = 3,
    CAMModeSquare      = 4,
    CAMModeTimeLapse   = 5,
    CAMModePortrait    = 6
};

typedef NS_ENUM(NSInteger, CAMCameraPosition) {
    CAMCameraPositionBack  = 0,
    CAMCameraPositionFront = 1
};

typedef NS_ENUM(NSInteger, CAMFlashMode) {
    CAMFlashModeOff  = 0,
    CAMFlashModeOn   = 1,
    CAMFlashModeAuto = 2
};

// ---------------------------------------------------------------------------
// MARK: - Simple View Subclass Declarations (needed for typed assignments)
// ---------------------------------------------------------------------------

@interface CAMViewfinderView : UIView
@end

@interface CAMControlDrawer : UIView
@end

@interface CAMModeDial : UIView
@end

@interface CAMModeSelector : UIView
@end

// ---------------------------------------------------------------------------
// MARK: - Button Subclasses
// ---------------------------------------------------------------------------

// NOTE: Do NOT redeclare UIControl's 'state' property.
// UIControl declares: @property (nonatomic, readonly) UIControlState state;
// Overriding type/atomicity causes -Werror,-Wincompatible-property-type.
@interface CUShutterButton : UIButton
@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, assign, getter=isSpinning) BOOL spinning;
- (void)setMode:(NSInteger)mode animated:(BOOL)animated;
@end

@interface CAMShutterButton : CUShutterButton
@end

@interface CAMFlipButton : UIButton
@end

@interface CAMFlashButton : UIButton
@property (nonatomic, assign) NSInteger flashMode;
@end

@interface CAMLivePhotoButton : UIButton
@property (nonatomic, assign, getter=isActive) BOOL active;
@end

@interface CAMTimerButton : UIButton
@property (nonatomic, assign) NSInteger timerDuration;
@end

@interface CAMHDRButton : UIButton
@end

@interface CAMImageWell : UIButton
@property (nonatomic, readonly, nullable) UIImageView *thumbnailImageView;
- (void)setThumbnailImage:(nullable UIImage *)image animated:(BOOL)animated;
- (nullable UIImage *)thumbnailImage;
@end

// ---------------------------------------------------------------------------
// MARK: - Control / Compound Views
// ---------------------------------------------------------------------------

@interface CAMZoomControl : UIControl
@property (nonatomic, assign) double zoomFactor;
- (void)setZoomFactor:(double)factor animated:(BOOL)animated;
@end

// ---------------------------------------------------------------------------
// MARK: - Capture Controller
// ---------------------------------------------------------------------------

@interface CAMCaptureController : NSObject
@property (nonatomic, assign) double zoomFactor;
@property (nonatomic, assign) NSInteger flashMode;
@property (nonatomic, assign, getter=isHDREnabled) BOOL HDREnabled;
- (void)setZoomFactor:(double)factor;
- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated;
- (nullable AVCaptureDevice *)currentDevice;
- (nullable AVCaptureDevice *)videoCaptureDevice;
@end

// ---------------------------------------------------------------------------
// MARK: - Bar Views
// ---------------------------------------------------------------------------

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
@property (nonatomic, strong, nullable) CAMHDRButton *HDRButton;
@end

// ---------------------------------------------------------------------------
// MARK: - Root Camera View Controller
// ---------------------------------------------------------------------------

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
@property (nonatomic, strong, nullable) CAMHDRButton *HDRButton;
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
- (void)_HDRButtonReleased:(nullable id)sender;
- (void)_zoomControl:(nullable id)control didChangeZoomFactor:(double)factor;
@end

NS_ASSUME_NONNULL_END
