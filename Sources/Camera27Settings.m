#import "Camera27Settings.h"

static void Camera27PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@implementation Camera27Settings
+ (instancetype)sharedSettings { static Camera27Settings *settings; static dispatch_once_t once; dispatch_once(&once, ^{ settings = [self new]; }); return settings; }
- (instancetype)init { if ((self = [super init])) { _enabled = YES; _glassEnabled = YES; _animationsEnabled = YES; _hapticsEnabled = YES; [self loadPreferences]; CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, Camera27PreferencesChanged, CFSTR(kCamera27PrefsChangedNotification), NULL, CFNotificationSuspensionBehaviorDeliverImmediately); } return self; }
- (void)loadPreferences { NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/jb/Library/Preferences/com.sanketyadav927.camera27.plist"]; if (!prefs) return; _enabled = [prefs[@"Enabled"] ?: @YES boolValue]; _glassEnabled = [prefs[@"GlassUI"] ?: @YES boolValue]; _animationsEnabled = [prefs[@"Animations"] ?: @YES boolValue]; _hapticsEnabled = [prefs[@"Haptics"] ?: @YES boolValue]; }
@end

static void Camera27PreferencesChanged(__unused CFNotificationCenterRef center, __unused void *observer, __unused CFStringRef name, __unused const void *object, __unused CFDictionaryRef userInfo) { [[Camera27Settings sharedSettings] loadPreferences]; }
