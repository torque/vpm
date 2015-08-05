#import <WebKit/WebKit.h>

#import "CommonLog.h"
#import "VpmMpvController.h"
#import "VpmWindow.h"
#import "VpmPropertyWrapper.h"

static inline void check_error( int status ) {
	if ( status < 0 ) {
		DDLogWarn( @"mpv API error: %s\n", mpv_error_string( status ) );
	}
}

static void wakeup( void *ctx ) {
	VpmMpvController *controller = (__bridge VpmMpvController *)ctx;
	[controller readEvents];
}

static const NSEventModifierFlags flaglist[] = {
	NSAlphaShiftKeyMask, // caps lock, apparently?
	NSShiftKeyMask,
	NSControlKeyMask,
	NSAlternateKeyMask,
	NSCommandKeyMask,
};

static NSString *flagNames[] = {
	@"Shift+",
	@"Shift+",
	@"Ctrl+",
	@"Alt+",
	@"Meta+",
};

#pragma mark - VpmMpvController Private Category

@interface VpmMpvController()

@property(strong) NSDictionary *inputMap;

@end

#pragma mark - VpmMpvController Implementation

@implementation VpmMpvController

- (instancetype)initWithJSContext:(JSContext *)ctx {
	if ( self = [super init] ) {
		self.ctx = ctx;
		self.mpvQueue = dispatch_queue_create( "org.unorg.vpm.mpv", DISPATCH_QUEUE_SERIAL );
		self.inputMap = @{
			// various unprintable keys are mapped to private-use unicode values.
			@"\uF700": @"UP",
			@"\uF701": @"DOWN",
			@"\uF702": @"LEFT",
			@"\uF703": @"RIGHT",
			@"\uF72C": @"PGUP",
			@"\uF72D": @"PGDWN",
			@"\uF729": @"HOME",
			@"\uF72B": @"END",
			@"\uF728": @"DEL",
			@"\uF704": @"F1",
			@"\uF705": @"F2",
			@"\uF706": @"F3",
			@"\uF707": @"F4",
			@"\uF708": @"F5",
			@"\uF709": @"F6",
			@"\uF70A": @"F7",
			@"\uF70B": @"F8",
			@"\uF70C": @"F9",
			@"\uF70D": @"F10",
			@"\uF70E": @"F11",
			@"\uF70F": @"F12",
			@" ": @"SPACE",
			@"#": @"SHARP",
			@"\t": @"TAB",
			@"\033": @"ESC",
			@"\177": @"BS",
		};

		self.mpv = mpv_create( );
		if ( !self.mpv ) {
			DDLogError( @"Failed to create mpv context." );
			// top tier error handling
			exit( 1 );
		}
		// check error
		mpv_set_option_string( self.mpv, "msg-level", "trace" );
		mpv_set_option_string( self.mpv, "terminal", "yes" );
		mpv_set_option_string( self.mpv, "config", "yes" );
		mpv_set_option_string( self.mpv, "load-scripts", "no" );

		self.properties = [[VpmPropertyWrapper alloc] initWithMpvController:self];
		// this can't really go in VpmWindow conveniently due to the use of
		// getMpvProperty.
		[self.properties observeProperty:@"dwidth" withCallback:^(NSString* name, NSString *value, NSString *oldValue) {
			CGFloat width = value.doubleValue;
			CGFloat height = [self getMpvProperty:@"dheight"].doubleValue;
			dispatch_async( dispatch_get_main_queue( ), ^{
				[self.window constrainedCenteredResize:NSMakeSize( width, height )];
			});
		}];
		// for some reason toggleFullScreen does nothing when sent by the window to
		// itself.
		[self.properties observeProperty:@"fullscreen" withCallback:^(NSString *name, NSString *value, NSString *oldValue) {
			dispatch_async( dispatch_get_main_queue( ), ^{
				[self.window toggleFullScreen:self.window];
			} );
		}];
		[self attachJS];

		mpv_set_wakeup_callback( self.mpv, wakeup, (__bridge void *)self );
		mpv_initialize( self.mpv );
	}
	return self;
}

- (void)attachJS {
	// poor man's error reporting. self.ctx.exceptionHandler doesn't catch
	// exceptions thrown from the javascript executed by a loaded page.
	// Unfortunately, webkit does not pass a stack trace to this listener,
	// so a better system should probably be devised.
	self.ctx[@"window"][@"onerror"] = ^(NSString *msg, NSString *url, NSNumber *line, NSNumber *col) {
		DDLogWarn( @"%@:%d:%d - %@", url, [line intValue], [col intValue], msg );
	};
	self.ctx[@"console"][@"log"] = ^(NSString *msg) {
		DDLogDebug( @"JS: %@", msg );
	};
	self.ctx[@"vpm"] = self;
}

- (void)loadVideo:(NSString *)fileName {
	[self command:@[@"loadfile", fileName]];
}

- (void)handleKeyEvent:(NSEvent *)theEvent {
	NSEventModifierFlags flags = [NSEvent modifierFlags];
	NSMutableString *keyString = [NSMutableString new];
	for ( int i = 0; i < 5; i++ ){
		if ( flags & flaglist[i])
			[keyString appendString:flagNames[i]];
	}
	dispatch_async( self.mpvQueue, ^{
		NSString *equivalent = self.inputMap[theEvent.charactersIgnoringModifiers];
		if ( equivalent )
			[keyString appendString:equivalent];
		else
			[keyString appendString:theEvent.charactersIgnoringModifiers];

		[self command:@[@"keypress", keyString]];
	} );
}

- (void)handleEvent:(mpv_event *)event {
	switch (event->event_id) {
		case MPV_EVENT_LOG_MESSAGE: {
			struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
			DDLogDebug( @"[%s] %s: %s", msg->prefix, msg->level, msg->text );
			break;
		}

		case MPV_EVENT_PROPERTY_CHANGE: {
			[self.properties handleMpvPropertyChange:event->data];
			break;
		}

		case MPV_EVENT_FILE_LOADED: {
			DDLogVerbose( @"file_loaded" );
			self.properties[@"fileLoaded"] = @"yes";
			break;
		}

		case MPV_EVENT_END_FILE: {
			self.properties[@"fileLoaded"] = @"no";
			break;
		}

		default: {}
	}
}

- (NSString *)getMpvProperty:(NSString *)name {
	char *value = mpv_get_property_string( self.mpv, name.UTF8String );
	if ( value )
		return [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
	return nil;
}

- (void)setMpvProperty:(NSString *)name toValue:(NSString *)value {
	mpv_set_property_string( self.mpv, name.UTF8String, value.UTF8String );
}

- (BOOL)observeMpvProperty:(NSString *)propertyName usingIndex:(NSInteger)index {
	if (mpv_observe_property( self.mpv, index, propertyName.UTF8String, MPV_FORMAT_STRING ) < 0)
		return false;
	return true;
}

- (void)unobserveMpvProperty:(NSInteger)index {
	mpv_unobserve_property( self.mpv, index );
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
	[self.properties destroy];
}

- (void)toggleFullScreen {
	self.properties[@"fullscreen"] = (self.window.styleMask & NSFullScreenWindowMask)? @"no": @"yes";
}

#pragma mark - WebkitFrameLoadDelegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame*)frame {
	self.properties[@"interfaceLoaded"] = @"yes";
}

#pragma mark - MpvJSBridge

// jsexport is kind enough to convert all array members to NS-types
- (void)command:(NSArray *)arguments {
	const char **cmd = calloc( [arguments count] + 1, sizeof(*cmd) );
	for ( int i = 0; i < [arguments count]; i++ ) {
		cmd[i] = [arguments[i] UTF8String];
	}
	check_error( mpv_command( self.mpv, cmd ) );
	free( cmd );
}

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

- (void)setProperty:(NSString *)name value:(NSString *)value {
	self.properties[name] = value;
}

- (NSString *)getProperty:(NSString *)name {
	return self.properties[name];
}

- (BOOL)observeProperty:(NSString *)name {
	[self.properties addJSCallbackForProperty:name];
	return YES;
}

- (void)unobserveProperty:(NSString *)name {
	[self.properties removeJSCallbackForProperty:name];
}

@end
