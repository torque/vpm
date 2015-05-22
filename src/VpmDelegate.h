#import <Cocoa/Cocoa.h>

#import <mpv/client.h>

#import "VpmWindow.h"

@interface VpmDelegate : NSObject <NSApplicationDelegate>

@property mpv_handle *mpv;
@property(strong) dispatch_queue_t mpvQueue;
@property(nonatomic, strong) VpmWindow *window;

- (void)readEvents;

@end
