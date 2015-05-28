#import <JavaScriptCore/JavaScriptCore.h>

@protocol MpvJSBridge <JSExport>

- (void)setPropertyString:(NSString *)name value:(NSString *)value;

@end
