#import <mpv/opengl_cb.h>

#import <stdio.h>
#import <stdlib.h>

#import "VpmDelegate.h"
#import "VpmJSBridge.h"

static inline void check_error( int status ) {
	if (status < 0) {
		printf( "mpv API error: %s\n", mpv_error_string( status ) );
		exit(1);
	}
}

static void wakeup(void *ctx) {
	VpmDelegate *delegate = (__bridge VpmDelegate *)ctx;
	[delegate readEvents];
}

static void glupdate(void *ctx) {
	VpmDelegate *delegate = (__bridge VpmDelegate *)ctx;
	dispatch_async( dispatch_get_main_queue( ), ^{
		[delegate.window.mainView drawRect];
	} );
}

static void *get_proc_address( void *ctx, const char *name) {
	CFStringRef symbolName = CFStringCreateWithCString( kCFAllocatorDefault, name, kCFStringEncodingASCII );
	void *addr = CFBundleGetFunctionPointerForName( CFBundleGetBundleWithIdentifier( CFSTR( "com.apple.opengl" ) ), symbolName );
	CFRelease( symbolName );
	return addr;
}

@implementation VpmDelegate

- (void)createWindow {
	int mask = NSTitledWindowMask | NSClosableWindowMask |
	           NSMiniaturizableWindowMask | NSResizableWindowMask;

	self.window = [[VpmWindow alloc]
		initWithContentRect:NSMakeRect(0, 0, 1280, 720)
		          styleMask:mask
		            backing:NSBackingStoreBuffered
		              defer:NO];

	[self.window makeKeyAndOrderFront:nil];
	[self.window makeMainWindow];
	self.window.title = @"vpm";

	NSMenu *m = [[NSMenu alloc] initWithTitle:@"AMainMenu"];
	NSMenuItem *item = [m addItemWithTitle:@"Apple" action:nil keyEquivalent:@""];
	NSMenu *sm = [[NSMenu alloc] initWithTitle:@"Apple"];
	[m setSubmenu:sm forItem:item];
	[sm addItemWithTitle: @"quit" action:@selector(terminate:) keyEquivalent:@"q"];
	[NSApp setMenu:m];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	atexit_b(^{
		// Because activation policy has just been set to behave like a real
		// application, that policy must be reset on exit to prevent, among
		// other things, the menubar created here from remaining on screen.
		[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
	});

	// Read filename
	NSArray *args = [NSProcessInfo processInfo].arguments;
	if (args.count < 3) {
		NSLog( @"Expected video and html filepaths on command line" );
		exit( 1 );
	}
	NSString *videopath = args[1];
	NSString *htmlpath = args[2];
	[self createWindow];

	// queue for dealing with mpv events later
	self.mpvQueue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);

	self.mpv = mpv_create();
	if ( !self.mpv ) {
		printf( "failed creating context\n" );
		exit( 1 );
	}

	// request important errors
	check_error(mpv_request_log_messages(self.mpv, "info"));
	check_error(mpv_initialize(self.mpv));

	check_error( mpv_set_option_string( self.mpv, "vo", "opengl-cb" ) );

	mpv_opengl_cb_context *mpv_gl = mpv_get_sub_api(self.mpv, MPV_SUB_API_OPENGL_CB);
	if (!mpv_gl) {
		puts("libmpv does not have the opengl-cb sub-API.");
		exit(1);
	}

	int r = mpv_opengl_cb_init_gl( mpv_gl, NULL, get_proc_address, NULL );

	if (r < 0) {
		puts( "gl init has failed." );
		exit( 1 );
	}

	mpv_opengl_cb_set_update_callback(mpv_gl, glupdate, (__bridge void *)self);
	self.window.mainView.mpv_gl = mpv_gl;

	// webkit calls also cannot be cross-thread
	[[self.window.mainView.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlpath isDirectory:NO]]];

	self.window.mainView.bridge = [[VpmJSBridge alloc] initWithMpv:self.mpv
	                                                         queue:self.mpvQueue];

	[self.window.mainView attachJS];

	dispatch_async( self.mpvQueue, ^{
		// Register to be woken up whenever mpv generates new events.
		mpv_set_wakeup_callback(self.mpv, wakeup, (__bridge void *)self);

		const char *cmd[] = {"loadfile", videopath.UTF8String, NULL};
		check_error( mpv_command( self.mpv, cmd ) );
	} );
}

- (void) handleEvent:(mpv_event *)event {
	switch (event->event_id) {
		case MPV_EVENT_SHUTDOWN: {
			dispatch_sync( dispatch_get_main_queue( ), ^{
				mpv_opengl_cb_uninit_gl(self.window.mainView.mpv_gl);
				[self.window.mainView clearGLContext];
			} );
			mpv_detach_destroy(self.mpv);
			self.mpv = NULL;
			self.window.mainView.mpv_gl = NULL;
			printf("event: shutdown\n");
			break;
		}

		case MPV_EVENT_LOG_MESSAGE: {
			struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
			printf("[%s] %s: %s", msg->prefix, msg->level, msg->text);
		}

		default: {

		}
	}
}

- (void)readEvents {
	dispatch_async(self.mpvQueue, ^{
		while ( self.mpv ) {
			mpv_event *event = mpv_wait_event( self.mpv, 0 );
			if (event->event_id == MPV_EVENT_NONE)
				break;
			[self handleEvent:event];
		}
	});
}

// quit when the window is closed.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSLog( @"Terminating." );
	const char *args[] = { "quit", NULL };
	mpv_command( self.mpv, args );
	return NSTerminateNow;
}

@end
