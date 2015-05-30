#import <Cocoa/Cocoa.h>

@class VpmWindow;

@interface VpmDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, strong) VpmWindow *window;

@end
