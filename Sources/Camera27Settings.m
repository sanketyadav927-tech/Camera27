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
    dispatch_once(&onceToken, ^{ shared = [Camera27Settings new]; });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled           = YES;
        _liquidGlassEnabled = YES;
        _animationsEnabled = YES;
        _hapticsEnabled    = YES;
        _appearanceMode    = 0;
        [self loadPreferences];
        [self _registerForChanges];
    }
    return self;
}

- (void)loadPreferences {
    // Try rootless path first, fall back to standard
    NSString *paths[] = {
        @"/var/jb/Library/Preferences/com.yourname.camera27.plist",
        @"/var/mobile/Library/Preferences/com.yourname.camera27.plist"
    };
    NSDictionary *prefs = nil;
    for (int i = 0; i < 2; i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:paths[i]]) {
            prefs = [NSDictionary dictionaryWithContentsOfFile:paths[i]];
            if (prefs) break;
        }
    }
    if (!prefs) return;
    if (prefs[@"Enabled"])      self.enabled           = [prefs[@"Enabled"] boolValue];
    if (prefs[@"LiquidGlass"])  self.liquidGlassEnabled = [prefs[@"LiquidGlass"] boolValue];
    if (prefs[@"Animations"])   self.animationsEnabled = [prefs[@"Animations"] boolValue];
    if (prefs[@"Haptics"])      self.hapticsEnabled    = [prefs[@"Haptics"] boolValue];
    if (prefs[@"Appearance"])   self.appearanceMode    = [prefs[@"Appearance"] integerValue];
}

static void _prefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef i) {
    [[Camera27Settings sharedSettings] loadPreferences];
}

- (void)_registerForChanges {
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), NULL, _prefsChanged,
        CFSTR(kCamera27PrefsChangedNotification), NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}

@end
