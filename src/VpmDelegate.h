#import <Cocoa/Cocoa.h>

#import <mpv/client.h>

#import "VpmWindow.h"

@interface VpmDelegate : NSObject <NSApplicationDelegate>

@property mpv_handle *mpv;
@property(retain) dispatch_queue_t mpvQueue;
@property(retain) VpmWindow *window;

- (void)readEvents;

@end
