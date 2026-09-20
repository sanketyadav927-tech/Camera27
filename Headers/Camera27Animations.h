//
//  Camera27Animations.h
//  Camera27
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Camera27Animations : NSObject

+ (void)playLightHaptic;
+ (void)playMediumHaptic;
+ (void)playRigidHaptic;
+ (void)playSuccessHaptic;

+ (void)animateSpringWithDuration:(NSTimeInterval)duration
                       animations:(void(^)(void))animations
                       completion:(void(^ _Nullable)(BOOL finished))completion;

+ (void)pulseView:(UIView *)view scale:(CGFloat)scale duration:(NSTimeInterval)duration;
+ (void)rotateFlipButton:(UIView *)view completion:(void(^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
