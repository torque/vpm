#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <mpv/client.h>

@protocol MpvJSBridge <JSExport>

- (void)setPropertyString:(NSString *)name value:(NSString *)value;

@end

@interface VpmJSBridge : NSObject <MpvJSBridge>

@property mpv_handle *mpv;
@property(nonatomic, strong) dispatch_queue_t mpvQueue;

- (instancetype)initWithMpv:(mpv_handle *)mpv
                      queue:(dispatch_queue_t)mpvQueue;

@end
