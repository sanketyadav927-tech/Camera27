#import <UIKit/UIKit.h>

@interface Camera27UI : NSObject
+ (instancetype)sharedInstance;
- (void)attachToController:(UIViewController *)controller;
@end
