//
//  Camera27Zoom.h
//  Camera27
//
//  Zoom selector tailored for iPhone 8 Plus (1× Wide, 2× Telephoto).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Camera27ZoomView;

@protocol Camera27ZoomViewDelegate <NSObject>
- (void)zoomView:(Camera27ZoomView *)zoomView didSelectZoomFactor:(CGFloat)zoomFactor;
@end

@interface Camera27ZoomView : UIView

@property (nonatomic, weak, nullable) id<Camera27ZoomViewDelegate> delegate;
@property (nonatomic, assign) CGFloat currentZoomFactor;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateAvailableLenses;
- (void)setSelectedZoomFactor:(CGFloat)factor animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
