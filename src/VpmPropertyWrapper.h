@import Foundation;
#import <mpv/client.h>

typedef void (^ValueChangedCallback)(NSString *name, NSString *value, NSString *oldValue);

@class VpmMpvController;

@interface VpmPropertyWrapper : NSObject

@property(weak) VpmMpvController *controller;

- (instancetype)initWithMpvController:(VpmMpvController*)controller;
- (void)handleMpvPropertyChange:(mpv_event_property*)property;

- (void)addJSCallbackForProperty:(NSString *)name;
- (void)removeJSCallbackForProperty:(NSString *)name;

- (NSString *)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(NSString *)obj forKeyedSubscript:(NSString *)key;
- (void)observeProperty:(NSString *)name withCallback:(ValueChangedCallback)callback;
- (void)unobserveProperty:(NSString *)name withCallback:(ValueChangedCallback)callback;

- (void)destroy;

@end
