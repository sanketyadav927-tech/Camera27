//
//  Camera27UI.h
//  Camera27
//

#import <UIKit/UIKit.h>
#import "CameraPrivateHeaders.h"

NS_ASSUME_NONNULL_BEGIN

@interface Camera27UI : NSObject

@property (nonatomic, weak, nullable) CAMViewfinderViewController *viewfinderController;

// Flash state cycling: 0=off, 1=on, 2=auto
@property (nonatomic, assign) NSInteger flashState;
// Live Photo
@property (nonatomic, assign) BOOL livePhotoActive;
// Timer: 0, 3, 10
@property (nonatomic, assign) NSInteger timerDuration;
// HDR
@property (nonatomic, assign) BOOL hdrEnabled;
// Current mode
@property (nonatomic, assign) CAMMode currentMode;
// Front facing?
@property (nonatomic, assign) BOOL isFrontCamera;

+ (instancetype)sharedInstance;
- (void)setupInViewController:(CAMViewfinderViewController *)vc;
- (void)hideLegacyStockUI;
- (void)teardown;
- (void)syncMode:(CAMMode)mode animated:(BOOL)animated;
- (void)syncZoomFactor:(double)factor;
- (void)syncRecording:(BOOL)recording;

@end

NS_ASSUME_NONNULL_END
