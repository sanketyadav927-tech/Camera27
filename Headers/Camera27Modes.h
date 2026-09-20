//
//  Camera27Modes.h
//  Camera27
//
//  Mode selector bar for iPhone 8 Plus native camera modes.
//

#import <UIKit/UIKit.h>
#import "CameraPrivateHeaders.h"

NS_ASSUME_NONNULL_BEGIN

@class Camera27ModeSwitcher;

@protocol Camera27ModeSwitcherDelegate <NSObject>
- (void)modeSwitcher:(Camera27ModeSwitcher *)modeSwitcher didSelectMode:(CAMMode)mode;
@end

@interface Camera27ModeSwitcher : UIView

@property (nonatomic, weak, nullable) id<Camera27ModeSwitcherDelegate> delegate;
@property (nonatomic, assign) CAMMode currentMode;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setSelectedMode:(CAMMode)mode animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
