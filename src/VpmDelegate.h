#import <Cocoa/Cocoa.h>

@class VpmWindow;
@class VpmCLIServer;

@interface VpmDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, strong) VpmWindow *window;
@property(nonatomic, strong) VpmCLIServer *server;

@end
