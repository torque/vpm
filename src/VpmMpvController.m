#import "VpmMpvController.h"
#import "VpmWindow.h"

enum observed_properties {
	DWIDTH_OBSERVATION = 1,
	JS_OBSERVED_PROPERTY_OFFSET
};

static inline void check_error( int status ) {
	if ( status < 0 ) {
		printf( "mpv API error: %s\n", mpv_error_string( status ) );
	}
}

static void wakeup( void *ctx ) {
	VpmMpvController *controller = (__bridge VpmMpvController *)ctx;
	[controller readEvents];
}

@implementation VpmMpvController

- (instancetype)initWithJSContext:(JSContext *)ctx {
	self = [super init];
	if ( self ) {
		self.ctx = ctx;
		self.fileLoaded = false;
		self.mpvQueue = dispatch_queue_create( "mpv", DISPATCH_QUEUE_SERIAL );

		self.eventIndices = [NSMutableArray new];

		self.mpv = mpv_create( );
		if ( !self.mpv ) {
			puts( "Failed to create mpv context." );
			// Actually handle the error?
		}
		// check error
		mpv_initialize( self.mpv );
		mpv_observe_property( self.mpv, DWIDTH_OBSERVATION, "dwidth", MPV_FORMAT_INT64 );
		mpv_set_wakeup_callback( self.mpv, wakeup, (__bridge void *)self );
		[self attachJS];
	}
	return self;
}

- (void)attachJS {
	// poor man's error reporting. self.ctx.exceptionHandler doesn't catch
	// exceptions thrown from the javascript executed by a loaded page.
	// Unfortunately, webkit does not pass a stack trace to this listener,
	// so a better system should probably be devised.
	self.ctx[@"window"][@"onerror"] = ^( NSString *msg, NSString *url, NSNumber *line, NSNumber *col ) {
		NSLog( @"%@:%d:%d - %@", url, [line intValue], [col intValue], msg );
	};
	self.ctx[@"console"][@"log"] = ^(NSString *msg) {
		NSLog( @"Javascript: %@", msg );
	};
	self.ctx[@"vpm"] = self;
}

- (void)loadVideo:(NSString *)fileName {
	[self command:@[@"loadfile", fileName]];
}

- (void)handleEvent:(mpv_event *)event {
	switch (event->event_id) {
		case MPV_EVENT_LOG_MESSAGE: {
			struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
			NSLog( @"[%s] %s: %s", msg->prefix, msg->level, msg->text );
			break;
		}

		case MPV_EVENT_PROPERTY_CHANGE: {
			switch (event->reply_userdata) {
				case DWIDTH_OBSERVATION: {
					dispatch_async( self.mpvQueue, ^{
						if ( self.mpv && self.fileLoaded ) {
							int64_t width, height;
							mpv_get_property( self.mpv, "video-params/dw", MPV_FORMAT_INT64, &width );
							mpv_get_property( self.mpv, "video-params/dh", MPV_FORMAT_INT64, &height );
							NSLog(@"resize");
							// This is necessary because the resize will launch from
							// whatever thread it was launched from, which can cause a
							// crash.
							dispatch_async( dispatch_get_main_queue( ), ^{
								[self.window constrainedCenteredResize:NSMakeSize( width, height )];
							} );
						}
					} );
					break;
				}
				default: {
					int eventIndex = event->reply_userdata - JS_OBSERVED_PROPERTY_OFFSET;
					if ( event->reply_userdata >= JS_OBSERVED_PROPERTY_OFFSET && eventIndex < [self.eventIndices count]) {
						[self sendJSEvent:eventIndex];
					}
				}
			}
			break;
		}

		case MPV_EVENT_START_FILE: {
			self.fileLoaded = true;
			break;
		}

		case MPV_EVENT_END_FILE: {
			self.fileLoaded = false;
			break;
		}

		default: {}
	}
}

- (void)sendJSEvent:(int)index {
	// dispatch js event. function signature is ( index, data ),
	// and data is always a string.
	char *value = mpv_get_property_string( self.mpv, [self.eventIndices[index] UTF8String] );
	NSString *res = value? [NSString stringWithCString:value encoding:NSUTF8StringEncoding]: nil;
	mpv_free(value);
	if (res) {
		// for mystery reasons that are probably very important, setTimeout
		// can only be called if this is run on the main thread.
		dispatch_async( dispatch_get_main_queue( ), ^{
			[self.ctx[@"window"][@"signalMpvEvent"] callWithArguments:@[@(index), res]];
		} );
	}
}

- (void)readEvents {
	dispatch_async( self.mpvQueue, ^{
		while ( self.mpv ) {
			mpv_event *event = mpv_wait_event( self.mpv, 0 );
			if ( event->event_id == MPV_EVENT_NONE )
				break;
			[self handleEvent:event];
		}
	} );
}

- (void)destroy {
	mpv_unobserve_property( self.mpv, DWIDTH_OBSERVATION );
	dispatch_sync( self.mpvQueue, ^{
		mpv_terminate_destroy( self.mpv );
		// have to set self.mpv explicitly to nil because the wakeup
		// callback will queue events in this dispatch queue that will not
		// run until after this block is finished. This happens whether or
		// not the termination happens in the mpv queue, but is far less
		// deterministic if it doesn't.
		self.mpv = nil;
	} );
}

#pragma mark - MpvJSBridge

- (void)observeProperty:(NSString *)propertyName withIndex:(NSNumber *)index {
	int idx = [index intValue];
	self.eventIndices[idx] = propertyName;
	mpv_observe_property( self.mpv, JS_OBSERVED_PROPERTY_OFFSET + idx, propertyName.UTF8String, MPV_FORMAT_STRING );
}

- (void)setPropertyString:(NSString *)name value:(NSString *)value {
	dispatch_async( self.mpvQueue, ^{
		if ( self.mpv )
			mpv_set_property_string( self.mpv, [name UTF8String], [value UTF8String] );
	} );
}

- (NSString *)getPropertyString:(NSString *)name {
	if ( self.mpv ) {
		char *str = mpv_get_property_string( self.mpv, [name UTF8String] );
		NSString *res = str? [NSString stringWithCString:str encoding:NSUTF8StringEncoding]: nil;
		mpv_free( str );
		return res;
	}
	return nil;
}

- (void)getPropertyStringAsync:(NSString *)name withCallback:(JSValue *)callback {
	dispatch_async( self.mpvQueue, ^{
		if ( self.mpv ) {
			char *str = mpv_get_property_string( self.mpv, [name UTF8String] );
			NSString *res = str? [NSString stringWithCString:str encoding:NSUTF8StringEncoding]: nil;
			mpv_free( str );
			// har har this doesn't work because executing the callback on a
			// different thread causes big problems everywhere. Sometimes.
			[callback callWithArguments:@[res]];
		}
	} );
}

// jsexport is kind enough to convert all array members to NS-types
- (void)command:(NSArray *)arguments {
	const char **cmd = calloc( [arguments count] + 1, sizeof(*cmd) );
	for ( int i = 0; i < [arguments count]; i++ ) {
		cmd[i] = [arguments[i] UTF8String];
	}
	check_error( mpv_command( self.mpv, cmd ) );
	free( cmd );
}

// jsexport is kind enough to convert all array members to NS-types
- (void)commandAsync:(NSArray *)arguments withCallback:(JSValue *)callback {
	dispatch_async( self.mpvQueue, ^{
		if ( self.mpv ) {
			const char **cmd = calloc( [arguments count] + 1, sizeof(*cmd) );
			for ( int i = 0; i < [arguments count]; i++ ) {
				cmd[i] = [arguments[i] UTF8String];
			}
			check_error( mpv_command( self.mpv, cmd ) );
			free( cmd );

			if ( callback ) {
				dispatch_async( dispatch_get_main_queue( ), ^{
					[self.ctx[@"setTimeout"] callWithArguments:@[callback, @0]];
				} );
			}

		}
	} );
}

@end
