//
//  Camera27Settings.h
//  Camera27
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kCamera27PrefsChangedNotification "com.yourname.camera27.prefschanged"
#define kCamera27PrefsDomain @"com.yourname.camera27"

@interface Camera27Settings : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL liquidGlassEnabled;
@property (nonatomic, assign) BOOL animationsEnabled;
@property (nonatomic, assign) BOOL hapticsEnabled;
@property (nonatomic, assign) NSInteger appearanceMode; // 0=Dark, 1=Light, 2=System

+ (instancetype)sharedSettings;
- (void)loadPreferences;

@end

NS_ASSUME_NONNULL_END
