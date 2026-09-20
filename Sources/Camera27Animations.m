//
//  Camera27Animations.m
//  Camera27
//

#import "Camera27Animations.h"
#import "Camera27Settings.h"

@implementation Camera27Animations

+ (void)playLightHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [g prepare]; [g impactOccurred];
    });
}

+ (void)playMediumHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [g prepare]; [g impactOccurred];
    });
}

+ (void)playRigidHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
        [g prepare]; [g impactOccurred];
    });
}

+ (void)playSuccessHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UINotificationFeedbackGenerator *g = [UINotificationFeedbackGenerator new];
        [g prepare]; [g notificationOccurred:UINotificationFeedbackTypeSuccess];
    });
}

+ (void)animateSpringWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations completion:(void(^ _Nullable)(BOOL))completion {
    if (![Camera27Settings sharedSettings].animationsEnabled) {
        if (animations) animations();
        if (completion) completion(YES);
        return;
    }
    [UIView animateWithDuration:duration delay:0
         usingSpringWithDamping:0.75 initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:animations completion:completion];
}

+ (void)pulseView:(UIView *)view scale:(CGFloat)scale duration:(NSTimeInterval)duration {
    if (!view || ![Camera27Settings sharedSettings].animationsEnabled) return;
    [UIView animateWithDuration:duration * 0.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        view.transform = CGAffineTransformMakeScale(scale, scale);
    } completion:^(BOOL f) {
        [UIView animateWithDuration:duration * 0.65 delay:0 usingSpringWithDamping:0.55
          initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseIn animations:^{
            view.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

+ (void)rotateFlipButton:(UIView *)view completion:(void(^ _Nullable)(void))completion {
    if (!view) return;
    [self playLightHaptic];
    if (![Camera27Settings sharedSettings].animationsEnabled) { if (completion) completion(); return; }
    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1.0 / 500.0;
    [UIView animateWithDuration:0.38 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.layer.transform = CATransform3DRotate(t, M_PI, 0, 1, 0);
    } completion:^(BOOL f) {
        view.layer.transform = CATransform3DIdentity;
        if (completion) completion();
    }];
}

@end
