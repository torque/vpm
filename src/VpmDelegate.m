#import <mpv/opengl_cb.h>

#import <stdio.h>
#import <stdlib.h>

#import "VpmDelegate.h"
#import "VpmWindow.h"
#import "VpmVideoView.h"
#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmDelegate

- (void)createWindow {
	int startHeight = 300;
	NSRect screenFrame = [NSScreen mainScreen].visibleFrame;

	NSRect windowRect = NSMakeRect( (screenFrame.size.width - startHeight)/2 + screenFrame.origin.x,
		                              (screenFrame.size.height - startHeight)/2 + screenFrame.origin.y,
		                              startHeight, startHeight );

	int mask = NSBorderlessWindowMask | NSResizableWindowMask;

	self.window = [[VpmWindow alloc]
		initWithContentRect:windowRect
		          styleMask:mask
		            backing:NSBackingStoreBuffered
		              defer:NO];

	NSMenu *m = [[NSMenu alloc] initWithTitle:@"AMainMenu"];
	NSMenuItem *item = [m addItemWithTitle:@"Apple" action:nil keyEquivalent:@""];
	NSMenu *sm = [[NSMenu alloc] initWithTitle:@"Apple"];
	[m setSubmenu:sm forItem:item];
	NSMenuItem *fs = [sm addItemWithTitle: @"Toggle Full Screen" action:@selector(toggleFullScreen) keyEquivalent:@"f"];
	fs.target = self.window.mainView.webView.bridge;
	[sm addItemWithTitle: @"Quit vpm" action:@selector(terminate:) keyEquivalent:@"q"];
	[NSApp setMenu:m];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	// Read filename
	NSArray *args = [NSProcessInfo processInfo].arguments;
	NSString *videopath = nil;
	NSString *htmlpath = nil;
	// lazy and kind of bad.
	bool launchedFromBundle = [NSBundle mainBundle].bundleIdentifier;
	if (!launchedFromBundle) {
		switch (args.count) {
			case 3:
				NSLog( @"%@", args[2] );
				htmlpath = args[2];
			case 2:
				NSLog( @"%@", args[1] );
				videopath = args[1];
		}
	}

	[self createWindow];

	// this is bad
	if ( htmlpath ) {
		[[self.window.mainView.webView mainFrame] loadRequest:
			[NSURLRequest requestWithURL:
				[NSURL fileURLWithPath:htmlpath isDirectory:NO]
			]
		];
	} else {
		[[self.window.mainView.webView mainFrame] loadRequest:
			[NSURLRequest requestWithURL:
				[[NSBundle mainBundle] URLForResource:@"video" withExtension:@"html"]
			]
		];
	}

	// this is also bad
	if ( videopath ) {
		[self.window.mainView.webView.bridge loadVideo:videopath];
	}
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
