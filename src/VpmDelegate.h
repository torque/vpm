#import <Cocoa/Cocoa.h>

@class VpmWindow;
@class VpmCLIServer;
@class VpmMpvController;

@interface VpmDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, strong) VpmWindow *window;
@property(nonatomic, strong) VpmCLIServer *server;
@property(nonatomic, strong) VpmMpvController *controller;

@end
