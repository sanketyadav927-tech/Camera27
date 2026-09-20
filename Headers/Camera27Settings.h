//
//  Camera27Settings.h
//  Camera27
//
//  Preferences manager supporting rootless Dopamine environment.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kCamera27PrefsChangedNotification "com.yourname.camera27.prefschanged"

@interface Camera27Settings : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL glassUIEnabled;
@property (nonatomic, assign) BOOL animationsEnabled;
@property (nonatomic, assign) BOOL hapticsEnabled;
@property (nonatomic, assign) NSInteger appearanceMode; // 0 = Dark, 1 = Light, 2 = System

+ (instancetype)sharedSettings;
- (void)loadPreferences;
- (void)registerForPreferenceChanges;

@end

NS_ASSUME_NONNULL_END
