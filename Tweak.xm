#import <UIKit/UIKit.h>
#import "Headers/Camera27Settings.h"
#import "Headers/Camera27Runtime.h"
#import "Headers/Camera27UI.h"

static void Camera27TryInstall(void) {
    if (![Camera27Settings sharedSettings].enabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (window.hidden || !window.rootViewController) continue;
            UIViewController *candidate = Camera27FindCameraController(window.rootViewController);
            if (candidate) [[Camera27UI sharedInstance] attachToController:candidate];
        }
    });
}

%ctor {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.camera"]) return;
    [Camera27Settings sharedSettings];
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) { Camera27TryInstall(); }];
    [center addObserverForName:UIWindowDidBecomeVisibleNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) { Camera27TryInstall(); }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ Camera27TryInstall(); });
}
