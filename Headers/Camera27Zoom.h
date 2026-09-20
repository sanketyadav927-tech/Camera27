//
//  Camera27Zoom.h
//  Camera27
//

#import <UIKit/UIKit.h>
#import "CameraPrivateHeaders.h"

NS_ASSUME_NONNULL_BEGIN

@class Camera27ZoomView;

@protocol Camera27ZoomViewDelegate <NSObject>
- (void)zoomView:(Camera27ZoomView *)zoomView didSelectZoomFactor:(CGFloat)factor;
@end

@interface Camera27ZoomView : UIView
@property (nonatomic, weak, nullable) id<Camera27ZoomViewDelegate> delegate;
@property (nonatomic, assign, readonly) CGFloat currentZoomFactor;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setSelectedZoomFactor:(CGFloat)factor animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
