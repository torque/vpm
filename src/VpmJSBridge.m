#import "VpmJSBridge.h"

@implementation VpmJSBridge

- (instancetype)initWithMpv:(mpv_handle *)mpv
                      queue:(dispatch_queue_t)mpvQueue
{
	self = [super init];
	if ( self ) {
		_mpv = mpv;
		_mpvQueue = mpvQueue;
	}
	return self;
}

- (void)setPropertyString:(NSString *)name value:(NSString *)value {
	const char *name_c = strdup([name UTF8String]);
	const char *value_c = strdup([value UTF8String]);
	dispatch_async( self.mpvQueue, ^{
		mpv_set_property( self.mpv, name_c,
		                  MPV_FORMAT_STRING, (void *)&value_c);
		free( name_c );
		free( value_c );
	} );
}

@end
