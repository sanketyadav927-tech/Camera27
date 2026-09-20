//
//  Camera27Animations.m
//  Camera27
//

#import "Camera27Animations.h"
#import "Camera27Settings.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation Camera27Animations

+ (void)playLightHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen prepare];
        [gen impactOccurred];
    });
}

+ (void)playMediumHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [gen prepare];
        [gen impactOccurred];
    });
}

+ (void)playRigidHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
        [gen prepare];
        [gen impactOccurred];
    });
}

+ (void)playSuccessHaptic {
    if (![Camera27Settings sharedSettings].hapticsEnabled) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UINotificationFeedbackGenerator *gen = [[UINotificationFeedbackGenerator alloc] init];
        [gen prepare];
        [gen notificationOccurred:UINotificationFeedbackTypeSuccess];
    });
}

+ (void)animateSpringWithDuration:(NSTimeInterval)duration
                       animations:(void (^)(void))animations
                       completion:(nullable void (^)(BOOL finished))completion {
    if (![Camera27Settings sharedSettings].animationsEnabled) {
        if (animations) animations();
        if (completion) completion(YES);
        return;
    }

    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:animations
                     completion:completion];
}

+ (void)pulseView:(UIView *)view scale:(CGFloat)scale duration:(NSTimeInterval)duration {
    if (!view) return;
    if (![Camera27Settings sharedSettings].animationsEnabled) return;

    [UIView animateWithDuration:duration * 0.4
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        view.transform = CGAffineTransformMakeScale(scale, scale);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration * 0.6
                              delay:0
             usingSpringWithDamping:0.6
              initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            view.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

+ (void)rotateFlipButton:(UIView *)view completion:(nullable void (^)(void))completion {
    if (!view) return;
    [self playLightHaptic];

    if (![Camera27Settings sharedSettings].animationsEnabled) {
        if (completion) completion();
        return;
    }

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        view.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    } completion:^(BOOL finished) {
        view.layer.transform = CATransform3DIdentity;
        if (completion) completion();
    }];
}

@end
