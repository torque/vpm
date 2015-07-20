#import <JavaScriptCore/JavaScriptCore.h>

@protocol MpvJSBridge <JSExport>

- (void)command:(NSArray *)arguments;

JSExportAs( commandAsync,
	- (void)commandAsync:(NSArray *)arguments withCallback:(JSValue *)callback
);

JSExportAs( setProperty,
	- (void)setProperty:(NSString *)name value:(NSString *)value
);

- (NSString *)getProperty:(NSString *)name;

- (BOOL)observeProperty:(NSString *)name;
- (void)unobserveProperty:(NSString *)name;

@end
