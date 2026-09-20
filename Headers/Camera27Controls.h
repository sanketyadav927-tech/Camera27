//
//  Camera27Controls.h
//  Camera27
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// ---------------------------------------------------------------------------
// MARK: - Camera27ShutterButton
// ---------------------------------------------------------------------------

@interface Camera27ShutterButton : UIControl
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) BOOL isVideoMode;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setRecording:(BOOL)recording animated:(BOOL)animated;
- (void)setIsVideoMode:(BOOL)isVideoMode animated:(BOOL)animated;
@end

// ---------------------------------------------------------------------------
// MARK: - Camera27FlipButton
// ---------------------------------------------------------------------------

@interface Camera27FlipButton : UIButton
- (instancetype)initWithFrame:(CGRect)frame;
@end

// ---------------------------------------------------------------------------
// MARK: - Camera27ImageWell
// ---------------------------------------------------------------------------

@interface Camera27ImageWell : UIButton
@property (nonatomic, strong, readonly) UIImageView *thumbnailImageView;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setThumbnailImage:(nullable UIImage *)image animated:(BOOL)animated;
- (void)loadRecentPhotoThumbnail;
@end

// ---------------------------------------------------------------------------
// MARK: - Camera27TopBar
// ---------------------------------------------------------------------------

@protocol Camera27TopBarDelegate <NSObject>
- (void)topBarDidTapFlash:(UIButton *)sender;
- (void)topBarDidTapLivePhoto:(UIButton *)sender;
- (void)topBarDidTapTimer:(UIButton *)sender;
- (void)topBarDidTapHDR:(UIButton *)sender;
@end

@interface Camera27TopBar : UIView
@property (nonatomic, weak, nullable) id<Camera27TopBarDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *flashButton;
@property (nonatomic, strong, readonly) UIButton *livePhotoButton;
@property (nonatomic, strong, readonly) UIButton *timerButton;
@property (nonatomic, strong, readonly) UIButton *hdrButton;
@property (nonatomic, strong, readonly) UILabel  *statusBadge;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setFlashState:(NSInteger)state;        // 0=off, 1=on, 2=auto
- (void)setLivePhotoActive:(BOOL)active;
- (void)setTimerDuration:(NSInteger)seconds;   // 0, 3, 10
- (void)setHDREnabled:(BOOL)enabled;
@end

NS_ASSUME_NONNULL_END
