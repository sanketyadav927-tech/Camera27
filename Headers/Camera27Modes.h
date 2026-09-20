//
//  Camera27Modes.h
//  Camera27
//

#import <UIKit/UIKit.h>
#import "CameraPrivateHeaders.h"

NS_ASSUME_NONNULL_BEGIN

@class Camera27ModeSwitcher;

@protocol Camera27ModeSwitcherDelegate <NSObject>
- (void)modeSwitcher:(Camera27ModeSwitcher *)switcher didSelectMode:(CAMMode)mode;
@end

@interface Camera27ModeSwitcher : UIView
@property (nonatomic, weak, nullable) id<Camera27ModeSwitcherDelegate> delegate;
@property (nonatomic, assign, readonly) CAMMode currentMode;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setSelectedMode:(CAMMode)mode animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
