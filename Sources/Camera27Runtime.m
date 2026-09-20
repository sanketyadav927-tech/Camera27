#import "Camera27Runtime.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>

static void Camera27AppendDiagnostic(NSString *message) {
    NSString *path = @"/var/mobile/Library/Logs/Camera27.log";
    NSString *line = [NSString stringWithFormat:@"%@ %@\n", NSDate.date, message];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle) {
        [line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        return;
    }
    [handle seekToEndOfFile];
    [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

static NSArray<UIView *> *Camera27AllViews(UIView *root) {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *pending = [NSMutableArray arrayWithObject:root];
    while (pending.count) { UIView *view = pending.lastObject; [pending removeLastObject]; [result addObject:view]; [pending addObjectsFromArray:view.subviews]; }
    return result;
}

static NSArray<NSString *> *Camera27Keywords(Camera27Action action) {
    switch (action) {
        case Camera27ActionShutter: return @[@"shutter", @"capture", @"takephoto"];
        case Camera27ActionFlip: return @[@"flip", @"switchcamera", @"camera switch"];
        case Camera27ActionGallery: return @[@"imagewell", @"thumbnail", @"recent", @"photo library"];
        case Camera27ActionFlash: return @[@"flash"];
        case Camera27ActionLivePhoto: return @[@"livephoto", @"live photo"];
        case Camera27ActionTimer: return @[@"timer"];
    }
    return @[];
}

static UIControl *Camera27FindControl(UIViewController *controller, Camera27Action action) {
    for (UIView *view in Camera27AllViews(controller.view)) {
        if (![view isKindOfClass:UIControl.class] || [NSStringFromClass(view.class) containsString:@"Camera27"]) continue;
        NSString *text = [NSString stringWithFormat:@"%@ %@ %@", NSStringFromClass(view.class), view.accessibilityIdentifier ?: @"", view.accessibilityLabel ?: @""].lowercaseString;
        for (NSString *keyword in Camera27Keywords(action)) if ([text containsString:keyword]) return (UIControl *)view;
    }
    return nil;
}

UIViewController *Camera27FindCameraController(UIViewController *root) {
    if (!root) return nil;
    if (Camera27ControllerIsSupported(root)) return root;
    for (UIViewController *child in root.childViewControllers) { UIViewController *found = Camera27FindCameraController(child); if (found) return found; }
    if (root.presentedViewController) return Camera27FindCameraController(root.presentedViewController);
    return nil;
}

BOOL Camera27ControllerIsSupported(UIViewController *controller) {
    if (!controller.isViewLoaded) return NO;
    return Camera27FindControl(controller, Camera27ActionShutter) && Camera27FindControl(controller, Camera27ActionFlip) && Camera27FindControl(controller, Camera27ActionGallery);
}

BOOL Camera27PerformAction(UIViewController *controller, Camera27Action action) {
    UIControl *control = Camera27FindControl(controller, action);
    if (!control) return NO;
    [control sendActionsForControlEvents:UIControlEventTouchUpInside];
    return YES;
}

BOOL Camera27PerformNamedMode(UIViewController *controller, NSString *modeName) {
    NSString *wanted = modeName.lowercaseString;
    for (UIView *view in Camera27AllViews(controller.view)) {
        if (![view isKindOfClass:UIControl.class]) continue;
        if ([NSStringFromClass(view.class) containsString:@"Camera27"]) continue;
        UIControl *control = (UIControl *)view;
        NSString *text = [NSString stringWithFormat:@"%@ %@ %@", control.accessibilityIdentifier ?: @"", control.accessibilityLabel ?: @"", [(id)control titleForState:UIControlStateNormal] ?: @""].lowercaseString;
        if ([text containsString:wanted]) { [control sendActionsForControlEvents:UIControlEventTouchUpInside]; return YES; }
    }
    return NO;
}

BOOL Camera27SetZoom(UIViewController *controller, CGFloat zoom) {
    for (UIView *view in Camera27AllViews(controller.view)) {
        SEL selector = NSSelectorFromString(@"setZoomFactor:");
        if (![view respondsToSelector:selector]) continue;
        NSMethodSignature *signature = [view methodSignatureForSelector:selector];
        if (!signature || signature.numberOfArguments != 3) continue;
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature]; invocation.target = view; invocation.selector = selector; [invocation setArgument:&zoom atIndex:2]; [invocation invoke]; return YES;
    }
    return NO;
}

BOOL Camera27HasTelephotoCamera(void) {
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        for (AVCaptureDevice *device in session.devices) if (device.deviceType == AVCaptureDeviceTypeBuiltInTelephotoCamera) return YES;
    }
    return NO;
}

void Camera27HideVerifiedStockChrome(UIViewController *controller) {
    for (Camera27Action action = Camera27ActionShutter; action <= Camera27ActionTimer; action++) {
        UIControl *control = Camera27FindControl(controller, action); if (!control) continue;
        UIView *candidate = control;
        while (candidate.superview && candidate.superview != controller.view && candidate.bounds.size.height < 170.0) candidate = candidate.superview;
        NSString *name = NSStringFromClass(candidate.class).lowercaseString;
        if (candidate != controller.view && ([name containsString:@"bar"] || [name containsString:@"control"] || [name containsString:@"drawer"] || candidate.bounds.size.height < 170.0)) { candidate.hidden = YES; candidate.userInteractionEnabled = NO; }
        else { control.hidden = YES; control.userInteractionEnabled = NO; }
    }
}

void Camera27LogDiagnosticReport(UIViewController *controller) {
    NSLog(@"[Camera27] controller=%@", NSStringFromClass(controller.class));
    Camera27AppendDiagnostic([NSString stringWithFormat:@"controller=%@", NSStringFromClass(controller.class)]);
    for (UIView *view in Camera27AllViews(controller.view)) {
        if (![view isKindOfClass:UIControl.class]) continue;
        UIControl *control = (UIControl *)view;
        NSLog(@"[Camera27] control=%@ id=%@ label=%@ targets=%@", NSStringFromClass(control.class), control.accessibilityIdentifier, control.accessibilityLabel, control.allTargets);
        Camera27AppendDiagnostic([NSString stringWithFormat:@"control=%@ id=%@ label=%@ targets=%@", NSStringFromClass(control.class), control.accessibilityIdentifier, control.accessibilityLabel, control.allTargets]);
    }
}
