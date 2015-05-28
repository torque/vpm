#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <mpv/client.h>

#import "MpvJSBridge.h"

@interface VpmMpvController : NSObject <MpvJSBridge>

@property mpv_handle *mpv;
@property(nonatomic, strong) dispatch_queue_t mpvQueue;
@property(weak) JSContext *ctx;

- (instancetype)initWithJSContext:(JSContext *)ctx;
- (void)attachJS;
- (void)loadVideo:(NSString *)fileName;
- (void)handleEvent:(mpv_event *)event;
- (void)readEvents;
- (void)destroy;

#pragma mark - MpvJSBridge
- (void)setPropertyString:(NSString *)name value:(NSString *)value;
@end
