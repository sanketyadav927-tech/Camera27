#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, Camera27Action) {
    Camera27ActionShutter, Camera27ActionFlip, Camera27ActionGallery,
    Camera27ActionFlash, Camera27ActionLivePhoto, Camera27ActionTimer
};

UIViewController *Camera27FindCameraController(UIViewController *root);
BOOL Camera27ControllerIsSupported(UIViewController *controller);
BOOL Camera27PerformAction(UIViewController *controller, Camera27Action action);
BOOL Camera27PerformNamedMode(UIViewController *controller, NSString *modeName);
BOOL Camera27SetZoom(UIViewController *controller, CGFloat zoom);
BOOL Camera27HasTelephotoCamera(void);
void Camera27HideVerifiedStockChrome(UIViewController *controller);
void Camera27LogDiagnosticReport(UIViewController *controller);
