//
//  Camera27Settings.m
//  Camera27
//

#import "Camera27Settings.h"
#import <notify.h>

@implementation Camera27Settings

+ (instancetype)sharedSettings {
    static Camera27Settings *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Camera27Settings alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Defaults
        _enabled = YES;
        _glassUIEnabled = YES;
        _animationsEnabled = YES;
        _hapticsEnabled = YES;
        _appearanceMode = 0; // Dark mode by default

        [self loadPreferences];
        [self registerForPreferenceChanges];
    }
    return self;
}

- (void)loadPreferences {
    // Check rootless preferences path first, then fallback to standard path
    NSString *rootlessPath = @"/var/jb/Library/Preferences/com.yourname.camera27.plist";
    NSString *standardPath = @"/var/mobile/Library/Preferences/com.yourname.camera27.plist";
    
    NSString *activePath = rootlessPath;
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootlessPath]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:standardPath]) {
            activePath = standardPath;
        }
    }

    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:activePath];
    if (prefs) {
        if (prefs[@"Enabled"] != nil) {
            self.enabled = [prefs[@"Enabled"] boolValue];
        }
        if (prefs[@"GlassUI"] != nil) {
            self.glassUIEnabled = [prefs[@"GlassUI"] boolValue];
        }
        if (prefs[@"Animations"] != nil) {
            self.animationsEnabled = [prefs[@"Animations"] boolValue];
        }
        if (prefs[@"Haptics"] != nil) {
            self.hapticsEnabled = [prefs[@"Haptics"] boolValue];
        }
        if (prefs[@"Appearance"] != nil) {
            self.appearanceMode = [prefs[@"Appearance"] integerValue];
        }
    }
}

static void prefsNotificationCallback(CFNotificationCenterRef center,
                                      void *observer,
                                      CFStringRef name,
                                      const void *object,
                                      CFDictionaryRef userInfo) {
    [[Camera27Settings sharedSettings] loadPreferences];
}

- (void)registerForPreferenceChanges {
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        prefsNotificationCallback,
        CFSTR(kCamera27PrefsChangedNotification),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}

@end
