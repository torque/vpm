#import <mpv/opengl_cb.h>

#import <stdio.h>
#import <stdlib.h>

#import "VpmDelegate.h"

@implementation VpmDelegate

- (void)createWindow {
	int mask = NSTitledWindowMask | NSClosableWindowMask |
	           NSMiniaturizableWindowMask | NSResizableWindowMask;

	self.window = [[VpmWindow alloc]
		initWithContentRect:NSMakeRect(0, 0, 200, 200)
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
	// Read filename
	NSArray *args = [NSProcessInfo processInfo].arguments;
	if (args.count < 3) {
		NSLog( @"Expected video and html filepaths on command line" );
		exit( 1 );
	}
	NSString *videopath = args[1];
	NSString *htmlpath = args[2];
	[self createWindow];

	// this is bad
	[[self.window.mainView.webView mainFrame] loadRequest:
		[NSURLRequest requestWithURL:
			[NSURL fileURLWithPath:htmlpath isDirectory:NO]
		]
	];

	// this is also bad
	[self.window.mainView.webView.bridge loadVideo:videopath];
}

// quit when the window is closed.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSLog( @"Shutting down." );
	[self.window destroy];
	return NSTerminateNow;
}

@end
