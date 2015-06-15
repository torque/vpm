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

JSExportAs( commandAsync,
	- (void)commandAsync:(NSArray *)arguments withCallback:(JSValue *)callback
);

JSExportAs( observeProperty,
	- (void)observeProperty:(NSString *)propertyName withIndex:(NSNumber *)index
);

// Probably should replace this with a generic interface for vpm properties, but
// I can't actually think of any others at the moment, so that'll be deferred
// until it's actually useful.
- (void)toggleFullScreen;
- (void)setFullScreenCallback:(JSValue *)callback;

@end
