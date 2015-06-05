#import <JavaScriptCore/JavaScriptCore.h>

@protocol MpvJSBridge <JSExport>

- (void)setPropertyString:(NSString *)name value:(NSString *)value;
- (NSString *)getPropertyString:(NSString *)name;
- (void)getPropertyStringAsync:(NSString *)name withCallback:(JSValue *)callback;
- (void)command:(NSArray *)arguments;

@end
