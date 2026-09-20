#import <Foundation/Foundation.h>

#define kCamera27PrefsDomain @"com.sanketyadav927.camera27"
#define kCamera27PrefsChangedNotification "com.sanketyadav927.camera27.prefschanged"

@interface Camera27Settings : NSObject
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL glassEnabled;
@property (nonatomic) BOOL animationsEnabled;
@property (nonatomic) BOOL hapticsEnabled;
+ (instancetype)sharedSettings;
- (void)loadPreferences;
@end
