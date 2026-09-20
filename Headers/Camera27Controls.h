//
//  Camera27Controls.h
//  Camera27
//
//  Modern glassmorphic control buttons and top navigation pill.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Modern concentric Shutter Button
@interface Camera27ShutterButton : UIControl

@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) BOOL isVideoMode;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setRecording:(BOOL)recording animated:(BOOL)animated;
- (void)setIsVideoMode:(BOOL)isVideoMode animated:(BOOL)animated;

@end

// Modern Camera Flip Button
@interface Camera27FlipButton : UIButton
- (instancetype)initWithFrame:(CGRect)frame;
@end

// Live Photo Thumbnail Well
@interface Camera27ImageWell : UIButton
@property (nonatomic, strong, readonly) UIImageView *thumbnailImageView;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setThumbnailImage:(nullable UIImage *)image animated:(BOOL)animated;
- (void)loadRecentPhotoThumbnail;
@end

// Modern Top Navigation Pill Bar
@protocol Camera27TopBarDelegate <NSObject>
- (void)topBarDidTapFlash:(UIButton *)sender;
- (void)topBarDidTapLivePhoto:(UIButton *)sender;
- (void)topBarDidTapTimer:(UIButton *)sender;
@end

@interface Camera27TopBar : UIView

@property (nonatomic, weak, nullable) id<Camera27TopBarDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *flashButton;
@property (nonatomic, strong, readonly) UIButton *livePhotoButton;
@property (nonatomic, strong, readonly) UIButton *timerButton;
@property (nonatomic, strong, readonly) UILabel *statusBadgeLabel;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setFlashState:(NSInteger)state;
- (void)setLivePhotoActive:(BOOL)active;
- (void)setTimerDuration:(NSInteger)seconds;

@end

NS_ASSUME_NONNULL_END
