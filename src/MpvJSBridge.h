#import <JavaScriptCore/JavaScriptCore.h>

@protocol MpvJSBridge <JSExport>

JSExportAs( setPropertyString,
	- (void)setPropertyString:(NSString *)name value:(NSString *)value
);

- (NSString *)getPropertyString:(NSString *)name;

JSExportAs( getPropertyStringAsync,
	- (void)getPropertyStringAsync:(NSString *)name withCallback:(JSValue *)callback
);

- (void)command:(NSArray *)arguments;

@end
