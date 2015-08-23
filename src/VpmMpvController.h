#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <mpv/client.h>

#import "MpvJSBridge.h"
@class VpmWindow;
@class VpmPropertyWrapper;

@interface VpmMpvController : NSObject <MpvJSBridge>

@property mpv_handle *mpv;
@property(nonatomic, strong) dispatch_queue_t mpvQueue;
@property(strong, readonly) NSDictionary *inputMap;
@property(strong) JSContext *ctx;
@property(weak) VpmWindow *window;
@property(strong) VpmPropertyWrapper *properties;

- (instancetype)init;
- (void)attachJSContext:(JSContext *)ctx;
- (void)loadVideo:(NSString *)fileName;
- (void)handleKeyEvent:(NSEvent *)theEvent;
- (void)handleEvent:(mpv_event *)event;
- (void)readEvents;
- (NSString *)getMpvProperty:(NSString *)name;
- (void)setMpvProperty:(NSString *)name toValue:(NSString *)value;
- (BOOL)observeMpvProperty:(NSString *)propertyName usingIndex:(NSInteger)index;
- (void)unobserveMpvProperty:(NSInteger)index;
- (void)toggleFullScreen;
- (void)destroy;

@end
