#import "VpmMpvController.h"

static inline void check_error( int status ) {
	if ( status < 0 ) {
		printf( "mpv API error: %s\n", mpv_error_string( status ) );
		exit(1);
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
		self.mpvQueue = dispatch_queue_create( "mpv", DISPATCH_QUEUE_SERIAL );

		// maybe run this in the mpv queue, so it doesn't slow down start up.
		self.mpv = mpv_create( );
		if ( !self.mpv ) {
			puts( "Failed to create mpv context." );
			// Actually handle the error?
		}
		// check error
		mpv_initialize( self.mpv );
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

	self.ctx[@"vpm"] = self;
}

- (void)loadVideo:(NSString *)fileName {
	dispatch_async( self.mpvQueue, ^{
		const char *cmd[] = { "loadfile", fileName.UTF8String, NULL };
		check_error( mpv_command( self.mpv, cmd ) );
	} );
}

- (void)handleEvent:(mpv_event *)event {
	switch (event->event_id) {
		case MPV_EVENT_LOG_MESSAGE: {
			struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
			NSLog( @"[%s] %s: %s", msg->prefix, msg->level, msg->text );
		}

		default: {
			NSLog( @"mpv event: %s", mpv_event_name(event->event_id) );
		}
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

- (void)setPropertyString:(NSString *)name value:(NSString *)value {
	dispatch_async( self.mpvQueue, ^{
		mpv_set_property_string( self.mpv, [name UTF8String], [value UTF8String] );
	} );
}

@end
